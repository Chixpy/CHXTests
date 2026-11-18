# ucCHXTestGroup

The test engine. `cCHXTestGroup` holds cases, child groups and writers, runs
them and reports every event to the writers. The assertions live in the same
class, so a test case only has to call them.

```pascal
uses ucCHXTestGroup;                 // engine and assertions
uses ucCHXTestGroup, ucCHXTWConsole; // engine plus the console writer
```

## Test cases

Test cases are the **published, parameterless** methods of a
`cCHXTestGroup` descendant:

```pascal
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
  MustTrue(False, 'Custom text on fail.');
end;
```

- Methods are discovered at runtime from the VMT method table in the
  constructor. Public and private methods are silently ignored.
- The `{$M+}` switch is not strictly needed: `cCHXTestGroup` is compiled with
  type info, and descendants inherit it. It is kept in the examples for clarity.
- Discovery walks the whole class hierarchy, so methods published in a parent
  class are also cases of the descendant. An overridden method replaces the
  inherited one.
- Cases are stored in `TestCases` in discovery order. A disabled case is
  reported as skipped and never called.

The class keeps its cases as a list of records, so to modify one read a copy,
change it and assign it back, or use `SetCaseEnabled`:

```pascal
MainTest.SetCaseEnabled('ExampleCaseSkiped', False);
```

## Groups and tree building

A group can contain cases and other groups:

```pascal
MainTest := cTest1.Create;
SubTest := MainTest.AddChildTest(cTest1a);   // owned by MainTest
SubTest.AddChildTest(cTest1a1);              // owned by SubTest
```

Two overloads exist:

| Call | Ownership |
| --- | --- |
| `AddChildTest(Class)` | The group creates the instance and frees it on `Destroy`. |
| `AddChildTest(Instance)` | The instance is **not** freed; the caller owns it. |

Rules of `AddChildTest`:

- `TreeDepth` of the new child is the depth of the parent plus one.
- The child receives a copy of the parent's current writer list.
- Adding the same instance twice (as a direct child) is ignored.
- When a child with the same name already exists:
  - if it is a `cCHXEmptyTestGroup` placeholder, it is replaced by the new
    group and its children, cases and writers are transferred;
  - if it is a real group, the new one is not added, to avoid duplicates.
- A name containing `.`, `/` or `\` creates intermediate empty groups. The
  first separator found is used, checking `.` first, then `/`, then `\`:

```pascal
MainTest.AddChildTest(SubSubTest, 'Level1/Level2/Leaf');
// Creates the placeholders 'Level1' and 'Level2' and adds 'Leaf' below them.
```

If the first segment equals the current group name, it is dropped, so both
`MainTest.AddChildTest(T, 'MainTest.Child')` and
`MainTest.AddChildTest(T, 'Child')` add `Child` below `MainTest`.

A disabled group is reported as `rtSkip`, increments `NSkippedGroups` and its
own cases are counted as skipped, but **its children are not visited**. A group
without cases and without children is also reported as skipped and increments
`NSkippedGroups`.

## Writers

Writers are attached to groups and receive the events of that group and its
cases:

```pascal
MainTest.AddWriter(cCHXTWConsole);           // created and owned by the group

Writer := cCHXTWJSON.Create;
MainTest.AddWriter(Writer);                  // caller owns it
```

The class overload creates the instance, keeps it in `OwnedWriters` and frees
it with the group. The instance overload only stores it in `TestWriters`.

Propagation:

- The `AddWriter(Class)` overload copies the new writer into the **direct**
  children, existing and future. It is not propagated recursively to
  grandchildren.
- The `AddWriter(Instance)` overload attaches the writer only to that group.
- A child added later receives a copy of the parent's writer list at the moment
  it is added.
- A writer added to a child is never propagated to its parent.
- Add writers before building the tree to have every group writing.

See [ucCHXTestWriter](ucCHXTestWriter.md) for the event model.

## Running

### `RunAllCases`

```pascal
ExitCode := MainTest.RunAllCases;
```

Runs every case of the group and of its children, recursively. Event order:

| Step | Root group | Child group |
| --- | --- | --- |
| 1 | `DoBeforeStart` + `OnBeforeStart` | — |
| 2 | `TestResultInit` | `TestResultInit` |
| 3 | `DoTestStart` + `OnTestStart` | `DoTestStart` + `OnTestStart` |
| 4 | each case: start, execute, end | each case: start, execute, end |
| 5 | each child: its own `RunAllCases` | each child: its own `RunAllCases` |
| 6 | `DoTestEnd` + `OnTestEnd` | `DoTestEnd` + `OnTestEnd` |
| 7 | `DoAfterEnd` + `OnAfterEnd` + `WriteSummary` | — |

A group that was created but never added to a parent has `TreeDepth = 0`, so it
behaves as a root and emits the before/after events.

### `RunCase`

```pascal
Code := MainTest.RunCase('ExampleCaseSuccess'); // by name
MainTest.RunCase(@aCase);                       // by pointer
```

`RunCase` runs one case without group events: writers receive only the case
events, and the group counters are not updated. The result **is** written back
to the case record.

- By name, the search is case-insensitive. A missing case returns the error
  code (`2`).
- By pointer, the case must belong to the group. This overload avoids a second
  lookup when the caller already has the position.

## Results and exit codes

The group result is the highest result of its cases and children:

```text
rtNone < rtStart < rtSkip < rtSuccess < rtFailed < rtError
```

| Code | Meaning |
| --- | --- |
| `0` | Every case passed. |
| `1` | At least one assertion failed. |
| `2` | At least one unexpected exception, or the requested case is missing. |
| `3` | Nothing was executed: skipped case or group, or the run never finished. |

The counters of the last run are available in `TestResults` (`NAsserts`,
`NCases`, `NSuccess`, `NFailed`, `NError`, `NSkip`, `NSkippedGroups`,
`NSubTests`, `TimeElapsed`). See [utCHXTestResults](utCHXTestResults.md).

`NSubTests` is worth an explanation: while a group runs it holds the number of
its descendants, and the root adds itself when the run ends. After
`RunAllCases` on the root it is the total number of groups, root included.

## Assertions

All assertions increment `NAsserts` of the current case.

### Hard assertions

They raise `eCHXTestFailed`, which aborts the current case and marks it as
`rtFailed`:

```pascal
MustTrue(Condition, Sender, Msg, ErrAdrs);
MustFalse(Condition, Sender, Msg, ErrAdrs);
```

| Parameter | Meaning |
| --- | --- |
| `Condition` | Condition to check. |
| `Sender` | Name of the failing statement. Defaults to the calling method. |
| `Msg` | Failure message. Defaults to `rsNotTrue` / `rsNotFalse`. |
| `ErrAdrs` | Address of the failing method. `nil` uses the caller address; only custom assertions pass it. |

```pascal
MustTrue(1 + 1 = 2);
MustFalse(FileExists('missing.txt'), 'Unexpected file exists',
  'missing.txt should not exist');
```

A failed assertion stops the case, so later statements are not executed:

```pascal
procedure cTestCases.Example;
begin
  MustTrue(False);
  WriteLn('never printed');
end;
```

### Soft assertions

They record the failure and keep the case running:

```pascal
MayTrue(Condition, Sender, Msg, ErrAdrs);
MayFalse(Condition, Sender, Msg, ErrAdrs);
```

When the case ends, the recorded failures make it fail. If a later `Must*`
also fails, both messages are reported: the hard failure message followed by a
`Soft failures (N):` block.

```pascal
procedure cTestCases.Example;
begin
  MayTrue(False, 'First soft failure', 'first soft failure');
  WriteLn('still running');
  MayEqual(10, 20, 'Second soft failure', 'second soft failure');
  MustTrue(True);
end;
```

The case is reported as failed, with the list of soft failures as the message.
See `Examples/SoftTest.pas`.

### Exception assertions

```pascal
MustRaise(Proc, Expected, Sender, Msg, ErrAdrs);
MustNotRaise(Proc, Sender, Msg, ErrAdrs);
MayRaise(Proc, Expected, Sender, Msg, ErrAdrs);
MayNotRaise(Proc, Sender, Msg, ErrAdrs);
```

`Proc` accepts both a plain `TProcedure` and a method reference
(`tTestMethod`). `Expected` matches the exception class or any subclass; `nil`
means `Exception`.

```pascal
procedure RaiseExpected;
begin
  raise EMyError.Create('Expected exception.');
end;

procedure cTestCases.ExampleRaisesExpected;
begin
  MustRaise(@RaiseExpected, EMyError);
end;
```

Special rules:

- An `eCHXTestFailed` raised by a `Must*` inside `Proc` is re-raised, unless
  the expected class is exactly `eCHXTestFailed`. An inner assertion failure is
  therefore never hidden by an outer raise assertion.
- When the exception does not match, the message is generated from the expected
  and actual classes (`rsWrongExceptionFmt`).
- When nothing is raised, the message is generated from the expected class
  (`rsExpectedExceptionFmt`).

`MayRaise` reports at most one failure: a wrong exception is not reported twice
as a missing one.

See `Examples/ExceptionTest.pas`.

### Comparison assertions

Generated from [ucCHXTestGroup.inc](ucCHXTestGroup.inc.md) for the built-in
types:

| Type | `Must`/`May` methods |
| --- | --- |
| `Int64`, `QWord`, `Char`, `String`, `Currency` | `MustEqual` (`=`), `MustNotEqual` (`<>`), `MustGreater` (`>`), `MustLess` (`<`), `MustGrtEqu` (`>=`), `MustLssEqu` (`<=`) |
| `Single`, `Double` | `MustEqual`/`MustNotEqual` with `SameValue` and a `Sigma` argument, plus the four order comparisons |
| `Pointer`, `TObject` | `MustEqual` (`=`), `MustNotEqual` (`<>`) |

Each hard assertion has a `May*` soft counterpart with the same signature.

```pascal
MustEqual(LengthNames, 3, 'Length(Names)');
MustGreater(Count, 0);
MustLssEqu(Ratio, 1.0);
MustEqual(1.0, 1.0001, 0.001);   // SameValue with Sigma
```

The generic signature is:

```pascal
procedure MustEqual(const Value, Correct : Type;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
```

`Value` is the left operand and `Correct` the right one. If `Msg` is not empty
it is formatted with `Format(Msg, [String(Value), String(Correct)])`, that is,
`%0:s` is `Value` and `%1:s` is `Correct`.

Floats do not have `=` and `<>` overloads on purpose: compare them with the
`SameValue` overload and a `Sigma`.

### Custom types

Include `ucCHXTestGroup.inc` in a descendant to generate the same assertions
for a custom type. The include must be added twice (declaration and
implementation) with matching defines, and the include directory must be in the
compiler path (`-Fi`). See [ucCHXTestGroup.inc](ucCHXTestGroup.inc.md).

## Info and progress

A case can report information while it runs:

```pascal
procedure cTestCases.ExampleProgressLoop;
var
  i : Integer;
begin
  SendInfo('Starting loop.');
  for i := 1 to 10 do
    SendProgress(Format('Step %d of 10', [i]), i * 10);
  SendInfo('Loop completed.');
  MustTrue(True);
end;
```

- `SendInfo(Text)` appends persistent text to the current case's
  `TestResults.Info`, joined with `LineEnding`. Outside a case it goes to the
  group result. Writers receive `OnCaseInfo` and the console also prints it in
  the failure summary.
- `SendProgress(Text, Percent)` is transient: it is not stored, writers receive
  `OnCaseProgress`, and `Percent` is `0..100` or `-1` when unknown.

The console only renders them when `ShowInfo` or `ShowProgress` is enabled. See
[ucCHXTWConsole](ucCHXTWConsole.md).

## Registration

Groups can be registered globally and added to a test later:

```pascal
// In the unit that implements the group:
initialization
  RegisterCHXTestGroup(cMyTests, 'My tests');

// In the program:
MainTest.AddRegistered;
```

`RegisterCHXTestGroup` stores the class and a name in the global `CHXRegTests`
array. Registering the same name twice is ignored. `AddRegistered` creates an
instance of every registered class, with default properties, and adds it as a
child of the group.

## Extension hooks

Override the `Do*` methods to run code around the events of the group itself,
without writing a writer:

| Method | Called |
| --- | --- |
| `DoBeforeStart` | On the root, before the run starts. |
| `DoTestStart` / `DoTestEnd` | When this group starts and ends. |
| `DoCaseStart` / `DoCaseEnd` | Before and after each case of this group, with its result. |
| `DoAfterEnd` | On the root, after the run ends. |

They run before the corresponding writer callbacks.

## Caveats

- `TestCases` is a list of records; mutate through a local copy and assign it
  back.
- `TreeDepth` is read-only; it is assigned by the parent when the group is
  added.
- An unexpected exception is reported as `rtError`. Its backtrace points to
  the engine call, not to the exact line inside the case, because the
  information is not recoverable after the exception unwinds. Compile with
  optimizations off and `-gl` for better messages.
- `RunCase` does not update the group counters and does not emit group events;
  the JSON writer therefore produces no document for a bare `RunCase`.
