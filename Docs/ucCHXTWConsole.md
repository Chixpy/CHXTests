# ucCHXTWConsole

Writer that renders the run as indented text, with a final totals block and a
summary of the collected failures.

```pascal
uses ucCHXTestGroup, ucCHXTWConsole;
```

## Usage

```pascal
MainTest := cTestCases.Create;
Console := cCHXTWConsole(MainTest.AddWriter(cCHXTWConsole));
Console.ShowInfo := True;       // render SendInfo text
Console.ShowProgress := True;   // render SendProgress with carriage returns
ExitCode := MainTest.RunAllCases;
MainTest.Free;
```

`AddWriter(Class)` creates the writer and the group frees it. The cast exposes
the properties; the engine only knows the `cCHXTestWriter` API.

## Output

Real output of `Examples/BasicTest.pas` (with `ShowSummary` enabled, symbols
and line numbers included):

```text
[12:00:00] cTestCases Start (Cases = 4 Groups = 0)
  ┆ [12:00:00] ExampleCaseSuccess ✅ Success [T=0] (TA=1)
  ┆ [12:00:00] ExampleCaseSkiped ⚠️ Skipped [T=0] (TA=0)
  ┆ [12:00:00] ExampleCaseFail ❌ Failed [T=5] (TA=1)
  ┆   ┆ Custom text on fail.
  ┆   ┆ Condition is not True
  ┆   ┆ $00000000  EXAMPLECASEFAIL,  line 39 of BasicTest.pas
  ┆ [12:00:00] ExampleCaseError ☢️ ¡ERROR! [T=15] (TA=10)
  ┆   ┆ Unexpected Exception: ERangeError
  ┆   ┆ Range check error
  ┆   ┆ $00000000  RUNCASE,  line 1761 of ../ucCHXTestGroup.pas
[T=23] cTestCases ☢️ ¡ERROR! (TA=12 TC=4 / Sk=1 Sc=1 F=1 E=1)

Totals:
  ┆ Time: 00:00:00 / Asserts: 12 / Cases: 4 / Groups: 1
Results:
  ┆ ✅ Success: 1 / ⛔ Skipped (G): 0 / ⚠️ Skipped (C): 1 / ❌ Failed: 1 / ☢️ ¡ERROR!: 1

Failures and errors:
  ┆ ❌ Failed cTestCases.ExampleCaseFail
  ┆   ┆ Assertion: Custom text on fail.
  ┆   ┆ Message: Condition is not True
  ┆   ┆ Backtrace: $00000000  EXAMPLECASEFAIL,  line 39 of BasicTest.pas
  ┆ ☢️ ¡ERROR! cTestCases.ExampleCaseError
  ┆   ┆ Assertion: Unexpected Exception: ERangeError
  ┆   ┆ Message: Range check error
  ┆   ┆ Backtrace: $00000000  RUNCASE,  line 1761 of ../ucCHXTestGroup.pas
```

The totals are printed in `OnAfterEnd`; the failure summary is printed after
them by `WriteSummary`. `(G)` counts skipped groups and `(C)` skipped cases;
they are deliberately separate counters.

The exact symbols and texts depend on the terminal and its font. `✅`, `⚠️`,
`⛔`, `❌` and `☢️` are the defaults; every one can be replaced (see below).

## Format strings

Each output line is produced with `Format`, using these positional arguments.
Any `*Fmt` property can be replaced to change the layout.

| Argument | Value |
| --- | --- |
| `%0:s` | Newline + current indent (`LineEnding` + `IndentStr` × depth). |
| `%1:s` | Additional indent (`IndentStr`). |
| `%2:s` | Group or case name. |
| `%3:d` | Nesting depth. |
| `%4:d` | `NAsserts`: assertions evaluated so far. |
| `%5:d` | `NCases`: cases evaluated in the subtree. |
| `%6:d` | `NOwnedCases`: cases declared by the group. |
| `%7:d` | `NSubTests`: groups in the subtree (direct children at start). |
| `%8:d` | `NSkip`: skipped cases. |
| `%9:d` | `NSuccess`: successful cases. |
| `%10:d` | `NFailed`: failed cases. |
| `%11:d` | `NError`: errored cases. |
| `%12:d` | `TimeElapsed`: elapsed milliseconds. |
| `%13:s` | Result as text, from the `*Str` properties. |
| `%14:s` | `FailedAssert`: failed assertion or statement. |
| `%15:s` | `Message`: failure or error message. |
| `%16:s` | `BackTrace`: backtrace line. |
| `%17:s` | Current time, or an empty string when `ShowTime` is `False`. |

Defaults (the `ksDef*Fmt` constants):

| Property | Default |
| --- | --- |
| `BeforeStartFmt` | empty |
| `TestStartFmt` | `%0:s[%17:s] %2:s %13:s (Cases = %6:d Groups = %7:d)` |
| `CaseStartFmt` | `%0:s%1:s[%17:s] %2:s ` |
| `CaseEndFmt` | `%13:s [T=%12:d] (TA=%4:d)` |
| `CaseFailMsgFmt` | `%0:s%1:s%1:s%14:s%0:s%1:s%1:s%15:s` |
| `CaseBackTraceMsgFmt` | `%0:s%1:s%1:s%16:s` |
| `TestEndFmt` | `%0:s[T=%12:d] %2:s %13:s (TA=%4:d TC=%5:d / Sk=%8:d Sc=%9:d F=%10:d E=%11:d)` |
| `AfterEndFmt` | empty |

`AfterEndFmt` is stored but the totals block is written directly by
`OnAfterEnd`; the property is reserved for a future layout change.

## Result strings

| Property | Default |
| --- | --- |
| `StartStr` | `Start` |
| `SkipStr` | `⚠️ Skipped` |
| `SkipGroupStr` | `⛔ Skipped` |
| `SuccessStr` | `✅ Success` |
| `FailStr` | `❌ Failed` |
| `ErrorStr` | `☢️ ¡ERROR!` |

```pascal
Console := cCHXTWConsole(MainTest.AddWriter(cCHXTWConsole));
Console.FailStr := '[FAIL]';
Console.ErrorStr := '[ERROR]';
Console.SkipStr := '[SKIP]';
```

## Properties

| Property | Default | Meaning |
| --- | --- | --- |
| `IndentStr` | `  ┆ ` | Padding added for each nesting level. |
| `TextWidth` | `80` | Reserved for message wrapping; not used yet. |
| `ShowTime` | `True` | Print the current time on group and case lines. |
| `ShowInfo` | `False` | Print the persistent `Info` at case end. |
| `ShowProgress` | `False` | Render `SendProgress` with carriage returns. |

`ShowInfo` also affects the final summary: `WriteSummary` prints the `Info`
field of each collected failure or error regardless of `ShowInfo`. The flag
only controls the per-case information line.

## Case output

For every case the writer:

1. prints the case start line and stores it, so it can be redrawn,
2. erases any progress line at case end and redraws the start line when
   progress was shown,
3. prints the case end line, and the failure message and backtrace for cases
   that are neither skipped nor successful,
4. prints the persistent `Info` when `ShowInfo` is enabled.

Progress is printed with a leading carriage return and blanked with spaces
before the next line, so it never accumulates. See `Examples/ProgressTest.pas`.

## Summary

`WriteSummary` prints `Failures and errors:` followed by one block per entry of
`Failures`:

```text
  ┆ ❌ Failed Root.Child.CaseName
  ┆   ┆ Assertion: ...
  ┆   ┆ Message: ...
  ┆   ┆ Info: ...
  ┆   ┆ Backtrace: ...
```

Empty items are skipped. Nothing is printed when there are no failures.
`ShowSummary := False` disables the whole block, keeping the totals.

## Tips

- Compile with `-O- -gl` so backtraces contain file names and line numbers.
- A failing case is `❌ Failed`; a case that raised another exception is
  `☢️ ¡ERROR!`. A backtrace pointing to `RunCase` is expected for errors: the
  original line inside the case is not recoverable.
