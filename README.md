# CHX Test Runner

Class to run groups of test cases and report errors, failures and other stuff.

## Building the examples

Requirements: FPC 3.2+ (tested with 3.3.1). No external dependencies beyond
the FPC RTL.

From the `Examples/` directory:

- Linux/macOS/Termux: `./build.sh BasicTest.pas`
- Windows: `Build.bat BasicTest.pas`

Executables are written to `Examples/bin` and compiled units to
`Examples/lib`.

`SelfTest.pas` checks the runner itself: it exits with `0` when all its
expected results match, and with `1` otherwise.

`SoftTest.pas` shows soft assertions: it exits with `0` when its intentional
soft failures and their combined messages are produced.

## Simple use program

1. Create a `cCHXTestGroup` descendant, with tests procedures in published
  section.
2. Add a `cCHXTestWriter` descendant class to previous `cCHXTestGroup`.
3. `[cCHXTestGroupChild].RunAllCases`
4. For more verbosity, compile with optimizations off and `-gl` (`lineinfo`
  unit) parameter.
  
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
  MainTest := cTestCases.Create;
  MainTest.AddWriter(cCHXTWConsole);
  ExitCode := MainTest.RunAllCases;
  MainTest.Free;
end.
```

`RunAllCases` returns `0` on success, `1` on failure, `2` on error and `3`
when nothing was executed (skipped). Assign it to `ExitCode` for batch use.

## Features

- Simple and functional.
- Nested subtests can be added as a tree (manually or by test name).
- Automatically create tree structure of multiple levels based on name.
- Test groups and test cases can be disabled.
- Auto register testing classes in units. I don't like globals, but in this
  specific case this kind of program will not do anything more.
- Testing engine and Test Writers (Listeners / Observers) are decoupled.
- Various Writers can report simultanealy.
- Virtual method at start and end of test cases, same for (sub)tests and global.
- Include file `ucCHXTestGroup.inc` for _easy_ creation of asserts for custom
  types using FPC macros.
- Statistics about time spent and total assertions made.
- Writers are notifyed in real time (like an _Observer_ pattern), so a console
  writer can show some activity while waiting...
- Returns a value that can be used as a program _exit code_ (`0` success,
  `1` failure, `2` error, `3` skipped/nothing executed), for example for
  running in a batch.
- `Must*` hard assertions and `May*` soft assertions. A soft failure lets the
  case continue and marks it as failed at the end; if a later `Must*` fails,
  both messages are reported.
- Exception assertions: `MustRaise`, `MustNotRaise`, `MayRaise` and
  `MayNotRaise`, including method-reference overloads.
- TODO: Send status info to listeners. (For example: Progress or debug info.).
- TODO: More assertions for inheritance, class types testing and nil.
  More especifically:
  - String: Empty, _Nil_ (specially `PChar`). Regex matching.
  - Integer types: Positive (for signed), Zero.
  - Float types: Positive, Zero, _Nan_, Infinite (Pos, Neg or both).
  - Interfaces:
  - Classes: Inheritance, Class matching, _Nil_.
  - Tecnically all are shortcuts of `if Cond then Fail()` (except exceptions)
- TODO: Auto register writers...
