program JSONTest;
{< Generate a JSON report and check its structure. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  Classes, SysUtils, fpjson, jsonparser,
  ucCHXTestGroup, ucCHXTWJSON, utCHXTestResults;

type

  cPass = class(cCHXTestGroup)
  published
    procedure CasePass;
  end;

  cFail = class(cCHXTestGroup)
  published
    procedure CaseFail;
  end;

  cError = class(cCHXTestGroup)
  published
    procedure CaseError;
  end;

  cInfo = class(cCHXTestGroup)
  published
    procedure CaseInfo;
  end;

  cDisabled = class(cCHXTestGroup)
  published
    procedure CaseNever;
  end;

  cSkipCase = class(cCHXTestGroup)
  published
    procedure CaseEnabled;
    procedure CaseDisabled;
  end;

{
  Test cases
}

procedure cPass.CasePass;
begin
  MustTrue(True);
end;

procedure cFail.CaseFail;
begin
  SendInfo('first line');
  SendInfo('second "line"');
  SendProgress('half', 50);
  MustTrue(False, 'quoted failure',
    'Message with "quotes" and' + LineEnding + 'a newline');
end;

procedure cError.CaseError;
begin
  raise Exception.Create('Intentional error with "quotes".');
end;

procedure cInfo.CaseInfo;
begin
  SendInfo('first line');
  SendInfo('second line');
  MustTrue(True);
end;

procedure cDisabled.CaseNever;
begin
  MustTrue(True);
end;

procedure cSkipCase.CaseEnabled;
begin
  MustTrue(True);
end;

procedure cSkipCase.CaseDisabled;
begin
  MustTrue(True);
end;

{
  Checks
}

var
  CheckFailed : Boolean = False;

procedure Check(const aLabel : String; const aCondition : Boolean;
  const aDetail : String = '');
begin
  if aCondition then Exit;

  CheckFailed := True;
  if aDetail <> '' then
    WriteLn('FAIL: ', aLabel, ' (', aDetail, ')')
  else
    WriteLn('FAIL: ', aLabel);
end;

procedure CheckInt(const aLabel : String; const aObject : TJSONObject;
  const aName : String; const aExpected : Int64);
var
  aActual : Int64;
begin
  if not Assigned(aObject) then
  begin
    Check(aLabel, False, 'missing object');
    Exit;
  end;

  aActual := aObject.Get(aName, Int64(-1));
  Check(aLabel, aActual = aExpected,
    Format('got %d, expected %d', [aActual, aExpected]));
end;

procedure CheckStr(const aLabel : String; const aObject : TJSONObject;
  const aName, aExpected : String);
var
  aActual : String;
begin
  if not Assigned(aObject) then
  begin
    Check(aLabel, False, 'missing object');
    Exit;
  end;

  aActual := aObject.Get(aName, '');
  Check(aLabel, aActual = aExpected,
    Format('got "%s", expected "%s"', [aActual, aExpected]));
end;

function FindGroup(const aGroup : TJSONObject;
  const aPath : String) : TJSONObject;
var
  aData : TJSONData;
  aGroups : TJSONArray;
  aChild : TJSONObject;
  i : Integer;
begin
  Result := nil;

  if aGroup.Get('path', '') = aPath then
    Exit(aGroup);

  aData := aGroup.Find('groups', jtArray);
  if not (aData is TJSONArray) then Exit;
  aGroups := TJSONArray(aData);

  for i := 0 to aGroups.Count - 1 do
  begin
    aChild := aGroups.Items[i] as TJSONObject;
    Result := FindGroup(aChild, aPath);
    if Assigned(Result) then Exit;
  end;
end;

function FindCase(const aGroup : TJSONObject;
  const aName : String) : TJSONObject;
var
  aData : TJSONData;
  aCases : TJSONArray;
  aCase : TJSONObject;
  i : Integer;
begin
  Result := nil;

  if not Assigned(aGroup) then Exit;

  aData := aGroup.Find('cases', jtArray);
  if not (aData is TJSONArray) then Exit;
  aCases := TJSONArray(aData);

  for i := 0 to aCases.Count - 1 do
  begin
    aCase := aCases.Items[i] as TJSONObject;
    if aCase.Get('name', '') = aName then
      Exit(aCase);
  end;
end;

{
  Main program
}

var
  Root : cCHXTestGroup;
  Writer : cCHXTWJSON;
  SkipGroup, DisabledGroup : cCHXTestGroup;
  Data : TJSONData;
  RootObj, Nested, Node, Counts, CaseNode : TJSONObject;
  aData : TJSONData;
  RunCode : Integer;
  Saved : TStringList;
begin
  Root := cCHXTestGroup.Create('JSONRoot');
  Writer := cCHXTWJSON(Root.AddWriter(cCHXTWJSON));
  Writer.FileName := ExtractFilePath(ParamStr(0)) + 'JSONTest.json';

  try
    Root.AddChildTest(cPass, 'Nested.Pass');
    Root.AddChildTest(cFail, 'Nested.Fail');
    Root.AddChildTest(cError, 'Nested.Error');
    Root.AddChildTest(cInfo, 'Nested.Info');
    DisabledGroup := Root.AddChildTest(cDisabled, 'Nested.Disabled');
    DisabledGroup.Enabled := False;
    SkipGroup := Root.AddChildTest(cSkipCase, 'Nested.SkipCase');
    SkipGroup.SetCaseEnabled('CaseDisabled', False);

    RunCode := Root.RunAllCases;

    Check('run code', RunCode = 2, Format('got %d', [RunCode]));
    Check('save error', Writer.SaveError = '', Writer.SaveError);

    // The saved file must match the in-memory document.
    Saved := TStringList.Create;
    try
      try
        Saved.LoadFromFile(Writer.FileName);
        Check('saved file', Saved.Text = Writer.Lines.Text);
      except
        on E: Exception do
          Check('saved file', False, E.Message);
      end;
    finally
      Saved.Free;
    end;

    Check('no progress percent',
      Pos('"percent"', Writer.Lines.Text) = 0);
    Check('no progress key',
      Pos('"progress":', LowerCase(Writer.Lines.Text)) = 0);

    Data := nil;
    try
      try
        Data := GetJSON(Writer.Lines.Text);
      except
        on E: Exception do
          Check('parse', False, E.Message);
      end;

      if Assigned(Data) then
      begin
        Check('root object', Data is TJSONObject);

        if Data is TJSONObject then
        begin
          RootObj := TJSONObject(Data);
          CheckStr('generator', RootObj, 'generator', 'CHXTests');
          CheckInt('schema version', RootObj, 'schemaVersion', 1);
          CheckStr('root name', RootObj, 'name', 'JSONRoot');
          CheckStr('root path', RootObj, 'path', 'JSONRoot');
          CheckStr('root result', RootObj, 'result', 'error');

          aData := RootObj.Find('counts', jtObject);
          Check('root counts', aData is TJSONObject);
          if aData is TJSONObject then
          begin
            Counts := TJSONObject(aData);
            CheckInt('root asserts', Counts, 'asserts', 4);
            CheckInt('root cases', Counts, 'cases', 7);
            CheckInt('root groups', Counts, 'groups', 8);
            CheckInt('root success', Counts, 'success', 3);
            CheckInt('root skipped', Counts, 'skipped', 2);
            CheckInt('root skipped groups',
              Counts, 'skippedGroups', 1);
            CheckInt('root failed', Counts, 'failed', 1);
            CheckInt('root errors', Counts, 'errors', 1);
          end;

          Nested := FindGroup(RootObj, 'JSONRoot.Nested');
          Check('nested group', Assigned(Nested));
          if Assigned(Nested) then
            CheckStr('nested result', Nested, 'result', 'error');

          Node := FindGroup(RootObj, 'JSONRoot.Nested.Pass');
          CheckStr('pass result', Node, 'result', 'success');
          if Assigned(Node) then
            CaseNode := FindCase(Node, 'CasePass')
          else
            CaseNode := nil;
          CheckStr('pass case result', CaseNode, 'result', 'success');

          Node := FindGroup(RootObj, 'JSONRoot.Nested.Fail');
          if Assigned(Node) then
            CaseNode := FindCase(Node, 'CaseFail')
          else
            CaseNode := nil;
          CheckStr('fail path', CaseNode, 'path',
            'JSONRoot.Nested.Fail');
          CheckStr('fail result', CaseNode, 'result', 'failed');
          CheckStr('fail assert', CaseNode, 'failedAssert',
            'quoted failure');
          CheckStr('fail message', CaseNode, 'message',
            'Message with "quotes" and' + LineEnding + 'a newline');
          CheckStr('fail info', CaseNode, 'info',
            'first line' + LineEnding + 'second "line"');
          CheckInt('fail asserts', CaseNode, 'asserts', 1);

          Node := FindGroup(RootObj, 'JSONRoot.Nested.Error');
          if Assigned(Node) then
            CaseNode := FindCase(Node, 'CaseError')
          else
            CaseNode := nil;
          CheckStr('error result', CaseNode, 'result', 'error');
          CheckStr('error message', CaseNode, 'message',
            'Intentional error with "quotes".');

          Node := FindGroup(RootObj, 'JSONRoot.Nested.Info');
          if Assigned(Node) then
            CaseNode := FindCase(Node, 'CaseInfo')
          else
            CaseNode := nil;
          CheckStr('info text', CaseNode, 'info',
            'first line' + LineEnding + 'second line');

          Node := FindGroup(RootObj, 'JSONRoot.Nested.SkipCase');
          if Assigned(Node) then
            CaseNode := FindCase(Node, 'CaseDisabled')
          else
            CaseNode := nil;
          CheckStr('disabled case result', CaseNode, 'result', 'skip');

          Node := FindGroup(RootObj, 'JSONRoot.Nested.Disabled');
          Check('disabled group', Assigned(Node));
          if Assigned(Node) then
          begin
            CheckStr('disabled group result', Node, 'result', 'skip');

            aData := Node.Find('counts', jtObject);
            Check('disabled counts', aData is TJSONObject);
            if aData is TJSONObject then
            begin
              Counts := TJSONObject(aData);
              CheckInt('disabled cases', Counts, 'cases', 1);
              CheckInt('disabled skipped', Counts, 'skipped', 1);
              CheckInt('disabled skipped groups',
                Counts, 'skippedGroups', 1);
            end;

            aData := Node.Find('cases', jtArray);
            Check('disabled has no case nodes',
              (aData is TJSONArray) and
              (TJSONArray(aData).Count = 0));
          end;
        end;
      end;
    finally
      Data.Free;
    end;

    if CheckFailed then
    begin
      WriteLn('JSONTest: FAILED');
      ExitCode := 1;
    end
    else
    begin
      WriteLn('JSONTest: OK -> ', Writer.FileName);
      ExitCode := 0;
    end;
  finally
    Root.Free;
  end;
end.
