program SoftTest;
{< Example of soft assertions that continue after a failure. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON,
  utCHXTestResults;

var
  ReachedAfterSoft : Boolean;
  ReachedAfterHard : Boolean;
  ReachedAfterMustSuccess : Boolean;

type

  {$PUSH}
  {$M+}
  cTestCases = class(cCHXTestGroup)
  published
    procedure ExampleSoftFailuresContinue;
    procedure ExampleSoftThenHard;
    procedure ExampleSoftThenMustSuccess;
    procedure ExampleCleanSuccess;
  end;
  {$POP}

{
  cTestCases
}

procedure cTestCases.ExampleSoftFailuresContinue;
begin
  MayTrue(False, 'First soft failure', 'first soft failure');
  ReachedAfterSoft := True;
  MayEqual(10, 20, 'Second soft failure', 'second soft failure');
  MustTrue(True, 'Reached after soft failures');
end;

procedure cTestCases.ExampleSoftThenHard;
begin
  MayTrue(False, 'Soft before hard failure', 'soft before hard');
  MustTrue(False, 'Hard failure after soft', 'hard failure after soft');
  ReachedAfterHard := True;
end;

procedure cTestCases.ExampleSoftThenMustSuccess;
begin
  MayTrue(False, 'Soft before successful Must',
    'soft before successful Must');
  MustTrue(True, 'Successful Must after soft');
  ReachedAfterMustSuccess := True;
end;

procedure cTestCases.ExampleCleanSuccess;
begin
  MustTrue(True);
end;

function IsExpectedResult(const aRunCode : Integer;
  const aResults : tCHXTestResults) : Boolean;
{< Check the results this example intentionally produces. }
begin
  Result := ReachedAfterSoft
    and (not ReachedAfterHard)
    and ReachedAfterMustSuccess
    and (aRunCode = 1)
    and (aResults.ResultType = rtFailed)
    and (aResults.NCases = 4)
    and (aResults.NSuccess = 1)
    and (aResults.NFailed = 3)
    and (aResults.NError = 0)
    and (aResults.NSkip = 0)
    and (aResults.NAsserts = 8);
end;

{
  Main program
}

var
  MainTest : cTestCases;
  RunCode : Integer;
  Results : tCHXTestResults;

begin
  ReachedAfterSoft := False;
  ReachedAfterHard := False;
  ReachedAfterMustSuccess := False;

  MainTest := cTestCases.Create;
  MainTest.AddWriter(cCHXTWConsole);
  if ParamCount >= 1 then
    cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON)).FileName := ParamStr(1);
  RunCode := MainTest.RunAllCases;
  Results := MainTest.TestResults;
  MainTest.Free;

  // The example intentionally reports three soft failures.
  if IsExpectedResult(RunCode, Results) then
    ExitCode := 0
  else
  begin
    WriteLn('SoftTest: unexpected results.');
    ExitCode := 1;
  end;
end.
