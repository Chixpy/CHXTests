# ucCHXTWJSON

Writer that produces a deterministic JSON document from the run. It never
writes to the console and ignores `SendProgress`; `ShowSummary` has no effect.

```pascal
uses ucCHXTestGroup, ucCHXTWJSON;
```

## Usage

```pascal
var
  aWriter : cCHXTWJSON;

aWriter := cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON));
aWriter.FileName := 'results.json';
ExitCode := MainTest.RunAllCases;
```

- `AddWriter(Class)` creates the writer and the group frees it.
- `FileName` is optional. When it is empty the document is only kept in
  memory; when it is set, the document is saved when the observed root ends.
- `Lines` exposes the generated text, and `SaveError` holds an I/O error
  instead of raising it.

```pascal
if Writer.SaveError <> '' then
  WriteLn('Could not save the report: ', Writer.SaveError)
else
  WriteLn(Writer.Lines.Text);
```

The library units do not depend on `fcl-json`: the document is built by hand.
`Examples/JSONTest.pas` validates it with `fpjson`.

## When the document is generated

The tree is built in memory from the events. When the last group of the
observed root ends (`OnTestEnd`), the writer serializes the tree:

- A writer attached to the root produces the whole run.
- A writer attached to a child produces a document that starts at that child,
  because the child is the observed root for this writer and it never receives
  `OnAfterEnd`.

```pascal
SubTest := MainTest.AddChildTest(cTest1a);
cCHXTWJSON(SubTest.AddWriter(cCHXTWJSON)).FileName := 'child.json';
// The document starts at cTest1a, not at MainTest.
```

A bare `RunCase` call emits no group events, so it produces no document. Use
`RunAllCases`.

## Document

Real output of `Examples/Subsubtest.pas`:

```json
{
  "generator": "CHXTests",
  "schemaVersion": 1,
  "name": "cTest1",
  "path": "cTest1",
  "result": "success",
  "durationMs": 159,
  "counts": {
    "asserts": 3,
    "cases": 3,
    "groups": 3,
    "success": 3,
    "skipped": 0,
    "skippedGroups": 0,
    "failed": 0,
    "errors": 0
  },
  "cases": [
    {
      "name": "Test1_1",
      "path": "cTest1",
      "result": "success",
      "asserts": 1,
      "durationMs": 50,
      "failedAssert": "",
      "message": "",
      "backtrace": "",
      "info": ""
    }
  ],
  "groups": [
    {
      "name": "cTest1a",
      "path": "cTest1.cTest1a",
      "result": "success",
      "durationMs": 107,
      "counts": {
        "asserts": 2,
        "cases": 2,
        "groups": 2,
        "success": 2,
        "skipped": 0,
        "skippedGroups": 0,
        "failed": 0,
        "errors": 0
      },
      "cases": [
        {
          "name": "Test1a_1",
          "path": "cTest1.cTest1a",
          "result": "success",
          "asserts": 1,
          "durationMs": 25,
          "failedAssert": "",
          "message": "",
          "backtrace": "",
          "info": ""
        }
      ],
      "groups": [
        {
          "name": "cTest1a1",
          "path": "cTest1.cTest1a.cTest1a1",
          "result": "success",
          "durationMs": 81,
          "counts": {
            "asserts": 1,
            "cases": 1,
            "groups": 1,
            "success": 1,
            "skipped": 0,
            "skippedGroups": 0,
            "failed": 0,
            "errors": 0
          },
          "cases": [
            {
              "name": "Test1a1_1",
              "path": "cTest1.cTest1a.cTest1a1",
              "result": "success",
              "asserts": 1,
              "durationMs": 80,
              "failedAssert": "",
              "message": "",
              "backtrace": "",
              "info": ""
            }
          ],
          "groups": [
          ]
        }
      ]
    }
  ]
}
```

## Fields

### Root

| Field | Type | Meaning |
| --- | --- | --- |
| `generator` | string | Always `"CHXTests"`. |
| `schemaVersion` | integer | Currently `1`. |
| `name` | string | Name of the observed root group. |
| `path` | string | Path of the observed root; equal to `name` at root level. |
| `result` | string | Aggregated result: `none`, `start`, `skip`, `success`, `failed` or `error`. |
| `durationMs` | integer | Elapsed time of the group in milliseconds. |
| `counts` | object | Counters of the subtree (see below). |
| `cases` | array | Cases declared directly by the group. |
| `groups` | array | Child groups, nested with the same shape. |

### `counts`

| Field | Meaning | Source |
| --- | --- | --- |
| `asserts` | Assertions evaluated in the subtree. | `NAsserts` |
| `cases` | Cases in the subtree, including skipped ones. | `NCases` |
| `groups` | Groups in the subtree, **including the group itself**. | Computed |
| `success` | Successful cases. | `NSuccess` |
| `skipped` | Skipped cases. | `NSkip` |
| `skippedGroups` | Skipped groups. | `NSkippedGroups` |
| `failed` | Failed cases. | `NFailed` |
| `errors` | Cases that raised an unexpected exception. | `NError` |

`counts.groups` is computed by walking the tree, so unlike `NSubTests` it
always includes the group itself.

### Case

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Case name. |
| `path` | string | Path of the containing group. |
| `result` | string | `success`, `skip`, `failed`, `error`, `start` or `none`. |
| `asserts` | integer | Assertions evaluated by the case. |
| `durationMs` | integer | Elapsed time in milliseconds. |
| `failedAssert` | string | Name of the failed assertion or statement. |
| `message` | string | Failure or error message (may contain newlines escaped as `\n`). |
| `backtrace` | string | Backtrace line, possibly empty. |
| `info` | string | Persistent information from `SendInfo`, lines joined with `\n`. |

## Guarantees

- **Deterministic**: there is no timestamp. The only variable data are the
  names, the messages and the durations in milliseconds.
- **Escaped**: `"`, `\`, backspace, tab, newline, form feed and carriage return
  are escaped. Other control characters are written as `\u00XX`.
- **No progress**: `OnCaseProgress` is not implemented, so `SendProgress`
  leaves no trace.
- **No summary**: `ShowSummary` and `WriteSummary` are not used.
- **Flat text**: the document is stored line by line in `Lines` and written to
  `FileName` with `TFileStream`. `IndentStr` (default two spaces) controls the
  indentation of the text.

## Detecting problems

| Symptom | Cause |
| --- | --- |
| Empty `Lines` | The run did not emit group events (a bare `RunCase`), or the observed group never started. |
| `SaveError` not empty | The file could not be created or written. |
| Document starts at a child | The writer was added to a child group, not to the root. |

## Validating the output

```pascal
uses fpjson, jsonparser;

Data := GetJSON(Writer.Lines.Text);
try
  WriteLn('root result: ', Data.FindPath('result').AsString);
finally
  Data.Free;
end;
```

See `Examples/JSONTest.pas` for a complete validation of the schema, of the
counts, of the nested groups and of the escaped text.
