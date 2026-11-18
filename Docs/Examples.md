# Example programs

Standalone programs in `Examples/` that exercise the library. They are the
"tests" of the project: there is no test framework or CI, so a change is
verified by rebuilding and running all of them.

## Build and run

```sh
cd Examples
./build.sh BasicTest.pas        # or: fpc @fpcfg.cfg BasicTest.pas
./bin/BasicTest
```

- `build.sh` (bash) and `Build.bat` (Windows) only create `bin/` and `lib/` and
  call FPC. The relevant flags live in `fpcfg.cfg`: `-O-` (no optimizations),
  `-gl` (line info), `-gh` (heaptrc) and `-Ciort` (checks).
- `-Fu..` and `-Fi..` let the programs find the root units and the include.
- Every run with `-gh` prints a heaptrc dump at the end; `0 unfreed memory
  blocks` is the expected result.
- The `Illegal compiler switch "FUNCTIONREFERENCES+"` warning under FPC 3.3.1
  is expected and harmless.

Except `ProgressTest`, `JSONTest` and `SelfTest`, the programs accept an
optional first argument: a path for a JSON report. When present, the program
adds a JSON writer besides the console writer:

```sh
./bin/BasicTest results.json
```

## List

### `SimplestTest`

Smallest useful program: one group, one case, one console writer, optional JSON
report. Shows the default name (`ClassName`) and the automatic freeing of
writers created by class.

Expected: `1` case, `1` assertion, success. Exit code `0`.

### `BasicTest`

Four cases in one group: a success, a disabled case, a failure with custom
text, and an error caused by an intentional out-of-bounds access inside the
loop (with `SendProgress` calls before it).

Expected:

```text
✅ Success: 1 / ⛔ Skipped (G): 0 / ⚠️ Skipped (C): 1 / ❌ Failed: 1 / ☢️ ¡ERROR!: 1
```

`RunAllCases` returns `2`, but the program checks the counts and maps the
intentional result to exit code `0`. It returns `1` when the results change.

The error is reported with a backtrace pointing to `RunCase`, not to the line
inside the case: that information is not recoverable after the exception
unwinds.

### `ExceptionTest`

`MustRaise` with three outcomes: the expected exception, no exception and a
different exception.

Expected: `1` success, `2` failures, run code `1`. The program maps it to exit
code `0`; it returns `1` when the counts change.

### `SoftTest`

Soft assertions and their interaction with hard ones:

- several `May*` failures followed by more code and a successful `Must*`,
- a `May*` failure followed by a failing `Must*` (the hard failure aborts),
- a `May*` failure followed by a successful `Must*`,
- a clean case.

Expected: `1` success, `3` failures, `8` assertions. The program also checks
that the code after the soft failures ran and that the code after the hard
failure did not.

### `ProgressTest`

`SendInfo` and `SendProgress` with `ShowInfo` and `ShowProgress` enabled. The
optional first argument is the number of loop iterations (default `10`; values
below `1` fall back to `10`). The program checks the persistent `Info` text and
the counters; it exits with `0` on success and `1` otherwise.

### `SelfTest`

Checks the runner itself: result counts, skips, exceptions, soft failures,
failure collection, summary hooks, `RunCase` and the JSON writer. No JSON
argument.

Current state: `15` cases, `218` assertions, all successful. Exits with `0`
when every expectation matches and `1` otherwise.

### `JSONTest`

Builds a tree with nested groups, a failure with quotes and newlines, an
intentional error, a disabled group and a disabled case. It writes
`Examples/bin/JSONTest.json`, reloads it and validates it with `fpjson`.

Expected run code `2` and these root counters:

| Counter | Value |
| --- | --- |
| `asserts` | 4 |
| `cases` | 7 |
| `groups` | 8 |
| `success` | 3 |
| `skipped` | 2 |
| `skippedGroups` | 1 |
| `failed` | 1 |
| `errors` | 1 |

Exits with `0` when the document matches. The library units do not need
`fcl-json`; only this program does.

### `SubTests`

One root group with two child groups added by class type. Shows nesting, the
console indentation and the totals line. Expected: `3` cases, `3` assertions,
`3` groups, success.

### `Subsubtest`

Three levels of groups, built adding a child to a child. Same expected results
as `SubTests`, with one more level of indentation.

### `WriterAfterChild`

Adds a writer **after** the first child, then adds a second child. Shows that
children added later also receive the writer. Only direct children are
propagated by `AddWriter(Class)`; see [ucCHXTestGroup](ucCHXTestGroup.md#writers).

### `WriterInChild`

Attaches the console and JSON writers to a child instead of the root. The
console output starts at the child, and the JSON document is rooted at that
child (see [ucCHXTWJSON](ucCHXTWJSON.md#when-the-document-is-generated)).

## Expected exit codes

| Program | Run code | Program exit code |
| --- | --- | --- |
| `SimplestTest` | `0` | `0` |
| `BasicTest` | `2` | `0` (checks the intentional result) |
| `ExceptionTest` | `1` | `0` (checks the intentional result) |
| `SoftTest` | `1` | `0` (checks the intentional result) |
| `ProgressTest` | `0` | `0` |
| `SelfTest` | `0` | `0` |
| `JSONTest` | `2` | `0` (checks the intentional result) |
| `SubTests`, `Subsubtest` | `0` | `0` |
| `WriterAfterChild`, `WriterInChild` | `0` | `0` |

The self-checking programs return `1` when the expected results do not match,
so their output has to be read as well; a non-zero run code by itself is not a
failure in `BasicTest`, `ExceptionTest`, `SoftTest` or `JSONTest`.
