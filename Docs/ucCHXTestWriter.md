# ucCHXTestWriter

Base class for writers, also called listeners or observers. The engine and the
writers are decoupled: `cCHXTestGroup` calls non-virtual `Process*` methods,
which keep the internal state and forward each event to a virtual `On*` hook.

```pascal
uses ucCHXTestWriter, utCHXTestResults;
```

## Class model

```pascal
cCHXTestWriter = class(TObject)
protected
  function CurrentPath : String;
public
  ShowSummary : Boolean;
  property Failures : tCHXTestFailureList read;
  procedure WriteSummary; virtual;
  procedure OnBeforeStart; virtual;
  procedure OnTestStart(const TestResult : tCHXTestResults); virtual;
  procedure OnTestEnd(const TestResult : tCHXTestResults); virtual;
  procedure OnCaseStart(const TestResult : tCHXTestResults); virtual;
  procedure OnCaseEnd(const TestResult : tCHXTestResults); virtual;
  procedure OnCaseInfo(const TestResult : tCHXTestResults;
    const Text : String); virtual;
  procedure OnCaseProgress(const TestResult : tCHXTestResults;
    const Text : String; const Percent : Integer); virtual;
  procedure OnAfterEnd(const TestResult : tCHXTestResults); virtual;
end;
```

Descendants override the `On*` hooks and, optionally, `WriteSummary`. The
non-virtual `Process*` methods are the engine's entry points and must not be
overridden: they maintain the group path and collect failures before the hook
runs.

## Events

| Hook | When |
| --- | --- |
| `OnBeforeStart` | Once, before the observed root group starts. |
| `OnTestStart` | A group starts. `TestResult` is the group result so far. |
| `OnTestEnd` | A group ends, with aggregated results. |
| `OnCaseStart` | A case starts; its result is already `rtStart`. |
| `OnCaseEnd` | A case ends, whatever its result. |
| `OnCaseInfo` | A case sent persistent information with `SendInfo`. |
| `OnCaseProgress` | A case sent transient progress with `SendProgress`. |
| `OnAfterEnd` | Once, after the observed root group ends. |
| `WriteSummary` | After `OnAfterEnd`, when `ShowSummary` is `True`. |

A writer attached only to a child group never receives `OnBeforeStart` or
`OnAfterEnd`, because only the root emits them.

## Paths

`CurrentPath` is the `'.'`-joined path of the group being processed. The engine
pushes the group name in `ProcessTestStart` before calling `OnTestStart`, so:

- during `OnCaseEnd` and `OnCaseStart` it is the path of the containing group,
- during `OnTestStart` and `OnTestEnd` it already includes the group itself,
- outside a run it is empty.

For a case inside `Root.Child`, `CurrentPath` is `Root.Child`. The JSON writer
uses it as the `path` of each case; the console writer composes
`TestPath + '.' + CaseName` for summary lines.

## Failures

`ProcessCaseEnd` appends failed and errored cases to `Failures` **before**
calling `OnCaseEnd`:

| Field | Meaning |
| --- | --- |
| `TestPath` | Path of the containing group. |
| `CaseName` | Case name. |
| `ResultType` | `rtFailed` or `rtError`. |
| `FailedAssert` | Name of the failed assertion or statement. |
| `Message` | Failure or error message. |
| `BackTrace` | Backtrace line, when available. |
| `Info` | Persistent information sent by the case. |

The list is cleared at the start of each run: in `ProcessBeforeStart`, and in
`ProcessTestStart` when the writer did not receive `ProcessBeforeStart`
(the case of a writer attached only to a child).

## Summary

`ShowSummary` defaults to `True`. At the end of the observed root,
`ProcessAfterEnd` calls `OnAfterEnd` and then `WriteSummary`:

```pascal
procedure cCHXTestWriter.ProcessAfterEnd(
  const TestResult : tCHXTestResults);
begin
  OnAfterEnd(TestResult);
  if ShowSummary then
    WriteSummary;
end;
```

The base `WriteSummary` does nothing. `cCHXTWConsole` prints the collected
failures and errors; `cCHXTWJSON` ignores it.

## Minimal descendant

```pascal
type
  cCountingWriter = class(cCHXTestWriter)
  private
    FCases : Integer;
  public
    procedure OnCaseEnd(
      const TestResult : tCHXTestResults); override;
    property Cases : Integer read FCases;
  end;

procedure cCountingWriter.OnCaseEnd(
  const TestResult : tCHXTestResults);
begin
  Inc(FCases);
  if TestResult.ResultType = rtFailed then
    WriteLn('Failed: ', CurrentPath, '.', TestResult.TestName);
end;
```

```pascal
MainTest := cTestCases.Create;
Writer := cCountingWriter.Create;
MainTest.AddWriter(Writer);      // the caller owns it
try
  MainTest.RunAllCases;
  WriteLn('cases: ', Writer.Cases);
finally
  MainTest.Free;
  Writer.Free;
end;
```

`CurrentPath` is `protected`, so it is available to descendants only. A writer
that needs the path publicly can expose it with a property.

## Other types

| Type | Purpose |
| --- | --- |
| `tCHXTestWriterClass` | Class reference used by `cCHXTestGroup.AddWriter`. |
| `cCHXTestWriterGenList` | Owning list of writers (`TObjectList<cCHXTestWriter>`). |
| `cCHXTestWriterList` | List of writers attached to a group. |
| `tCHXTestFailure` | One entry of `Failures`. |
| `tCHXTestFailureList` | `TList<tCHXTestFailure>`. |

## Ownership

`cCHXTestGroup.AddWriter(Class)` creates the instance and keeps it in the
group's owned list. `AddWriter(Instance)` only stores the instance; the caller
must free it.

A writer receives events from the group it is attached to and from the groups
and cases below it, so one writer per root is the usual setup. See
[ucCHXTestGroup](ucCHXTestGroup.md#writers) for propagation rules.
