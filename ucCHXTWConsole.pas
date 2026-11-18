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
  {< Writer that renders the run as indented, coloured-by-symbol text.

    Every line is produced from one of the `*Fmt` properties with `Format`, so
    the layout can be changed without touching the class. The default format
    strings are the `ksDef*Fmt` constants.

    ```pascal
    Console := cCHXTWConsole(MainTest.AddWriter(cCHXTWConsole));
    Console.ShowInfo := True;
    Console.ShowProgress := True;
    ```

    The totals line is printed in `OnAfterEnd` and the collected failures and
    errors in `WriteSummary`, so the summary goes below the totals.

    @seealso(ucCHXTestWriter)
  }
  protected
    FProgressShown : Boolean;
    //< `True` while a transient progress line is on screen.
    FProgressLen : Integer;
    //< Length of the last progress line, used to erase it.
    FCaseStartLine : String;
    //< Case line kept to redraw it after progress output.

    function ResultStr(const ResultType : tCHXTestResultType) : String;
    //< Symbol and text for a result, from the `*Str` properties.
    function FormatStr(const aString : String;
      const TestResults : tCHXTestResults) : String;
    {< Expand a format string with the fields of `TestResults`.

      @param(aString Format string, usually one of the `*Fmt` properties.)
      @param(TestResults Data used as positional arguments.)
      @returns(The formatted text, or an empty string when `aString` is
        empty.)
    }
    procedure WriteStr(const aString : String;
      const TestResults : tCHXTestResults);
    //< Format and write a string without a line break.
    procedure WriteInfo(const TestResults : tCHXTestResults);
    //< Write `TestResults.Info` indented below the case line.
    procedure WriteSummaryItem(const Caption, Text : String);
    //< Write one `Caption: Text` line of the final summary, if not empty.

  public
    TextWidth : Integer;
    //< Width for wrap messages (currently not used by the writer).

    ShowTime : Boolean;
    //< Show actual time where a test started.

    ShowInfo : Boolean;
    //< Render the persistent information sent by cases.

    ShowProgress : Boolean;
    //< Render transient progress using carriage returns.

    IndentStr : String;
    //< Padding added for each nesting level.

    BeforeStartFmt : String;
    //< Format printed once before the run starts.
    AfterEndFmt : String;
    //< Format printed once after the run ends (empty by default).
    TestStartFmt : String;
    //< Format of a group start line.
    TestEndFmt : String;
    //< Format of a group end line.
    CaseStartFmt : String;
    //< Format of a case start line.
    CaseEndFmt : String;
    //< Format of a case end line.
    CaseFailMsgFmt : String;
    //< Format of the failure text; printed for non-successful cases.
    CaseBackTraceMsgFmt : String;
    //< Format of the backtrace line; printed for non-successful cases.

    StartStr : String;
    //< Text for `rtStart`.
    SkipStr : String;
    //< Text for skipped cases.
    SkipGroupStr : String;
    //< String for skipped groups in the final totals.
    SuccessStr : String;
    //< Text for successful results.
    FailStr : String;
    //< Text for failed results.
    ErrorStr : String;
    //< Text for errored results.

    constructor Create; override;
    {< Create the writer with the default formats, symbols and flags. }

    destructor Destroy; override;

    procedure OnBeforeStart; override;
    //< Print `BeforeStartFmt` with an empty result.
    procedure OnTestStart(const TestResults : tCHXTestResults); override;
    //< Print the group start line.
    procedure OnCaseStart(const TestResults : tCHXTestResults); override;
    {< Print the case start line and reset the progress state.

      The line is kept so it can be redrawn after progress output.
    }
    procedure OnCaseEnd(const TestResults : tCHXTestResults); override;
    {< Erase any progress line, print the case end line and its details.

      Failure details and backtrace are printed for failed and errored cases
      only. `Info` is printed when `ShowInfo` is enabled.
    }
    procedure OnCaseProgress(const TestResults : tCHXTestResults;
      const Text : String; const Percent : Integer); override;
    {< Redraw the progress line when `ShowProgress` is enabled.

      `Percent` is shown as `Text (N%)` when it is 0..100, and as plain `Text`
      when it is -1.
    }
    procedure OnTestEnd(const TestResults : tCHXTestResults); override;
    //< Print the group end line.
    procedure OnAfterEnd(const TestResults : tCHXTestResults); override;
    //< Print the totals block; the summary follows it.
    procedure WriteSummary; override;
    {< Print the collected failures and errors with assertion, message, info
      and backtrace. Nothing is printed when there are no failures.
    }
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
