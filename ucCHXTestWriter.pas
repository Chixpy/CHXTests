unit ucCHXTestWriter;

{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH TypeHelpers}

interface

uses
  Classes, Generics.Collections, utCHXTestResults;

type

  tCHXTestFailure = record
  {< Data needed to report a failed or errored case in the final summary. }
    TestPath : String;
    CaseName : String;
    ResultType : tCHXTestResultType;
    FailedAssert : String;
    Message : String;
    BackTrace : String;
    Info : String;
  end;

  tCHXTestFailureList = specialize TList<tCHXTestFailure>;

{ cCHXTestWriter }

  cCHXTestWriter = class(tObject)
  private
    FFailures : tCHXTestFailureList;
    FPathStack : TStringList;

    function CurrentPath : String;
    procedure AddFailure(const TestResult : tCHXTestResults);

  public
    ShowSummary : Boolean;
    //< Call `WriteSummary` after `OnAfterEnd` when a run finishes.

    constructor Create; virtual;
    destructor Destroy; override;

    procedure ProcessBeforeStart;
    procedure ProcessTestStart(const TestResult : tCHXTestResults);
    procedure ProcessTestEnd(const TestResult : tCHXTestResults);
    procedure ProcessCaseStart(const TestResult : tCHXTestResults);
    procedure ProcessCaseEnd(const TestResult : tCHXTestResults);
    procedure ProcessAfterEnd(const TestResult : tCHXTestResults);
    {< Non-virtual event processors used by `cCHXTestGroup`.

      They keep the path stack and collect failed/errored cases before calling
      the corresponding virtual `On*` hook. Writers must override the hooks,
      not these processors.
    }

    property Failures : tCHXTestFailureList read FFailures;
    {< Failed and errored cases collected during the current run. }

    procedure WriteSummary; virtual;
    {< Render the collected failures. The default implementation does nothing. }

    procedure OnBeforeStart; virtual;
    procedure OnTestStart(const TestResult : tCHXTestResults); virtual;
    procedure OnTestEnd(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseStart(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseEnd(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseInfo(const TestResult : tCHXTestResults;
      const Text : String); virtual;
    {< Called when a case sends persistent information.

      `TestResult.Info` already contains the new text appended. Writers that
      only need the final information can ignore this callback and use
      `OnCaseEnd`.
    }
    procedure OnCaseProgress(const TestResult : tCHXTestResults;
      const Text : String; const Percent : Integer); virtual;
    {< Called when a case sends transient progress.

      `Percent` is a value from 0 to 100, or -1 when it is not available.
      Progress is not stored in `TestResult`.
    }
    procedure OnAfterEnd(const TestResult : tCHXTestResults); virtual;
  end;

  tCHXTestWriterClass = class of cCHXTestWriter;

  cCHXTestWriterGenList  = specialize tObjectList<cCHXTestWriter>;
  cCHXTestWriterList  = class(cCHXTestWriterGenList)
  end;

implementation

constructor cCHXTestWriter.Create;
begin
  inherited Create;

  FFailures := tCHXTestFailureList.Create;
  FPathStack := TStringList.Create;

  ShowSummary := True;
end;

destructor cCHXTestWriter.Destroy;
begin
  FPathStack.Free;
  FFailures.Free;

  inherited Destroy;
end;

function cCHXTestWriter.CurrentPath : String;
var
  i : Integer;
begin
  Result := '';

  for i := 0 to FPathStack.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + '.';
    Result := Result + FPathStack[i];
  end;
end;

procedure cCHXTestWriter.AddFailure(const TestResult : tCHXTestResults);
var
  aFailure : tCHXTestFailure;
begin
  aFailure.TestPath := CurrentPath;
  aFailure.CaseName := TestResult.TestName;
  aFailure.ResultType := TestResult.ResultType;
  aFailure.FailedAssert := TestResult.FailedAssert;
  aFailure.Message := TestResult.Message;
  aFailure.BackTrace := TestResult.BackTrace;
  aFailure.Info := TestResult.Info;

  FFailures.Add(aFailure);
end;

procedure cCHXTestWriter.ProcessBeforeStart;
begin
  FPathStack.Clear;
  FFailures.Clear;

  OnBeforeStart;
end;

procedure cCHXTestWriter.ProcessTestStart(
  const TestResult : tCHXTestResults);
begin
  // A writer attached only to a child may not receive ProcessBeforeStart.
  if FPathStack.Count = 0 then
    FFailures.Clear;

  FPathStack.Add(TestResult.TestName);

  OnTestStart(TestResult);
end;

procedure cCHXTestWriter.ProcessTestEnd(const TestResult : tCHXTestResults);
begin
  try
    OnTestEnd(TestResult);
  finally
    if FPathStack.Count > 0 then
      FPathStack.Delete(FPathStack.Count - 1);
  end;
end;

procedure cCHXTestWriter.ProcessCaseStart(
  const TestResult : tCHXTestResults);
begin
  OnCaseStart(TestResult);
end;

procedure cCHXTestWriter.ProcessCaseEnd(const TestResult : tCHXTestResults);
begin
  if TestResult.ResultType in [rtFailed, rtError] then
    AddFailure(TestResult);

  OnCaseEnd(TestResult);
end;

procedure cCHXTestWriter.ProcessAfterEnd(const TestResult : tCHXTestResults);
begin
  OnAfterEnd(TestResult);

  if ShowSummary then
    WriteSummary;
end;

procedure cCHXTestWriter.WriteSummary;
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnBeforeStart;
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnTestStart(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnTestEnd(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseStart(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseEnd(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseInfo(const TestResult : TCHXTestResults;
  const Text : String);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseProgress(const TestResult : TCHXTestResults;
  const Text : String; const Percent : Integer);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnAfterEnd(const TestResult : tCHXTestResults);
begin
  // Do nothing by default
end;

initialization

finalization

end.
