unit ucCHXTWConsole;
{< Simple test writer for console output with raw text.

  (c) 2026 Chixpy https://github.com/Chixpy

  ToDo: Make proper report at the end, listing failures and errors.

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
  ksDefSuccess = '✅ Success';
  ksDefFail = '❌ Failed';
  ksDefError = '❌ ¡ERROR!';
  {<< Default test / case result strings. }

type

{
  cCHXTWConsole
}

  cCHXTWConsole = class(cCHXTestWriter)
  protected
    function ResultStr(const ResultType : tCHXTestResultType) : String;
    procedure WriteStr(const aString : String;
      const TestResults : tCHXTestResults);

  public
    TextWidth : Integer;
    //< Width for wrap messages
    ShowTime : Boolean;
    //< Show actual time where a test started.

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
    SuccessStr : String;
    FailStr : String;
    ErrorStr : String;

    constructor Create; override;
    destructor Destroy; override;

    procedure OnBeforeStart; override;
    procedure OnTestStart(const TestResults : tCHXTestResults); override;
    procedure OnCaseStart(const TestResults : tCHXTestResults); override;
    procedure OnCaseEnd(const TestResults : tCHXTestResults); override;
    procedure OnTestEnd(const TestResults : tCHXTestResults); override;
    procedure OnAfterEnd(const TestResults : tCHXTestResults); override;
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

procedure cCHXTWConsole.WriteStr(const aString : String;
  const TestResults : tCHXTestResults);
var
  LineIndent, TimeStr, aStr : String;
begin
  if ShowTime then
    TimeStr := TimeToStr(Time)
  else
    TimeStr := '';

  LineIndent := DupeString(IndentStr, TestResults.TreeDepth);

  aStr := Format(aString,
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

  // ToDo: Use WordWrap
  if aStr <> '' then
    Write(aStr);

//   LineIndent := DupeString(IndentStr, TestResults.TreeDepth + 2) + '  ';
//
//   if Self.TextWidth >= LineIndent.Length + 1 then
//     WriteLn(DupeString(IndentStr, TestResults.TreeDepth + 2) + '  ' +
//       TestResults.Message)
//   else
//   begin
//     LineIndent := DupeString(IndentStr, TestResults.TreeDepth + 2) + '  ';
//     Write(LineIndent);
//     WriteLn(WrapText(TestResults.Message, LineEnding + LineIndent,
//       [' ', ',', ';', '.', #9], 80 - LineIndent.Length));
//   end;
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
  SuccessStr := ksDefSuccess;
  FailStr := ksDefFail;
  ErrorStr := ksDefError;

  TextWidth := 80;
  ShowTime := true;
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
begin
  WriteStr(CaseStartFmt, TestResults);
end;

procedure cCHXTWConsole.OnCaseEnd(const TestResults : tCHXTestResults);
begin
  WriteStr(CaseEndFmt, TestResults);
  if not (TestResults.ResultType in [rtSkip, rtSuccess]) then
  begin
    WriteStr(CaseFailMsgFmt, TestResults);
    WriteStr(CaseBackTraceMsgFmt, TestResults);
  end;
end;

procedure cCHXTWConsole.OnTestEnd(const TestResults : tCHXTestResults);
begin
  WriteStr(TestEndFmt, TestResults);
end;

procedure cCHXTWConsole.OnAfterEnd(const TestResults : tCHXTestResults);
var
  Time : Double;
begin
  // ToDo: Make a proper report and configurable...

  // Converting MS to TTimeDate
  Time := TestResults.TimeElapsed / MSecsPerDay;

  WriteLn;
  WriteLn;
  WriteLn('Totals:');
  WriteLn(IndentStr, Format('Time: %s / Asserts: %d / Cases: %d / Groups: %d',
    [TimeToStr(Time), TestResults.NAsserts, TestResults.NCases, TestResults.NSubTests]));
  WriteLn('Results:');
  WriteLn(IndentStr, Format('%d %s / %d %s / %d %s / %d %s',
    [TestResults.NSkip, ksDefSkip, TestResults.NSuccess, ksDefSuccess,
    TestResults.NFailed, ksDefFail, TestResults.NError, ksDefError]));
  WriteLn;
end;

initialization

finalization

end.
