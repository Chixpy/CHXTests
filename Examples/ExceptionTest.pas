program ExceptionTest;
{< Example of MustRaise with successful and failing outcomes. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, utCHXTestResults;

type
  EMyError = class(Exception);
  EOtherError = class(Exception);

  {$PUSH}
  {$M+}
  cTestCases = class(cCHXTestGroup)
  published
    procedure ExampleRaisesExpected;
    procedure ExampleDoesNotRaise;
    procedure ExampleRaisesOther;
  end;
  {$POP}

procedure RaiseExpected;
begin
  raise EMyError.Create('Expected exception.');
end;

procedure NoRaise;
begin
end;

procedure RaiseOther;
begin
  raise EOtherError.Create('Another exception.');
end;

{
  cTestCases
}

procedure cTestCases.ExampleRaisesExpected;
begin
  MustRaise(@RaiseExpected, EMyError);
end;

procedure cTestCases.ExampleDoesNotRaise;
begin
  MustRaise(@NoRaise, EMyError);
end;

procedure cTestCases.ExampleRaisesOther;
begin
  MustRaise(@RaiseOther, EMyError);
end;

function IsExpectedResult(const aRunCode : Integer;
  const aResults : tCHXTestResults) : Boolean;
{< Check the results this example intentionally produces. }
begin
  Result := (aRunCode = 1)
    and (aResults.ResultType = rtFailed)
    and (aResults.NCases = 3)
    and (aResults.NSuccess = 1)
    and (aResults.NFailed = 2)
    and (aResults.NError = 0)
    and (aResults.NSkip = 0);
end;

{
  Main program
}

var
  MainTest : cTestCases;
  RunCode : Integer;
  Results : tCHXTestResults;

begin
  MainTest := cTestCases.Create;
  MainTest.AddWriter(cCHXTWConsole);
  RunCode := MainTest.RunAllCases;
  Results := MainTest.TestResults;
  MainTest.Free;

  // The example intentionally reports two failures.
  if IsExpectedResult(RunCode, Results) then
    ExitCode := 0
  else
  begin
    WriteLn('ExceptionTest: unexpected results.');
    ExitCode := 1;
  end;
end.
