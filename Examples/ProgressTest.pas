program ProgressTest;
{< Example of persistent case info and transient progress. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, utCHXTestResults;

type

  {$PUSH}
  {$M+}
  cTestCases = class(cCHXTestGroup)
  private
    FIterations : Integer;
  public
    property Iterations : Integer read FIterations write FIterations;
  published
    procedure ExampleProgressLoop;
  end;
  {$POP}

{
  cTestCases
}

procedure cTestCases.ExampleProgressLoop;
var
  i : Integer;
begin
  SendInfo(Format('Starting %d-step loop.', [Iterations]));

  for i := 1 to Iterations do
    SendProgress(Format('Step %d of %d', [i, Iterations]),
      (i * 100) div Iterations);

  SendInfo('Loop completed.');
  MustTrue(True);
end;

function IsExpectedResult(const aResults : tCHXTestResults;
  const aInfo : String; const aIterations : Integer) : Boolean;
{< Check the results and the persistent information this example produces. }
begin
  Result := (aResults.ResultType = rtSuccess)
    and (aResults.NCases = 1)
    and (aResults.NSuccess = 1)
    and (aResults.NFailed = 0)
    and (aResults.NError = 0)
    and (aResults.NSkip = 0)
    and (aResults.NAsserts = 1)
    and (aInfo = Format('Starting %d-step loop.', [aIterations]) +
      LineEnding + 'Loop completed.');
end;

{
  Main program
}

var
  MainTest : cTestCases;
  Console : cCHXTWConsole;
  RunCode : Integer;
  Results : tCHXTestResults;
  Info : String;
  Iterations : Integer;

begin
  Iterations := StrToIntDef(ParamStr(1), 10);
  if Iterations < 1 then Iterations := 10;

  MainTest := cTestCases.Create;
  MainTest.Iterations := Iterations;
  Console := cCHXTWConsole(MainTest.AddWriter(cCHXTWConsole));
  Console.ShowInfo := True;
  Console.ShowProgress := True;

  RunCode := MainTest.RunAllCases;
  Results := MainTest.TestResults;
  Info := MainTest.TestCases[0].TestResults.Info;
  MainTest.Free;

  if (RunCode = 0)
    and IsExpectedResult(Results, Info, Iterations) then
    ExitCode := 0
  else
  begin
    WriteLn('ProgressTest: unexpected results.');
    ExitCode := 1;
  end;
end.
