# utCHXTestResults

Unit of `tCHXTestResults`, the record used by cases, groups and complete runs.
It has no dependency on the engine or on the writers, so consumers can include
it alone (for example, a program that only reads exit codes and counters).

```pascal
uses utCHXTestResults;
```

## `tCHXTestResultType`

```pascal
tCHXTestResultType = (
  rtNone, rtStart, rtSkip, rtSuccess, rtFailed, rtError);
```

| Value | Meaning |
| --- | --- |
| `rtNone` | No result yet. |
| `rtStart` | The test or case started and has not finished. |
| `rtSkip` | The case was disabled, or the group is disabled or empty. |
| `rtSuccess` | All assertions passed. |
| `rtFailed` | An assertion failed: `eCHXTestFailed` was raised. |
| `rtError` | Any other exception was raised. |

The order is **load-bearing**: `AddResult` aggregates by taking the highest
value, so the enum must never be reordered.

### Result aggregation

A group builds its result from its cases and children:

```text
rtNone < rtStart < rtSkip < rtSuccess < rtFailed < rtError
```

This means that a single failed case turns the group into `rtFailed`, and an
unexpected exception in any descendant turns it into `rtError`.

`TestResultExitCode` in `ucCHXTestGroup` maps this order to process exit codes:
`rtSuccess` is `0`, `rtFailed` is `1`, `rtError` is `2`. Every value below
`rtSuccess` (`rtNone`, `rtStart`, `rtSkip`) maps to the sentinel `3`.

## `tCHXTestResults`

Record shared by one case, one group and a whole run.

### Fields

| Field | Meaning |
| --- | --- |
| `TestName` | Name of the case or group. |
| `TreeDepth` | Nesting level; `0` is the root group. |
| `NAsserts` | Assertions evaluated in the case or subtree. |
| `NCases` | Cases in the subtree, including skipped ones. |
| `NOwnedCases` | Cases declared directly by this group. |
| `NSubTests` | Test groups in the subtree. |
| `NSkippedGroups` | Groups reported as skipped in the subtree. |
| `NSkip` | Skipped cases. |
| `NSuccess` | Successful cases. |
| `NFailed` | Failed cases. |
| `NError` | Cases that raised an unexpected exception. |
| `TimeElapsed` | Elapsed time in milliseconds. |
| `ResultType` | Highest result of the case or subtree. |
| `FailedAssert` | Name of the failed assertion or failing statement. |
| `Message` | Failure or error message, including soft failure details. |
| `BackTrace` | Backtrace line of the failure, when available. |
| `Info` | Persistent information sent by the case, joined with `LineEnding`. |

Some details worth knowing:

- `NOwnedCases` and `NCases` are equal for a leaf case. For a group,
  `NCases` grows as the results of its children are merged.
- `NSubTests` holds the number of **descendants** while a group runs. The root
  group adds itself at the end of the run, so after `RunAllCases` the value
  includes the root. The console start line prints the number of direct
  children, because that is what the counter holds at that moment.
- `TimeElapsed` is not added by `AddResult`: each group measures its own total
  separately, so a group shows the wall-clock time of its subtree while the
  case times stay independent.

### `Init`

```pascal
procedure Init(const aName : String = '');
```

Resets every field: result `rtNone`, counters `0`, strings empty, and
`TestName` set to `aName`.

```pascal
var
  R : tCHXTestResults;
begin
  R.Init('MyCase');
  // R.ResultType = rtNone, R.NAsserts = 0, R.TestName = 'MyCase'
end;
```

### `AddResult`

```pascal
procedure AddResult(const aResult : tCHXTestResults);
```

Merges another result into this one:

- counters are added,
- the result type becomes the highest of both,
- `TimeElapsed` is left untouched.

```pascal
var
  Root, Child : tCHXTestResults;
begin
  Root.Init('Root');
  Child.Init('Child');
  Child.ResultType := rtFailed;
  Child.NCases := 1;
  Child.NFailed := 1;

  Root.AddResult(Child);
  // Root.ResultType = rtFailed, Root.NCases = 1, Root.NFailed = 1
end;
```

## Reading the counters from a program

After a run, the group keeps its result:

```pascal
MainTest := cTestCases.Create;
MainTest.AddWriter(cCHXTWConsole);
RunCode := MainTest.RunAllCases;

WriteLn('success: ', MainTest.TestResults.NSuccess);
WriteLn('failed : ', MainTest.TestResults.NFailed);
WriteLn('errors : ', MainTest.TestResults.NError);
WriteLn('skipped: ', MainTest.TestResults.NSkip);

MainTest.Free;
```

Per-case results are also available, because `RunAllCases` writes each case
result back into `TestCases`:

```pascal
WriteLn(MainTest.TestCases[0].CaseName, ': ',
  Ord(MainTest.TestCases[0].TestResults.ResultType));
WriteLn(MainTest.TestCases[0].TestResults.Info);
```

`TestCases` is a list of **records**. To modify an entry, read a copy, change
it and assign it back:

```pascal
aCase := MainTest.TestCases[0];
aCase.Enabled := False;
MainTest.TestCases[0] := aCase;
```

or simply call `SetCaseEnabled`.
