program BasicTest;
{< Basic test of cCHXTestGroup with simple cases. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  ucCHXTestGroup, ucCHXTWConsole;

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
{
  Main program
}

var
  MainTest : cTestCases;

begin
  MainTest := cTestCases.Create;
  // Writers added by class type are autofreed on test destroy.
  MainTest.AddWriter(cCHXTWConsole);
  MainTest.RunAllCases;
  MainTest.Free;
  ExitCode := 0;
end.
