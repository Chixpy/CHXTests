program BasicTest;
{< Basic test of cCHXTestGroup with simple cases. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, utCHXTestResults;

type

  {$PUSH}
  {$M+}
  cTestCases = class(cCHXTestGroup)
  published
    procedure ExampleCaseSuccess;
    procedure ExampleCaseSkiped;
    procedure ExampleCaseFail;
    procedure ExampleCaseError;
  end;
  {$POP}

{
  cTestCases
}

procedure cTestCases.ExampleCaseSuccess;
begin
  MustTrue(True);
end;

procedure cTestCases.ExampleCaseSkiped;
begin
  MustTrue(True);
end;

procedure cTestCases.ExampleCaseFail;
begin
  MustTrue(False, 'Custom text on fail.');
end;

procedure cTestCases.ExampleCaseError;
const
  NIter = 10;
var
  aArray : Array of integer;
  i : Integer;
begin
  SetLength(aArray, NIter);
  // Runtime error at i = NIter
  for i := 0 to Length(aArray) do
  begin
    aArray[i] := i;
    SendProgress(IntToStr(i), i * 100 div Length(aArray));
    MustTrue(aArray[i] = i);
  end;
end;

function IsExpectedResult(const aRunCode : Integer;
  const aResults : tCHXTestResults) : Boolean;
{< Check the results this example intentionally produces. }
begin
  Result := (aRunCode = 2)
    and (aResults.ResultType = rtError)
    and (aResults.NCases = 4)
    and (aResults.NSuccess = 1)
    and (aResults.NFailed = 1)
    and (aResults.NError = 1)
    and (aResults.NSkip = 1);
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
  // Writers added by class type are autofreed on test destroy.
  MainTest.AddWriter(cCHXTWConsole);
  MainTest.SetCaseEnabled('ExampleCaseSkiped', False);
  RunCode := MainTest.RunAllCases;
  Results := MainTest.TestResults;
  MainTest.Free;

  // This example intentionally includes one failure and one error.
  // Return 0 when it produces exactly the expected results.
  if IsExpectedResult(RunCode, Results) then
    ExitCode := 0
  else
  begin
    WriteLn('BasicTest: unexpected results.');
    ExitCode := 1;
  end;
end.
