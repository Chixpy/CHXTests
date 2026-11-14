# ChangeLog 2026

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

