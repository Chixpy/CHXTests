unit ucCHXTWJSON;
{< JSON writer for test results.

  (c) 2026 Chixpy https://github.com/Chixpy

  The document is built in memory and saved when the observed root group
  ends (`OnTestEnd`). This also covers writers attached only to a child,
  which never receive `OnAfterEnd`. The writer never writes to the console
  and ignores progress notifications. `ShowSummary` has no effect.

  A single `RunCase` call does not emit group events, so it does not produce a
  document. Use `RunAllCases` for JSON output.
}
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}

interface

uses
  Classes, SysUtils, Generics.Collections,
  ucCHXTestWriter, utCHXTestResults;

type

  {
    Internal data kept until the document is serialized.
  }
  tCHXJSONCase = class;
  tCHXJSONGroup = class;

  tCHXJSONCaseList = specialize TObjectList<tCHXJSONCase>;
  tCHXJSONGroupList = specialize TObjectList<tCHXJSONGroup>;
  tCHXJSONGroupStack = specialize TList<tCHXJSONGroup>;

  tCHXJSONCase = class
  public
    Name : String;
    Path : String;
    ResultType : tCHXTestResultType;
    Asserts : Cardinal;
    DurationMs : UInt64;
    FailedAssert : String;
    Message : String;
    BackTrace : String;
    Info : String;

    constructor Create(const aTestResult : tCHXTestResults);
  end;

  tCHXJSONGroup = class
  public
    Name : String;
    Path : String;
    ResultType : tCHXTestResultType;
    Asserts : Cardinal;
    Cases : Cardinal;
    Success : Cardinal;
    Skip : Cardinal;
    SkippedGroups : Cardinal;
    Failed : Cardinal;
    Errors : Cardinal;
    DurationMs : UInt64;
    CaseList : tCHXJSONCaseList;
    ChildList : tCHXJSONGroupList;

    constructor Create(const aName, aPath : String);
    destructor Destroy; override;

    procedure UpdateCounters(const aTestResult : tCHXTestResults);
  end;

  {
    cCHXTWJSON
  }
  cCHXTWJSON = class(cCHXTestWriter)
  private
    FRoot : tCHXJSONGroup;
    FStack : tCHXJSONGroupStack;
    FLines : TStrings;
    FSaveError : String;

    procedure AddLine(const aLevel : Integer; const aText : String);
    procedure AppendToLastLine(const aText : String);
    procedure ClearData;
    function GroupCount(const aGroup : tCHXJSONGroup) : Integer;
    procedure SaveDocument(const aFileName : String);
    procedure Serialize;
    procedure WriteCase(const aCase : tCHXJSONCase;
      const aLevel : Integer);
    procedure WriteGroup(const aGroup : tCHXJSONGroup;
      const aLevel : Integer);
    procedure WriteGroupFields(const aGroup : tCHXJSONGroup;
      const aLevel : Integer);

  public
    FileName : String;
    //< If not empty, the document is saved to this file after a run.
    IndentStr : String;
    //< Indentation added for each nesting level.

    constructor Create; override;
    destructor Destroy; override;

    property Lines : TStrings read FLines;
    //< Generated JSON document. Available when the observed root ends.
    property SaveError : String read FSaveError;
    //< Error raised while saving `FileName`, or an empty string.

    procedure OnBeforeStart; override;
    procedure OnTestStart(const TestResult : tCHXTestResults); override;
    procedure OnTestEnd(const TestResult : tCHXTestResults); override;
    procedure OnCaseEnd(const TestResult : tCHXTestResults); override;
  end;

implementation

uses
  StrUtils;

function ResultTypeName(const aResultType : tCHXTestResultType) : String;
begin
  case aResultType of
    rtNone : Result := 'none';
    rtStart : Result := 'start';
    rtSkip : Result := 'skip';
    rtSuccess : Result := 'success';
    rtFailed : Result := 'failed';
    rtError : Result := 'error';
  else
    Result := 'none';
  end;
end;

function JSONEscape(const aText : String) : String;
var
  i : Integer;
  c : Char;
begin
  Result := '';

  for i := 1 to Length(aText) do
  begin
    c := aText[i];
    case c of
      '"' : Result := Result + '\"';
      '\' : Result := Result + '\\';
      #8 : Result := Result + '\b';
      #9 : Result := Result + '\t';
      #10 : Result := Result + '\n';
      #12 : Result := Result + '\f';
      #13 : Result := Result + '\r';
    else
      if c < #32 then
        Result := Result + '\u' + IntToHex(Ord(c), 4)
      else
        Result := Result + c;
    end;
  end;
end;

{
  tCHXJSONCase
}

constructor tCHXJSONCase.Create(const aTestResult : tCHXTestResults);
begin
  inherited Create;

  Name := aTestResult.TestName;
  ResultType := aTestResult.ResultType;
  Asserts := aTestResult.NAsserts;
  DurationMs := aTestResult.TimeElapsed;
  FailedAssert := aTestResult.FailedAssert;
  Message := aTestResult.Message;
  BackTrace := aTestResult.BackTrace;
  Info := aTestResult.Info;
end;

{
  tCHXJSONGroup
}

constructor tCHXJSONGroup.Create(const aName, aPath : String);
begin
  inherited Create;

  Name := aName;
  Path := aPath;
  ResultType := rtNone;
  Asserts := 0;
  Cases := 0;
  Success := 0;
  Skip := 0;
  SkippedGroups := 0;
  Failed := 0;
  Errors := 0;
  DurationMs := 0;
  CaseList := tCHXJSONCaseList.Create;
  ChildList := tCHXJSONGroupList.Create;
end;

destructor tCHXJSONGroup.Destroy;
begin
  ChildList.Free;
  CaseList.Free;

  inherited Destroy;
end;

procedure tCHXJSONGroup.UpdateCounters(
  const aTestResult : tCHXTestResults);
begin
  ResultType := aTestResult.ResultType;
  Asserts := aTestResult.NAsserts;
  Cases := aTestResult.NCases;
  Success := aTestResult.NSuccess;
  Skip := aTestResult.NSkip;
  SkippedGroups := aTestResult.NSkippedGroups;
  Failed := aTestResult.NFailed;
  Errors := aTestResult.NError;
  DurationMs := aTestResult.TimeElapsed;
end;

{
  cCHXTWJSON
}

constructor cCHXTWJSON.Create;
begin
  inherited Create;

  FRoot := nil;
  FStack := tCHXJSONGroupStack.Create;
  FLines := TStringList.Create;
  FSaveError := '';

  FileName := '';
  IndentStr := '  ';
end;

destructor cCHXTWJSON.Destroy;
begin
  FStack.Free;
  FLines.Free;
  FreeAndNil(FRoot);

  inherited Destroy;
end;

procedure cCHXTWJSON.AddLine(const aLevel : Integer;
  const aText : String);
begin
  FLines.Add(DupeString(IndentStr, aLevel) + aText);
end;

procedure cCHXTWJSON.AppendToLastLine(const aText : String);
begin
  if FLines.Count > 0 then
    FLines[FLines.Count - 1] := FLines[FLines.Count - 1] + aText;
end;

procedure cCHXTWJSON.ClearData;
begin
  FStack.Clear;
  FreeAndNil(FRoot);
  FLines.Clear;
  FSaveError := '';
end;

function cCHXTWJSON.GroupCount(const aGroup : tCHXJSONGroup) : Integer;
var
  i : Integer;
begin
  Result := 1;
  for i := 0 to aGroup.ChildList.Count - 1 do
    Inc(Result, GroupCount(aGroup.ChildList[i]));
end;

procedure cCHXTWJSON.SaveDocument(const aFileName : String);
var
  Stream : TFileStream;
  aText : String;
begin
  aText := FLines.Text;

  Stream := TFileStream.Create(aFileName, fmCreate);
  try
    if aText <> '' then
      Stream.WriteBuffer(aText[1], Length(aText));
  finally
    Stream.Free;
  end;
end;

procedure cCHXTWJSON.Serialize;
begin
  FLines.Clear;
  if not Assigned(FRoot) then Exit;

  AddLine(0, '{');
  AddLine(1, '"generator": "CHXTests",');
  AddLine(1, '"schemaVersion": 1,');
  WriteGroupFields(FRoot, 1);
  AddLine(0, '}');
end;

procedure cCHXTWJSON.WriteCase(const aCase : tCHXJSONCase;
  const aLevel : Integer);
begin
  AddLine(aLevel, '{');
  AddLine(aLevel + 1,
    '"name": "' + JSONEscape(aCase.Name) + '",');
  AddLine(aLevel + 1,
    '"path": "' + JSONEscape(aCase.Path) + '",');
  AddLine(aLevel + 1,
    '"result": "' + ResultTypeName(aCase.ResultType) + '",');
  AddLine(aLevel + 1, '"asserts": ' + UIntToStr(aCase.Asserts) + ',');
  AddLine(aLevel + 1,
    '"durationMs": ' + UIntToStr(aCase.DurationMs) + ',');
  AddLine(aLevel + 1,
    '"failedAssert": "' + JSONEscape(aCase.FailedAssert) + '",');
  AddLine(aLevel + 1,
    '"message": "' + JSONEscape(aCase.Message) + '",');
  AddLine(aLevel + 1,
    '"backtrace": "' + JSONEscape(aCase.BackTrace) + '",');
  AddLine(aLevel + 1,
    '"info": "' + JSONEscape(aCase.Info) + '"');
  AddLine(aLevel, '}');
end;

procedure cCHXTWJSON.WriteGroup(const aGroup : tCHXJSONGroup;
  const aLevel : Integer);
begin
  AddLine(aLevel, '{');
  WriteGroupFields(aGroup, aLevel + 1);
  AddLine(aLevel, '}');
end;

procedure cCHXTWJSON.WriteGroupFields(const aGroup : tCHXJSONGroup;
  const aLevel : Integer);
var
  i : Integer;
begin
  AddLine(aLevel, '"name": "' + JSONEscape(aGroup.Name) + '",');
  AddLine(aLevel, '"path": "' + JSONEscape(aGroup.Path) + '",');
  AddLine(aLevel,
    '"result": "' + ResultTypeName(aGroup.ResultType) + '",');
  AddLine(aLevel,
    '"durationMs": ' + UIntToStr(aGroup.DurationMs) + ',');
  AddLine(aLevel, '"counts": {');
  AddLine(aLevel + 1, '"asserts": ' + UIntToStr(aGroup.Asserts) + ',');
  AddLine(aLevel + 1, '"cases": ' + UIntToStr(aGroup.Cases) + ',');
  AddLine(aLevel + 1,
    '"groups": ' + IntToStr(GroupCount(aGroup)) + ',');
  AddLine(aLevel + 1, '"success": ' + UIntToStr(aGroup.Success) + ',');
  AddLine(aLevel + 1, '"skipped": ' + UIntToStr(aGroup.Skip) + ',');
  AddLine(aLevel + 1,
    '"skippedGroups": ' + UIntToStr(aGroup.SkippedGroups) + ',');
  AddLine(aLevel + 1, '"failed": ' + UIntToStr(aGroup.Failed) + ',');
  AddLine(aLevel + 1, '"errors": ' + UIntToStr(aGroup.Errors));
  AddLine(aLevel, '},');

  AddLine(aLevel, '"cases": [');
  for i := 0 to aGroup.CaseList.Count - 1 do
  begin
    if i > 0 then
      AppendToLastLine(',');
    WriteCase(aGroup.CaseList[i], aLevel + 1);
  end;
  AddLine(aLevel, '],');

  AddLine(aLevel, '"groups": [');
  for i := 0 to aGroup.ChildList.Count - 1 do
  begin
    if i > 0 then
      AppendToLastLine(',');
    WriteGroup(aGroup.ChildList[i], aLevel + 1);
  end;
  AddLine(aLevel, ']');
end;

procedure cCHXTWJSON.OnBeforeStart;
begin
  ClearData;
end;

procedure cCHXTWJSON.OnTestStart(const TestResult : tCHXTestResults);
var
  aGroup : tCHXJSONGroup;
begin
  // A writer attached only to a child may not receive OnBeforeStart. Also,
  // a new run without OnBeforeStart must not mix documents.
  if FStack.Count = 0 then
  begin
    if Assigned(FRoot) then
      ClearData;
  end;

  aGroup := tCHXJSONGroup.Create(TestResult.TestName, CurrentPath);
  FStack.Add(aGroup);
end;

procedure cCHXTWJSON.OnTestEnd(const TestResult : tCHXTestResults);
var
  aGroup : tCHXJSONGroup;
begin
  if FStack.Count = 0 then Exit;

  aGroup := FStack[FStack.Count - 1];
  FStack.Delete(FStack.Count - 1);
  aGroup.UpdateCounters(TestResult);

  if FStack.Count > 0 then
    FStack[FStack.Count - 1].ChildList.Add(aGroup)
  else
  begin
    FRoot := aGroup;
    // The observed root has finished: the tree is complete. This is also
    // the only end-of-run event for a writer attached to a child group.
    Serialize;

    if FileName = '' then Exit;

    try
      SaveDocument(FileName);
      FSaveError := '';
    except
      on E: Exception do
        FSaveError := E.Message;
    end;
  end;
end;

procedure cCHXTWJSON.OnCaseEnd(const TestResult : tCHXTestResults);
var
  aCase : tCHXJSONCase;
begin
  // A case run without a group event has no place in the tree.
  if FStack.Count = 0 then Exit;

  aCase := tCHXJSONCase.Create(TestResult);
  aCase.Path := CurrentPath;
  FStack[FStack.Count - 1].CaseList.Add(aCase);
end;

initialization

finalization

end.
