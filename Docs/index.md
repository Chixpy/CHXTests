# CHX Test Runner — Documentation

Reference documentation for the library in its current state. For a short
overview and a first program, see the [README](../README.md); this directory
goes unit by unit and explains the behaviour in detail.

## What the library does

`ucCHXTestGroup` is a small test runner for Free Pascal. A test group is a
class whose **published, parameterless methods** are the test cases. The engine
discovers them at runtime, runs them, aggregates counters and results, and
notifies a set of writers (`ucCHXTestWriter` descendants) with the events of
the run.

Two writers are included:

- `ucCHXTWConsole`: human-readable console output and final summary.
- `ucCHXTWJSON`: machine-readable JSON document.

The engine and the writers are decoupled: a group can have several writers, and
writers are propagated to the children of the group that owns them.

## Units

| Unit | Purpose |
| --- | --- |
| `utCHXTestResults` | `tCHXTestResultType` and `tCHXTestResults`. No dependencies. |
| `ucCHXTestWriter` | `cCHXTestWriter` base class, `tCHXTestFailure` and lists. |
| `ucCHXTestGroup` | Engine: `cCHXTestGroup`, cases, assertions, registration. |
| `ucCHXTestGroup.inc` | Macro include that generates the comparison assertions. |
| `ucCHXTWConsole` | Console writer. |
| `ucCHXTWJSON` | JSON writer. |

Dependency direction:

```text
utCHXTestResults      (pure data)
      ^
      |
ucCHXTestWriter  <---+--- ucCHXTWConsole
      ^                  ucCHXTWJSON
      |
ucCHXTestGroup
```

- [utCHXTestResults](utCHXTestResults.md)
- [ucCHXTestGroup](ucCHXTestGroup.md)
- [ucCHXTestGroup.inc](ucCHXTestGroup.inc.md)
- [ucCHXTestWriter](ucCHXTestWriter.md)
- [ucCHXTWConsole](ucCHXTWConsole.md)
- [ucCHXTWJSON](ucCHXTWJSON.md)
- [Example programs](Examples.md)

## Requirements and build

Free Pascal 3.2 or newer (tested with 3.3.1). The library itself has no
external dependencies; only `Examples/JSONTest` needs `fcl-json` to validate
its document.

The units live at the repository root, so a program only needs the root in its
unit path:

```sh
fpc -Fu/path/to/CHXTests -gl -O- -Ciort MyTests.pas
```

Examples are compiled from `Examples/`, where `fpcfg.cfg` sets `-Fu..` and
`-Fi..` and writes the binaries to `Examples/bin`:

```sh
cd Examples
./build.sh BasicTest.pas
./bin/BasicTest
```

Compiling with optimizations off and line information (`-O- -gl`) is
recommended: failure messages and backtraces depend on it.

## Minimal program

```pascal
program SimpleTest;

{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  ucCHXTestGroup, ucCHXTWConsole;

type
  {$PUSH}{$M+}
  cTestCases = class(cCHXTestGroup)
  published
    procedure ExampleCaseSuccess;
    procedure ExampleCaseFail;
  end;
  {$POP}

procedure cTestCases.ExampleCaseSuccess;
begin
  MustTrue(True);
end;

procedure cTestCases.ExampleCaseFail;
begin
  MustTrue(False);
end;

var
  MainTest : cTestCases;

begin
  MainTest := cTestCases.Create('SimpleTest');
  MainTest.AddWriter(cCHXTWConsole);
  try
    ExitCode := MainTest.RunAllCases;
  finally
    MainTest.Free;
  end;
end.
```

## Exit codes

`RunAllCases` and `RunCase` return the exit code of the run:

| Code | Meaning |
| --- | --- |
| `0` | Success: every case passed. |
| `1` | Failure: at least one assertion failed. |
| `2` | Error: at least one unexpected exception, or a requested case does not exist. |
| `3` | Nothing was executed: the group or the case was skipped or never finished. |

The sentinel `3` is computed from the result enum, not hardcoded: it is one
step above the highest real code. See
[utCHXTestResults](utCHXTestResults.md#result-aggregation) for the details.
