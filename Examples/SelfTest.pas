program SelfTest;
{< Check the test runner itself with small known groups. }
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, utCHXTestResults;

type

  {$PUSH}
  {$M+}
  cTargetPass = class(cCHXTestGroup)
  published
    procedure CasePass;
  end;

  cTargetFail = class(cCHXTestGroup)
  published
    procedure CaseFail;
  end;

  cTargetError = class(cCHXTestGroup)
  published
    procedure CaseError;
  end;

  cTargetEmpty = class(cCHXTestGroup)
  end;

  cSelfTest = class(cCHXTestGroup)
  private
    procedure CheckCode(const aLabel : String; const aActual,
      aExpected : Integer);
    procedure CheckCount(const aLabel : String; const aActual,
      aExpected : Cardinal);
    procedure CheckResultType(const aLabel : String;
      const aActual, aExpected : tCHXTestResultType);
  published
    procedure CheckSuccess;
    procedure CheckFailure;
    procedure CheckError;
    procedure CheckEmptyGroup;
    procedure CheckDisabledGroup;
    procedure CheckSkippedCase;
    procedure CheckChildSkips;
    procedure CheckDisabledSubtree;
    procedure CheckRunCase;
  end;
  {$POP}

{
  Target groups
}

procedure cTargetPass.CasePass;
begin
  MustTrue(True);
end;

procedure cTargetFail.CaseFail;
begin
  MustTrue(False, 'Intentional failure.');
end;

procedure cTargetError.CaseError;
begin
  raise Exception.Create('Intentional error.');
end;

{
  cSelfTest
}

procedure cSelfTest.CheckCode(const aLabel : String; const aActual,
  aExpected : Integer);
begin
  MustTrue(aActual = aExpected, aLabel,
    Format('%s: got %d, expected %d',
    [aLabel, Int64(aActual), Int64(aExpected)]));
end;

procedure cSelfTest.CheckCount(const aLabel : String; const aActual,
  aExpected : Cardinal);
begin
  MustTrue(aActual = aExpected, aLabel,
    Format('%s: got %d, expected %d',
    [aLabel, Int64(aActual), Int64(aExpected)]));
end;

procedure cSelfTest.CheckResultType(const aLabel : String;
  const aActual, aExpected : tCHXTestResultType);
begin
  MustTrue(aActual = aExpected, aLabel,
    Format('%s: got %d, expected %d',
    [aLabel, Ord(aActual), Ord(aExpected)]));
end;

procedure cSelfTest.CheckSuccess;
var
  Target : cTargetPass;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetPass.Create;
  try
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('success: code', RunCode, 0);
  CheckResultType('success: type', Results.ResultType, rtSuccess);
  CheckCount('success: cases', Results.NCases, 1);
  CheckCount('success: success', Results.NSuccess, 1);
  CheckCount('success: failed', Results.NFailed, 0);
  CheckCount('success: error', Results.NError, 0);
  CheckCount('success: skip', Results.NSkip, 0);
  CheckCount('success: skipped groups', Results.NSkippedGroups, 0);
  CheckCount('success: groups', Results.NSubTests, 1);
  CheckCount('success: asserts', Results.NAsserts, 1);
end;

procedure cSelfTest.CheckFailure;
var
  Target : cTargetFail;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetFail.Create;
  try
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('failure: code', RunCode, 1);
  CheckResultType('failure: type', Results.ResultType, rtFailed);
  CheckCount('failure: cases', Results.NCases, 1);
  CheckCount('failure: success', Results.NSuccess, 0);
  CheckCount('failure: failed', Results.NFailed, 1);
  CheckCount('failure: error', Results.NError, 0);
  CheckCount('failure: skip', Results.NSkip, 0);
  CheckCount('failure: skipped groups', Results.NSkippedGroups, 0);
  CheckCount('failure: groups', Results.NSubTests, 1);
  CheckCount('failure: asserts', Results.NAsserts, 1);
end;

procedure cSelfTest.CheckError;
var
  Target : cTargetError;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetError.Create;
  try
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('error: code', RunCode, 2);
  CheckResultType('error: type', Results.ResultType, rtError);
  CheckCount('error: cases', Results.NCases, 1);
  CheckCount('error: success', Results.NSuccess, 0);
  CheckCount('error: failed', Results.NFailed, 0);
  CheckCount('error: error', Results.NError, 1);
  CheckCount('error: skip', Results.NSkip, 0);
  CheckCount('error: skipped groups', Results.NSkippedGroups, 0);
  CheckCount('error: groups', Results.NSubTests, 1);
  CheckCount('error: asserts', Results.NAsserts, 0);
end;

procedure cSelfTest.CheckEmptyGroup;
var
  Target : cTargetEmpty;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetEmpty.Create;
  try
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('empty: code', RunCode, 3);
  CheckResultType('empty: type', Results.ResultType, rtSkip);
  CheckCount('empty: cases', Results.NCases, 0);
  CheckCount('empty: success', Results.NSuccess, 0);
  CheckCount('empty: failed', Results.NFailed, 0);
  CheckCount('empty: error', Results.NError, 0);
  CheckCount('empty: skip', Results.NSkip, 0);
  CheckCount('empty: skipped groups', Results.NSkippedGroups, 1);
  CheckCount('empty: groups', Results.NSubTests, 1);
  CheckCount('empty: asserts', Results.NAsserts, 0);
end;

procedure cSelfTest.CheckDisabledGroup;
var
  Target : cTargetPass;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetPass.Create;
  try
    Target.Enabled := False;
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('disabled: code', RunCode, 3);
  CheckResultType('disabled: type', Results.ResultType, rtSkip);
  CheckCount('disabled: cases', Results.NCases, 1);
  CheckCount('disabled: success', Results.NSuccess, 0);
  CheckCount('disabled: failed', Results.NFailed, 0);
  CheckCount('disabled: error', Results.NError, 0);
  CheckCount('disabled: skip', Results.NSkip, 1);
  CheckCount('disabled: skipped groups', Results.NSkippedGroups, 1);
  CheckCount('disabled: groups', Results.NSubTests, 1);
  CheckCount('disabled: asserts', Results.NAsserts, 0);
end;

procedure cSelfTest.CheckSkippedCase;
var
  Target : cTargetPass;
  Results : tCHXTestResults;
  RunCode : Integer;
begin
  Target := cTargetPass.Create;
  try
    Target.SetCaseEnabled('CasePass', False);
    RunCode := Target.RunAllCases;
    Results := Target.TestResults;
  finally
    Target.Free;
  end;

  CheckCode('skipped case: code', RunCode, 3);
  CheckResultType('skipped case: type', Results.ResultType, rtSkip);
  CheckCount('skipped case: cases', Results.NCases, 1);
  CheckCount('skipped case: success', Results.NSuccess, 0);
  CheckCount('skipped case: failed', Results.NFailed, 0);
  CheckCount('skipped case: error', Results.NError, 0);
  CheckCount('skipped case: skip', Results.NSkip, 1);
  CheckCount('skipped case: skipped groups',
    Results.NSkippedGroups, 0);
  CheckCount('skipped case: groups', Results.NSubTests, 1);
  CheckCount('skipped case: asserts', Results.NAsserts, 0);
end;

procedure cSelfTest.CheckChildSkips;
var
  Parent : cTargetPass;
  DisabledChild, EmptyChild : cCHXTestGroup;
  ParentResults, DisabledResults, EmptyResults : tCHXTestResults;
  RunCode : Integer;
begin
  Parent := cTargetPass.Create;
  try
    DisabledChild := Parent.AddChildTest(cTargetPass);
    DisabledChild.Enabled := False;
    EmptyChild := Parent.AddChildTest(cTargetEmpty);

    RunCode := Parent.RunAllCases;
    ParentResults := Parent.TestResults;
    DisabledResults := DisabledChild.TestResults;
    EmptyResults := EmptyChild.TestResults;
  finally
    Parent.Free;
  end;

  CheckCode('child skips: code', RunCode, 0);
  CheckResultType('child skips: type', ParentResults.ResultType,
    rtSuccess);
  CheckCount('child skips: cases', ParentResults.NCases, 2);
  CheckCount('child skips: success', ParentResults.NSuccess, 1);
  CheckCount('child skips: failed', ParentResults.NFailed, 0);
  CheckCount('child skips: error', ParentResults.NError, 0);
  CheckCount('child skips: skip', ParentResults.NSkip, 1);
  CheckCount('child skips: skipped groups',
    ParentResults.NSkippedGroups, 2);
  CheckCount('child skips: groups', ParentResults.NSubTests, 3);
  CheckCount('child skips: asserts', ParentResults.NAsserts, 1);

  CheckResultType('disabled child: type',
    DisabledResults.ResultType, rtSkip);
  CheckCount('disabled child: cases', DisabledResults.NCases, 1);
  CheckCount('disabled child: skip', DisabledResults.NSkip, 1);
  CheckCount('disabled child: skipped groups',
    DisabledResults.NSkippedGroups, 1);

  CheckResultType('empty child: type', EmptyResults.ResultType,
    rtSkip);
  CheckCount('empty child: cases', EmptyResults.NCases, 0);
  CheckCount('empty child: skip', EmptyResults.NSkip, 0);
  CheckCount('empty child: skipped groups',
    EmptyResults.NSkippedGroups, 1);
end;

procedure cSelfTest.CheckDisabledSubtree;
var
  Parent : cTargetPass;
  DisabledChild, GrandChild : cCHXTestGroup;
  ParentResults, DisabledResults, GrandResults : tCHXTestResults;
  RunCode : Integer;
begin
  Parent := cTargetPass.Create;
  try
    DisabledChild := Parent.AddChildTest(cTargetPass);
    GrandChild := DisabledChild.AddChildTest(cTargetPass);
    DisabledChild.Enabled := False;

    RunCode := Parent.RunAllCases;
    ParentResults := Parent.TestResults;
    DisabledResults := DisabledChild.TestResults;
    GrandResults := GrandChild.TestResults;
  finally
    Parent.Free;
  end;

  CheckCode('disabled subtree: code', RunCode, 0);
  CheckResultType('disabled subtree: type',
    ParentResults.ResultType, rtSuccess);
  CheckCount('disabled subtree: cases', ParentResults.NCases, 2);
  CheckCount('disabled subtree: skip', ParentResults.NSkip, 1);
  CheckCount('disabled subtree: skipped groups',
    ParentResults.NSkippedGroups, 1);
  CheckCount('disabled subtree: disabled skip',
    DisabledResults.NSkip, 1);
  CheckCount('disabled subtree: disabled groups',
    DisabledResults.NSkippedGroups, 1);
  CheckResultType('disabled subtree: grandchild type',
    GrandResults.ResultType, rtNone);
  CheckCount('disabled subtree: grandchild skip',
    GrandResults.NSkip, 0);
  CheckCount('disabled subtree: grandchild groups',
    GrandResults.NSkippedGroups, 0);
end;

procedure cSelfTest.CheckRunCase;
var
  PassTarget : cTargetPass;
  FailTarget : cTargetFail;
begin
  PassTarget := cTargetPass.Create;
  try
    CheckCode('run case: existing',
      PassTarget.RunCase('casepass'), 0);
    CheckCode('run case: missing',
      PassTarget.RunCase('NoSuchCase'), 2);

    PassTarget.SetCaseEnabled('CasePass', False);
    CheckCode('run case: skipped',
      PassTarget.RunCase('CasePass'), 3);
  finally
    PassTarget.Free;
  end;

  FailTarget := cTargetFail.Create;
  try
    CheckCode('run case: failed',
      FailTarget.RunCase('CaseFail'), 1);
  finally
    FailTarget.Free;
  end;
end;

{
  Main program
}

var
  MainTest : cSelfTest;
  RunCode : Integer;

begin
  MainTest := cSelfTest.Create;
  MainTest.AddWriter(cCHXTWConsole);
  RunCode := MainTest.RunAllCases;
  MainTest.Free;

  // Any non-zero result means the runner did not behave as expected.
  if RunCode = 0 then
    ExitCode := 0
  else
    ExitCode := 1;
end.
