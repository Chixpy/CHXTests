program BasicTest;
{< Basic test of cCHXTestGroup with simple cases. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  ucCHXTestGroup, ucCHXTWConsole, utCHXTestResults;

type

  {$PUSH}
  {$M+}
  cTestCases = class(cCHXTestGroup)
  published
    procedure ExampleCaseSuccess;
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

procedure cTestCases.ExampleCaseFail;
begin
  MustTrue(False, 'Custom text on fail.');
end;

procedure cTestCases.ExampleCaseError;
var
  aArray : Array of integer;
  i : Integer;
begin
  SetLength(aArray, 10);
  // Runtime error at i = 10
  for i := 0 to Length(aArray) do
  begin
    aArray[i] := i;
    MustTrue(aArray[i] = i);
  end;
end;

function IsExpectedResult(const aRunCode : Integer;
  const aResults : tCHXTestResults) : Boolean;
{< Check the results this example intentionally produces. }
begin
  Result := (aRunCode = 2)
    and (aResults.ResultType = rtError)
    and (aResults.NCases = 3)
    and (aResults.NSuccess = 1)
    and (aResults.NFailed = 1)
    and (aResults.NError = 1)
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
  // Writers added by class type are autofreed on test destroy.
  MainTest.AddWriter(cCHXTWConsole);
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
