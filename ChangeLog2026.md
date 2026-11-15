# ChangeLog 2026

## 2026-11-16 00:49

Make skip handling and result propagation reliable.

### Test runner (`ucCHXTestGroup.pas`, `utCHXTestResults.pas`)
- Finalize `RunAllCases` through `try..finally`, so start/end notifications
  stay paired and the root finishes normally even when it is disabled.
- Report disabled and empty groups as `rtSkip`; count them in the new
  `NSkippedGroups` field and add a disabled group's own cases to `NSkip`.
- Return the error exit code from `RunCase` when the requested case does not
  exist, instead of leaving the result undefined.
- Map every result through one helper: `0` success, `1` failure, `2` error and
  `3` for skip/not executed.

### Console writer (`ucCHXTWConsole.pas`)
- Show `Groups skipped` in the final totals.

### Examples
- Propagate `RunAllCases` to `ExitCode` in all examples.
- Make `BasicTest` return `0` when it produces its intentional result: one
  success, one failure and one error.
- Add `SelfTest.pas`, which checks counters, result types, skipped cases and
  groups, disabled subtrees and missing cases. It exits with `1` on mismatch.

### Documentation and repository
- Document the exit-code mapping and `SelfTest` in `README.md`.
- Ignore `AGENTS.md`, `RoadMap.md` and local `ToDo.md` in `.gitignore`.

### Verification
- Rebuild and run the six examples plus `SelfTest`; all exit with `0` and
  report `0 unfreed memory blocks`.
- Confirm `BasicTest` keeps 1 success, 1 failure and 1 error.
- Corrupt a temporary `SelfTest` expectation and confirm it exits with `1`.

## 2026-11-14 17:57

Remove the `TestUtils` dependency and make method discovery standalone.

### Test runner

- Replace `TestUtils.GetMethodList` with a local `GetPublishedMethodList`
  helper in `ucCHXTestGroup.pas`.
- Walk the VMT published method table directly and detect at runtime whether
  entries start at offset 4 or 8, covering both packed and aligned FPC
  layouts.
- Keep inherited test cases and let overridden published methods resolve to
  the most derived implementation.
- Remove the now unused `TypInfo` unit from the interface uses.

### Documentation and repository

- Update `README.md`: the FPC RTL is the only dependency, and remove the
  generic CHXPas and SDL3 references.
- Remove the obsolete `Readme.txt` and `Readme.org` files.

### Verification

- Rebuild and run all examples; `BasicTest` still reports 1 success,
  1 failure and 1 error, with no memory leaks.
- Verify with a temporary inheritance test that inherited and overridden
  published methods are discovered correctly.

## 2026-11-14 16:11

Initial standalone CHXTests import

### Repository

- Move all project files from `CHXTests/CHXTests/` to the repository root.
- Add `.gitignore` for build outputs, FPC artifacts and `LastChanges.md`.

### Build

- Update `Examples/fpcfg.cfg` to use local paths (`-Fu..`, `-Fi..`,
  `-FEbin`, `-FUlib`) instead of CHXPas and SDL3 include directories.
- Update `Examples/build.sh` and `Examples/Build.bat` to create local
  `bin` and `lib` directories and stop using `../../tmp/lib`.

### Examples

- Replace obsolete `TestTrue` calls with `MustTrue`.
- Fix the syntax error in `Examples/WriterInChild.pas`.

### Documentation

- Rename `Readme.md` to `README.md`.
- Document requirements, the `TestUtils` dependency and how to build the
  examples as a standalone project.

