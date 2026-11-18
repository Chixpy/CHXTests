unit ucCHXTWConsole;
{< Simple test writer for console output with raw text.

  (c) 2026 Chixpy https://github.com/Chixpy

}
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

interface

uses
  SysUtils, StrUtils, ucCHXTestWriter, utCHXTestResults;

const
  ksDefIndent = '  ┆ ';
  {< Default string used as padding. }

  ksDefBeforeStartFmt = '';
  ksDefTestStartFmt = '%0:s[%17:s] %2:s %13:s (Cases = %6:d Groups = %7:d)';
  ksDefCaseStartFmt = '%0:s%1:s[%17:s] %2:s ';
  ksDefCaseEndFmt =   '%13:s [T=%12:d] (TA=%4:d)';
  ksDefFailMsgFmt =   '%0:s%1:s%1:s%14:s%0:s%1:s%1:s%15:s';
  ksDefBckTrcMsgFmt = '%0:s%1:s%1:s%16:s';
  ksDefTestEndFmt =   '%0:s[T=%12:d] %2:s %13:s (TA=%4:d TC=%5:d ' +
    '/ Sk=%8:d Sc=%9:d F=%10:d E=%11:d)';
  ksDefAfterEndFmt = '';
  {<< Default Format strings for output. They can be changed in cCHXTWConsole
    properties. Available arguments are (or any Format variations):
      - `%0:s` = Newline + Current indent
      - `%1:s` = Additional indent
      - `%2:s` = Test Group / Case Name
      - `%3:d` = Nested test depth
      - `%4:d` = Current total assertions evaluated
      - `%5:d` = Current total test cases evaluated
      - `%6:d` = Total owned test cases
      - `%7:d` = Total owned subtests groups
      - `%8:d` = Test cases skipped
      - `%9:d` = Test cases successful
      - `%10:d` = Test cases failed
      - `%11:d` = Other error test cases
      - `%12:d` = Time elapsed
      - `%13:s` = Result of Test / Case as a string
      - `%14:s` = Failed assertion
      - `%15:s` = Fail / Error message
      - `%16:s` = Fail / Error BackTrace
      - `%17:s` = Current time. '' if `ShowTime = @False`.
  }

  ksDefStart = 'Start';
  ksDefSkip = '⚠️ Skipped';
  ksDefSkipGroup = '⛔ Skipped';
  ksDefSuccess = '✅ Success';
  ksDefFail = '❌ Failed';
  ksDefError = '☢️ ¡ERROR!';
  {<< Default test / case result strings. `ksDefSkipGroup` is used in the
    final totals for skipped groups. }

type

{
  cCHXTWConsole
}

  cCHXTWConsole = class(cCHXTestWriter)
  protected
    FProgressShown : Boolean;
    FProgressLen : Integer;
    FCaseStartLine : String;

    function ResultStr(const ResultType : tCHXTestResultType) : String;
    function FormatStr(const aString : String;
      const TestResults : tCHXTestResults) : String;
    procedure WriteStr(const aString : String;
      const TestResults : tCHXTestResults);
    procedure WriteInfo(const TestResults : tCHXTestResults);
    procedure WriteSummaryItem(const Caption, Text : String);

  public
    TextWidth : Integer;
    //< Width for wrap messages
    ShowTime : Boolean;
    //< Show actual time where a test started.
    ShowInfo : Boolean;
    //< Render the persistent information sent by cases.
    ShowProgress : Boolean;
    //< Render transient progress using carriage returns.

    IndentStr : String;
    BeforeStartFmt : String;
    AfterEndFmt : String;
    TestStartFmt : String;
    TestEndFmt : String;
    CaseStartFmt : String;
    CaseEndFmt : String;
    CaseFailMsgFmt : String;
    CaseBackTraceMsgFmt : String;

    StartStr : String;
    SkipStr : String;
    SkipGroupStr : String;
    //< String for skipped groups in the final totals.
    SuccessStr : String;
    FailStr : String;
    ErrorStr : String;

    constructor Create; override;
    destructor Destroy; override;

    procedure OnBeforeStart; override;
    procedure OnTestStart(const TestResults : tCHXTestResults); override;
    procedure OnCaseStart(const TestResults : tCHXTestResults); override;
    procedure OnCaseEnd(const TestResults : tCHXTestResults); override;
    procedure OnCaseProgress(const TestResults : tCHXTestResults;
      const Text : String; const Percent : Integer); override;
    procedure OnTestEnd(const TestResults : tCHXTestResults); override;
    procedure OnAfterEnd(const TestResults : tCHXTestResults); override;
    procedure WriteSummary; override;
  end;


implementation

{
  cCHXTWConsole
}

function cCHXTWConsole.ResultStr(const ResultType : tCHXTestResultType) : String;
begin
  case ResultType of
    rtStart : Result := StartStr;
    rtSkip : Result := SkipStr;
    rtSuccess : Result := SuccessStr;
    rtFailed : Result := FailStr;
    rtError : Result := ErrorStr;
  otherwise // rtNone
    Result := '';
  end;
end;

function cCHXTWConsole.FormatStr(const aString : String;
  const TestResults : tCHXTestResults) : String;
var
  LineIndent, TimeStr : String;
begin
  if ShowTime then
    TimeStr := TimeToStr(Time)
  else
    TimeStr := '';

  LineIndent := DupeString(IndentStr, TestResults.TreeDepth);

  Result := Format(aString,
    [
      LineEnding + LineIndent,          // `%0:s` = Newline + Current indent
      IndentStr,                        // `%1:s` = Additional indent
      TestResults.TestName,              // `%2:s` = Test Group / Case Name
      TestResults.TreeDepth,             // `%3:d` = Nested test depth
      TestResults.NAsserts,              // `%4:d` = Current total assertions
      TestResults.NCases,                // `%5:d` = Current total test cases
      TestResults.NOwnedCases,           // `%6:d` = Total owned test cases
      TestResults.NSubTests,             // `%7:d` = Total owned tests groups
      TestResults.NSkip,                 // `%8:d` = Test cases skipped
      TestResults.NSuccess,              // `%9:d` = Test cases successful
      TestResults.NFailed,               // `%10:d` = Test cases failed
      TestResults.NError,                // `%11:d` = Other error test cases
      TestResults.TimeElapsed,           // `%12:d` = Time elapsed
      ResultStr(TestResults.ResultType), // `%13:s` = Result of Test / Case
      TestResults.FailedAssert,          // `%14:s` = Failed assertion
      TestResults.Message,               // `%15:s` = Fail / Error message
      TestResults.BackTrace,             // `%16:s` = Fail / Error BackTrace
      TimeStr                           // `%17:s` = Current time
    ]);
end;

procedure cCHXTWConsole.WriteStr(const aString : String;
  const TestResults : tCHXTestResults);
var
  aStr : String;
begin
  aStr := FormatStr(aString, TestResults);
  if aStr <> '' then
    Write(aStr);
end;

procedure cCHXTWConsole.WriteInfo(const TestResults : tCHXTestResults);
var
  LineIndent, aInfo : String;
begin
  if TestResults.Info = '' then Exit;

  LineIndent := DupeString(IndentStr, TestResults.TreeDepth + 2);
  aInfo := StringReplace(TestResults.Info, LineEnding,
    LineEnding + LineIndent, [rfReplaceAll]);
  Write(LineEnding + LineIndent + aInfo);
end;

procedure cCHXTWConsole.WriteSummaryItem(const Caption, Text : String);
var
  aText : String;
begin
  if Text = '' then Exit;

  aText := StringReplace(Text, LineEnding,
    LineEnding + IndentStr + IndentStr, [rfReplaceAll]);
  WriteLn(IndentStr, IndentStr, Caption, ': ', aText);
end;

constructor cCHXTWConsole.Create;
begin
  inherited Create;

  IndentStr := ksDefIndent;
  BeforeStartFmt := ksDefBeforeStartFmt;
  AfterEndFmt := ksDefAfterEndFmt;
  TestStartFmt := ksDefTestStartFmt;
  TestEndFmt := ksDefTestEndFmt;
  CaseStartFmt := ksDefCaseStartFmt;
  CaseEndFmt := ksDefCaseEndFmt;
  CaseFailMsgFmt := ksDefFailMsgFmt;
  CaseBackTraceMsgFmt := ksDefBckTrcMsgFmt;
  StartStr := ksDefStart;
  SkipStr := ksDefSkip;
  SkipGroupStr := ksDefSkipGroup;
  SuccessStr := ksDefSuccess;
  FailStr := ksDefFail;
  ErrorStr := ksDefError;

  TextWidth := 80;
  ShowTime := True;
  ShowInfo := False;
  ShowProgress := False;
  FProgressShown := False;
  FProgressLen := 0;
  FCaseStartLine := '';
end;

destructor cCHXTWConsole.Destroy;
begin
  inherited Destroy;
end;

procedure cCHXTWConsole.OnBeforeStart;
var
  TREmpty : tCHXTestResults;
begin
  TREmpty.Init;
  TREmpty.ResultType := rtStart;
  TREmpty.TreeDepth := 0;
  WriteStr(BeforeStartFmt, TREmpty);
end;

procedure cCHXTWConsole.OnTestStart(const TestResults : tCHXTestResults);
begin
  WriteStr(TestStartFmt, TestResults);
end;

procedure cCHXTWConsole.OnCaseStart(const TestResults : tCHXTestResults);
var
  aLine : String;
begin
  aLine := FormatStr(CaseStartFmt, TestResults);
  FCaseStartLine := aLine;
  if Copy(FCaseStartLine, 1, Length(LineEnding)) = LineEnding then
    Delete(FCaseStartLine, 1, Length(LineEnding));

  FProgressShown := False;
  FProgressLen := 0;

  if aLine <> '' then
    Write(aLine);
end;

procedure cCHXTWConsole.OnCaseEnd(const TestResults : tCHXTestResults);
begin
  if FProgressShown then
  begin
    Write(#13, DupeString(' ', FProgressLen), #13);
    if FCaseStartLine <> '' then
      Write(FCaseStartLine);
    FProgressShown := False;
    FProgressLen := 0;
  end;

  WriteStr(CaseEndFmt, TestResults);
  if not (TestResults.ResultType in [rtSkip, rtSuccess]) then
  begin
    WriteStr(CaseFailMsgFmt, TestResults);
    WriteStr(CaseBackTraceMsgFmt, TestResults);
  end;

  if ShowInfo then
    WriteInfo(TestResults);
end;

procedure cCHXTWConsole.OnCaseProgress(const TestResults : tCHXTestResults;
  const Text : String; const Percent : Integer);
var
  aLine, LineIndent : String;
begin
  if not ShowProgress then Exit;

  LineIndent := DupeString(IndentStr, TestResults.TreeDepth + 2);
  if Percent >= 0 then
    aLine := Format('%s%s (%d%%)', [LineIndent, Text, Percent])
  else
    aLine := LineIndent + Text;

  Write(#13, DupeString(' ', FProgressLen), #13, aLine);
  FProgressLen := Length(aLine);
  FProgressShown := True;
end;

procedure cCHXTWConsole.OnTestEnd(const TestResults : tCHXTestResults);
begin
  WriteStr(TestEndFmt, TestResults);
end;

procedure cCHXTWConsole.OnAfterEnd(const TestResults : tCHXTestResults);
var
  Time : Double;
begin
  // Totals are printed before the collected failure summary.

  // Converting MS to TTimeDate
  Time := TestResults.TimeElapsed / MSecsPerDay;

  WriteLn;
  WriteLn;
  WriteLn('Totals:');
  WriteLn(IndentStr, Format('Time: %s / Asserts: %d / Cases: %d / Groups: %d',
    [TimeToStr(Time), TestResults.NAsserts, TestResults.NCases, TestResults.NSubTests]));
  WriteLn('Results:');
  WriteLn(IndentStr, Format(
    '%s: %d / %s (G): %d / %s (C): %d / %s: %d / %s: %d',
    [SuccessStr, TestResults.NSuccess,
    SkipGroupStr, TestResults.NSkippedGroups,
    SkipStr, TestResults.NSkip,
    FailStr, TestResults.NFailed,
    ErrorStr, TestResults.NError]));
  WriteLn;
end;

procedure cCHXTWConsole.WriteSummary;
var
  i : Integer;
  aFailure : tCHXTestFailure;
  aName : String;
begin
  if Failures.Count = 0 then Exit;

  WriteLn('Failures and errors:');
  for i := 0 to Failures.Count - 1 do
  begin
    aFailure := Failures[i];

    if aFailure.TestPath <> '' then
      aName := aFailure.TestPath + '.' + aFailure.CaseName
    else
      aName := aFailure.CaseName;

    WriteLn(IndentStr, ResultStr(aFailure.ResultType), ' ', aName);

    WriteSummaryItem('Assertion', aFailure.FailedAssert);
    WriteSummaryItem('Message', aFailure.Message);
    WriteSummaryItem('Info', aFailure.Info);
    WriteSummaryItem('Backtrace', aFailure.BackTrace);
  end;

  WriteLn;
end;

initialization

finalization

end.
