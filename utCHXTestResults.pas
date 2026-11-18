unit utCHXTestResults;
{< Unit of tCHXTestResults.

  Result data returned by cases, test groups and complete runs. It holds the
  counters, timings and the failure information that writers render.

  It only uses plain `System` types, so a writer or a consumer can use it
  without linking the engine.

}
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH TypeHelpers}

interface

type

  tCHXTestResultType = (rtNone, rtStart, rtSkip, rtSuccess, rtFailed, rtError);
  {< Outcome of a case, a group or a whole run.

    The order is load-bearing: `tCHXTestResults.AddResult` aggregates by taking
    the highest enum value, so it must not be reordered. From lowest to highest
    the meaning is:

      - `rtNone`: no result yet.
      - `rtStart`: the test or case started and has not finished.
      - `rtSkip`: the case or group was disabled or empty.
      - `rtSuccess`: all assertions passed.
      - `rtFailed`: an assertion failed (`eCHXTestFailed`).
      - `rtError`: any other (unexpected) exception was raised.

    @seealso(tCHXTestResults.AddResult)
  }

  tCHXTestResults = record
  {< Result data of one case, one group or a complete run.

    A case fills its own record, and a group aggregates the results of its
    cases and children with `AddResult`, so the same type describes a leaf and
    a whole tree. Writers receive it in every `On*` callback.

    @seealso(cCHXTestWriter)
  }
  private

  public
    TestName : String;
    //< Name of the case or group.

    TreeDepth : Cardinal;
    //< Nesting level; `0` is the root group.

    NAsserts : Cardinal;
    //< Assertions evaluated in this case or subtree.

    NCases : Cardinal;
    //< Cases in this subtree, including skipped ones.

    NOwnedCases : Cardinal;
    //< Cases declared directly by this group, without its children.

    NSubTests : Cardinal;
    {< Test groups in this subtree.

      While a group runs it holds the number of its descendants. The root adds
      itself in `NotifyAfterEnd`, so after a run the value includes the root.
    }

    NSkippedGroups : Cardinal;
    //< Groups reported as skipped in this subtree.

    NSkip : Cardinal;
    //< Skipped cases in this subtree.

    NSuccess : Cardinal;
    //< Successful cases in this subtree.

    NFailed : Cardinal;
    //< Failed cases in this subtree.

    NError : Cardinal;
    //< Cases that raised an unexpected exception.

    TimeElapsed : UInt64;
    {< Elapsed time of the case or group in milliseconds.

      Cases measure their own execution. Aggregated results do not add the
      times of their children; consumers such as `cCHXTWConsole` show the
      elapsed time of the group as a whole.
    }

    ResultType : tCHXTestResultType;
    //< Highest result of the case or subtree.

    FailedAssert : String;
    //< Name of the failed assertion or of the failing statement.

    Message : String;
    //< Failure or error message, including soft failure details.

    BackTrace : String;
    //< Backtrace line of the failed assertion or of the exception.

    Info : String;
    //< Persistent information sent by the case, joined with `LineEnding`.

    procedure Init(const aName : String = '');
    {< Reset all fields to their initial values.

      The result type becomes `rtNone`, every counter becomes `0` and every
      string becomes empty.

      @param(aName Initial value for `TestName`.)
    }

    procedure AddResult(const aResult : tCHXTestResults);
    {< Aggregate another result into this one.

      Counters are added and the result type becomes the highest of both. The
      elapsed time is not added: a group measures its own total separately.

      @param(aResult Result of a case or child group.)
      @seealso(tCHXTestResultType)
    }
  end;


implementation

{
  tCHXTestResults
}
procedure tCHXTestResults.AddResult(const aResult : tCHXTestResults);
begin
  // rtNone < rtSkip < rtStart < rtSuccess < rtFailed < rtError
  if Self.ResultType < aResult.ResultType then
    Self.ResultType := aResult.ResultType;

  Inc(Self.NAsserts, aResult.NAsserts);
  Inc(Self.NSubTests, aResult.NSubTests);
  Inc(Self.NSkippedGroups, aResult.NSkippedGroups);
  Inc(Self.NCases, aResult.NCases);
  Inc(Self.NSkip, aResult.NSkip);
  Inc(Self.NSuccess, aResult.NSuccess);
  Inc(Self.NFailed, aResult.NFailed);
  Inc(Self.NError, aResult.NError);
  // Calculate individually or add it manually.
  // Inc(Self.TimeElapsed, aResult.TimeElapsed);
end;

procedure tCHXTestResults.Init(const aName : String = '');
begin
    TestName := aName;
    TreeDepth := 0;

    NAsserts := 0;
    NCases := 0;
    NOwnedCases := 0;
    NSubTests := 0;
    NSkippedGroups := 0;

    NSkip := 0;
    NSuccess := 0;
    NFailed := 0;
    NError := 0;

    TimeElapsed := 0;

    ResultType := rtNone;
    FailedAssert := '';
    Message := '';
    BackTrace := '';
    Info := '';
end;

initialization

finalization

end.
