unit utCHXTestResults;
{< Unit of tCHXTestResults.

  Type returned by cases, tests and groups.

}
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH TypeHelpers}

interface

type

  // Order is important.
  tCHXTestResultType = (rtNone, rtStart, rtSkip, rtSuccess, rtFailed, rtError);

  tCHXTestResults = record
  private

  public
    TestName : String;
    TreeDepth : Cardinal;

    NAsserts : Cardinal;
    NCases : Cardinal;
    NOwnedCases : Cardinal;
    NSubTests : Cardinal;

    NSkip : Cardinal;
    NSuccess : Cardinal;
    NFailed : Cardinal;
    NError : Cardinal;

    TimeElapsed : UInt64;

    ResultType : tCHXTestResultType;
    FailedAssert : String;
    Message : String;
    BackTrace : String;

    procedure Init(const aName : String = '');
    procedure AddResult(const aResult : tCHXTestResults);
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

    NSkip := 0;
    NSuccess := 0;
    NFailed := 0;
    NError := 0;

    TimeElapsed := 0;

    ResultType := rtNone;
    FailedAssert := '';
    Message := '';
    BackTrace := '';
end;

initialization

finalization

end.
