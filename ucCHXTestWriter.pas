unit ucCHXTestWriter;
{< Unit of cCHXTestWriter.

  Base class for test result writers (also called listeners or observers).
  The engine calls the non-virtual `Process*` methods, which track the group
  path and collect failures before forwarding the events to the virtual `On*`
  hooks. Descendants only override the hooks and, optionally, `WriteSummary`.

  Writers added by class type through `cCHXTestGroup.AddWriter` are created
  and freed by the group and attached to its direct children. Writers added as
  instances stay owned by the caller and are attached only to that group.

  @seealso(ucCHXTestGroup)
  @seealso(utCHXTestResults)
}
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
    //< `'.'`-joined group path, for example `Root.Child`. Empty at root.

    CaseName : String;
    //< Name of the failed or errored case.

    ResultType : tCHXTestResultType;
    //< `rtFailed` for a failed assertion, `rtError` for any other exception.

    FailedAssert : String;
    //< Name of the failed assertion or of the failing statement.

    Message : String;
    //< Failure or error message, including soft failure details.

    BackTrace : String;
    //< Backtrace line of the failure, when available.

    Info : String;
    //< Persistent information sent by the case before it ended.
  end;

  tCHXTestFailureList = specialize TList<tCHXTestFailure>;
  //< List of collected failures, owned by the writer.

{ cCHXTestWriter }

  cCHXTestWriter = class(tObject)
  {< Base class for test result writers.

    Override the virtual `On*` methods to render or store information, and
    `WriteSummary` to print a summary after the run. Never override the
    non-virtual `Process*` methods: they maintain the internal path stack used
    by `CurrentPath` and collect the entries of `Failures` before calling the
    hooks.

    Minimal descendant:

    ```
    cMyWriter = class(cCHXTestWriter)
      procedure OnCaseEnd(
        const TestResult : tCHXTestResults); override;
    end;
    ```
  }
  private
    FFailures : tCHXTestFailureList;
    FPathStack : TStringList;

    procedure AddFailure(const TestResult : tCHXTestResults);
    //< Append a failed or errored case to `Failures`, with the current path.

  protected
    function CurrentPath : String;
    {< Path of the group currently being processed.

      The engine pushes a group name in `ProcessTestStart` before calling
      `OnTestStart`, so during `OnTestStart` and `OnCaseEnd` this is the
      containing group path. It is empty outside a run.
    }

  public
    ShowSummary : Boolean;
    //< Call `WriteSummary` after `OnAfterEnd` when a run finishes.

    constructor Create; virtual;
    {< Create the writer with `ShowSummary` enabled and empty collections. }

    destructor Destroy; override;
    {< Free the collected failures and the path stack. }

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
    {< Render the collected failures. The default implementation does nothing.

      It is called automatically after `OnAfterEnd` when `ShowSummary` is
      enabled, and `Failures` is already complete at that point.
    }

    procedure OnBeforeStart; virtual;
    {< Called once before the observed root group starts. }

    procedure OnTestStart(const TestResult : tCHXTestResults); virtual;
    {< Called when a group starts. `TestResult` is the group result so far. }

    procedure OnTestEnd(const TestResult : tCHXTestResults); virtual;
    {< Called when a group ends, with its aggregated results. }

    procedure OnCaseStart(const TestResult : tCHXTestResults); virtual;
    {< Called when a case starts. `TestResult` already has `rtStart`. }

    procedure OnCaseEnd(const TestResult : tCHXTestResults); virtual;
    {< Called when a case ends, whatever its result.

      Failed and errored cases have already been appended to `Failures` when
      this hook runs.
    }

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
    {< Called once after the observed root group ends, before `WriteSummary`.

      A writer attached only to a child group never receives this event,
      because only the root group emits it.
    }
  end;

  tCHXTestWriterClass = class of cCHXTestWriter;
  //< Writer class reference used by `cCHXTestGroup.AddWriter`.

  cCHXTestWriterGenList  = specialize tObjectList<cCHXTestWriter>;
  //< Owning list of writers; used for the writers created by the engine.

  cCHXTestWriterList  = class(cCHXTestWriterGenList)
  end;
  //< List of writers attached to a group.

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
