# CHX Test Runner

Small Free Pascal library to run groups of test cases and report successes,
failures, errors and skipped work.

## Building the examples

Requirements: FPC 3.2+ (tested with 3.3.1). No external dependencies beyond
the FPC distribution; the JSON example and self-test use the `fcl-json`
package.

From the `Examples/` directory:

- Linux/macOS/Termux: `./build.sh BasicTest.pas`
- Windows: `Build.bat BasicTest.pas`

Executables are written to `Examples/bin` and compiled units to
`Examples/lib`.

The examples cover different parts of the runner:

- `BasicTest`: one success, one failure, one error and one disabled case.
- `ExceptionTest`: expected, missing and wrong exceptions.
- `SoftTest`: soft failures and their combination with hard failures.
- `ProgressTest`: `ShowInfo` and `ShowProgress`; its optional first argument
  sets the number of iterations (default 10).
- `SelfTest`: checks the runner itself. It exits with `0` when all expected
  results match and with `1` otherwise.
- `JSONTest`: generates a JSON report with nested groups, failures, errors,
  skips and escaped text, and verifies it with `fpjson`.
- `SimplestTest`, `SubTests`, `Subsubtest`, `WriterAfterChild` and
  `WriterInChild`: minimal programs for groups, nesting and writer ownership.

Except `ProgressTest`, `JSONTest` and `SelfTest`, the examples accept an
optional output file as their first argument. When present, they also add a
JSON writer and save the report there:

```sh
./bin/BasicTest results.json
```

`WriterInChild` attaches the JSON writer to the child group, so its document
starts at that child instead of the main test.

## Simple use program

1. Create a `cCHXTestGroup` descendant with test procedures in the
   `published` section.
2. Add a `cCHXTestWriter` descendant class to the group.
3. Call `RunAllCases` and assign its result to `ExitCode`.
4. For more verbose backtraces, compile with optimizations off and `-gl`
   (`lineinfo`).

```pascal
program SimpleTest;

// Switch off optimizations
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
  MustTrue(False);
end;

{
  Main program
}

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

`RunAllCases` returns `0` on success, `1` on failure, `2` on error and `3`
when nothing was executed (skipped or not started). `RunCase` returns the
same kind of code for one case, and returns `2` when the requested case does
not exist.

## Test semantics

- Cases are the **published, parameterless** methods of a `cCHXTestGroup`
  descendant. They are discovered from the VMT at runtime; public and private
  methods are ignored.
- Groups can contain cases and other groups. Child names containing `.`, `/`
  or `\` create intermediate groups automatically.
- A disabled group returns `rtSkip` and increments `NSkippedGroups`. Its own
  cases are counted as skipped, but its children are not visited.
- A group with no cases or children is also reported as skipped and increments
  `NSkippedGroups`.
- A failed assertion produces `rtFailed`. Any other exception produces
  `rtError`.
- The result of a group is the highest result of its cases and child groups:
  `rtNone` < `rtStart` < `rtSkip` < `rtSuccess` < `rtFailed` < `rtError`.
- `NSkip` counts skipped cases; `NSkippedGroups` counts skipped groups. They
  are deliberately separate.

## Assertions

- `Must*` assertions raise `eCHXTestFailed` and abort the current case.
- `May*` soft assertions record the failure, keep the case running and mark it
  as failed at the end. If a later `Must*` also fails, both messages are
  reported.
- `MustRaise`/`MustNotRaise` check exceptions; `MayRaise`/`MayNotRaise` are
  their soft variants. They accept `TProcedure` and method references; an
  exception matches when it is the expected class or a subclass.
- An internal `eCHXTestFailed` raised inside a raise assertion is re-raised
  unless it is the expected class, so an inner assertion failure is not hidden.
- `ucCHXTestGroup.inc` can be included to generate the assertion overloads for
  custom types.

## Info and progress

Cases can report information while they run:

- `SendInfo(Text)` appends persistent text to the active case's
  `TestResults.Info`, joined with `LineEnding`. It is also included in the
  final failure summary.
- `SendProgress(Text, Percent)` sends transient progress. `Percent` is in the
  range 0..100, or `-1` when unknown; progress is not stored.

Console rendering is opt-in:

- `ShowInfo := True` prints the persistent information at case end.
- `ShowProgress := True` renders progress with carriage returns and restores
  the case line when the case finishes.

## Writers and the final summary

The engine and the writers are decoupled. `AddWriter(Class)` creates and owns
the writer; passing a writer instance does not transfer ownership. Writers are
propagated to existing and future children, but adding one to a child never
propagates upward.

Writers receive the virtual callbacks `OnBeforeStart`, `OnTestStart`,
`OnCaseStart`, `OnCaseEnd`, `OnCaseInfo`, `OnCaseProgress`, `OnTestEnd` and
`OnAfterEnd`. The engine calls these through the non-virtual `Process*`
methods, which also maintain the group path and collect failures. Override the
`On*` hooks (and optionally `WriteSummary`), not the `Process*` methods.

Every writer has:

- `Failures`: a list of `tCHXTestFailure` entries with `TestPath`, `CaseName`,
  `ResultType`, `FailedAssert`, `Message`, `BackTrace` and `Info`. `TestPath`
  is the `.`-joined group path, for example `Root.Child`.
- `ShowSummary`: enabled by default. When the run finishes, the writer calls
  `WriteSummary` after `OnAfterEnd`.
- `WriteSummary`: a virtual method that does nothing in the base class. The
  console writer renders the collected failures and errors below the totals.

To disable the summary, set `ShowSummary := False` on the writer.

The console totals use separate strings for skipped groups and cases:

```text
  ┆ ✅ Success: 1 / ⛔ Skipped (G): 0 / ⚠️ Skipped (C): 1 / ❌ Failed: 1 / ☢️ ¡ERROR!: 1
```

`SkipGroupStr`, `SkipStr`, `SuccessStr`, `FailStr` and `ErrorStr` can be
customized. The symbols and labels depend on the terminal and its font.

## JSON writer

`cCHXTWJSON` produces a machine-readable document. It never writes to the
console and ignores `SendProgress`; `ShowSummary` has no effect.

```pascal
uses ucCHXTestGroup, ucCHXTWJSON;

var
  aWriter : cCHXTWJSON;
...
aWriter := cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON));
aWriter.FileName := 'results.json';
ExitCode := MainTest.RunAllCases;
```

The document is generated when the root group observed by the writer ends, so
even a writer added only to a child produces its own subtree. `FileName` saves
it automatically; `Lines` exposes the text and `SaveError` contains an I/O
error instead of raising it.

```json
{
  "generator": "CHXTests",
  "schemaVersion": 1,
  "name": "Root",
  "path": "Root",
  "result": "failed",
  "durationMs": 12,
  "counts": {
    "asserts": 2, "cases": 2, "groups": 2,
    "success": 1, "skipped": 0, "skippedGroups": 0,
    "failed": 1, "errors": 0
  },
  "cases": [ ... ],
  "groups": [ ... ]
}
```

- Groups and cases are nested, and every node carries its `path`.
- Cases include `result`, `asserts`, `durationMs`, `failedAssert`, `message`,
  `backtrace` and `info`.
- `counts.groups` is the subtree count including the group itself.
- A disabled group is reported as `skip`; its cases are counted in
  `counts.cases`/`counts.skipped` but do not appear in its `cases` array.
- The output is deterministic: there is no timestamp, and durations are in
  milliseconds.
- A single `RunCase` call does not emit group events, so it produces no
  document.

`Examples/JSONTest.pas` shows a complete report and validates it with
`fpjson`.

## Features

- Nested groups, manually or from names with separators.
- Auto-registration of testing classes in units.
- Decoupled testing engine and writers, with several writers at once.
- Real-time callbacks while tests run.
- Hard and soft assertions, exception assertions and custom-type assertions.
- Statistics for time, assertions, cases and groups.
- Exit codes suitable for batch use.
- Collected failure/error summary with case information.
- JSON writer for automated checks.

## Pending ideas

- More assertions for inheritance, class matching and `nil`.
  More specifically:
  - Strings: empty and nil values (especially `PChar`), regular expressions.
  - Integers: positive (signed types) and zero.
  - Floats: positive, zero, NaN and infinities.
  - Interfaces.
  - Classes: inheritance, class matching and `nil`.
- Auto-register writers.
- Select cases and groups with regular expressions.
- Word wrap that preserves indentation in the console writer.
- Configurable progress update interval.
- Additional writers: XML, HTML and Markdown.
