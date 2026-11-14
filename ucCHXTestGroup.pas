unit ucCHXTestGroup;
{< Unit of cCHXTestGroup.

  (c) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH TypeHelpers}

interface

uses
  Classes, SysUtils, Generics.Collections,
  utCHXTestResults, ucCHXTestWriter;

resourcestring
  rsUnexpectedException = 'Unexpected Exception: %s';
  rsNotTrue = 'Condition is not True';
  rsNotFalse = 'Condition is not False';
  rsEqualFmt = '"%s" = "%s"';
  rsNotEqualFmt = '"%s" <> "%s"';
  rsGreaterFmt = '"%s" > "%s"';
  rsLessFmt = '"%s" < "%s"';
  rsGrtEquFmt = '"%s" => "%s"';
  rsLssEquFmt = '"%s" =< "%s"';

type
  tTestMethod = procedure of object;

{
  tTestCase
}

  tTestCase = record
  {< Individual test case info. }
    CaseName : String;
    Enabled : Boolean;
    Method : tTestMethod;
    TestResults : tCHXTestResults;
  end;
  pTestCase = ^tTestCase;

  cTestCaseGenList = specialize tList<tTestCase>;
  cTestCaseList = class(cTestCaseGenList);

{
  eCHXTestFailed
}

  eCHXTestFailed = class(Exception);
  //< Exception returned by Assertions/Check/Tests.

{
  cCHXTestGroup
}
  // Forward declarations, so we don't need another unit.
  cCHXTestGroup = class;
  cCHXTestGroupList = class;
  tCHXTestGroupClass = class of cCHXTestGroup;

  {$PUSH}
  {$TYPEINFO ON} // or {.$M+}
  cCHXTestGroup = class(TPersistent)
  private
    FTestName : String;
    FTreeDepth : Cardinal;

    FailedAssert : String;

    procedure SetTestName(const aTestName : String);
    procedure SetTreeDepth(const aTreeDepth : Cardinal);
    procedure CopyFrom(const aTest : cCHXTestGroup);
    {< Copy test group properties from `aTest`.

      Removes ownership of writers and childs of `aTest` (by setting
      `OwnsObject` to false, not removing them) and transfers them to `Self`.

      Used to exchange a `cCHXEmptyTestGroup` with an actual implemented test
      group with the same name.
    }

    procedure NotifyBeforeStart;
    procedure NotifyAfterEnd;
    procedure NotifyTestStart;
    procedure NotifyTestEnd;
    procedure NotifyCaseStart(const aCaseResult : tCHXTestResults);
    procedure NotifyCaseEnd(const aCaseResult : tCHXTestResults);

  protected
    OwnedChilds : cCHXTestGroupList;
    //< Subtests owned (Added by class type)
    OwnedWriters : cCHXTestWriterList;
    //< Writers owned (Added by class type)

    NCaseAsserts : Cardinal;
    //< Number of asserts checked in current case.

    procedure TestResultInit;

    procedure AddCaseSkip(const aCase : pTestCase);
    procedure AddCaseSuccess(const aCase : pTestCase);
    procedure AddCaseFail(const aCase : pTestCase; const Msg: String);
    procedure AddCaseError(const aCase : pTestCase; const Msg: String);

    function CallerAddr(const ParentDepth : SizeInt = 1) : Pointer;
    {< Get the memory address of a parent caller function.

      We can define wich of parents we want to get its address. `0` is the
      caller of `CallerAddr`, `1` is the previous one and so on.

      @param(ParentDepth Parent we want to get its address.)
    }

    procedure DoBeforeStart; virtual;
    procedure DoAfterEnd; virtual;
    procedure DoTestStart; virtual;
    procedure DoTestEnd; virtual;
    procedure DoCaseStart(const aCaseResult : tCHXTestResults); virtual;
    procedure DoCaseEnd(const aCaseResult : tCHXTestResults); virtual;
    {< Methods called at some events. }

    procedure MustFail(const Sender : String; const Msg : String;
      ErrAdrs: Pointer);
    {<< Send a Failed Test signal and *exit* current test case method.

      Not intended for a direct call from a test case unless for testing
      purpouses. Surely, there will be a condition before the call to this
      method wich can be asserted by other methods (or create a custom one).

      @param(Sender Sender's name of the fail or failed statement.)
      @param(Msg More detailed fail message.)
      @param(ErrAdrs Address of the failed method. Usually `nil` unless called
        from an assertion method.)
    }

  {
    Assertions / Checks / Tests...

    These methods increments the number of assertions made and call `MustFail`
    (only if failed, obviuosly) with more descriptive information (wich can be
    customized too). `ErrAdrs` may be @nil, unless called by another assertion
    methods.
  }

  {
    Boolean and general conditions.
  }
    procedure MustTrue(const Condition : Boolean;
      Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
    procedure MustFalse(const Condition : Boolean;
      Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);

  {
    Integers, floats, `Char`, `String`, pointers and instanced classes.

    The generic declaration of the methods is:

    ```
    Procedure <Method>(const Correct, Value : <Type>;
      Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
    ```

    All types have `MustEqual` (`=`) and `MustNotEqual` (`<>`) methods.

    Except `Pointer` and `TObject`, all others have:
      - `MustGreater` (`>`) and `MustLess` (`<`).
      - `MustGrtEqu` (`>=`) and `MustLssEqu` (`<=`).

    To be clear: `Value` is the left value and `Correct` is the right one.
    "/Value/ must be greater/less than (or equal to) /Correct/".

    @param(Sender Sender's name of the fail or failed statement.

      If empty, defaults to ` Must[x]` method Name. It's better to write the
      previous statement that failed, if not very long.)

    @param(Msg More detailed fail message. Every method defaults to it's own
      comparison message.

      If not empty, `Msg` will be parsed with
      `Format(Msg, [String(Correct), String(Value)])`. In other words,
      `%0:s` will be `Value` value and `%1:s` as `Correct`.)

    @param(ErrAdrs Address of the failed method. `nil` sets it to the
      caller address. Use `nil` unless called from another assertion method.)
  }
    {$MACRO ON}

    {$PUSH}
    {$DEFINE TestMethodsDecl}   // Add declarations
    {$UNDEF TestMethodsImpl}    // Don't add implementations

    {$DEFINE TestEquMethods}     // Add `=` and `<>`
    {$UNDEF TestSameValueMethods}   // Don't add `SameValue`
    {$DEFINE TestGrtLssMethods}  // Add `<`, `>`, `<=` and `>=`

    {$DEFINE CustomType := Int64}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := QWord}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := Char}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := String}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := Currency}
    {$I 'ucCHXTestGroup.inc'}

    {$UNDEF TestEquMethods}        // Don't add `=` and `<>` (Can cause confusion)
    {$DEFINE TestSameValueMethods} // Add `SameValue`
    {$DEFINE TestGrtLssMethods}    // Add `<`, `>`, `<=` and `>=`

    {$DEFINE CustomType := Single}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := Double}
    {$I 'ucCHXTestGroup.inc'}
    {.$DEFINE CustomType := Extended}
    {.$I 'ucCHXTestGroup.inc'}

    {$DEFINE TestEquMethods}      // Don't add `=` and `<>` (Can cause confusion)
    {$UNDEF TestSameValueMethods} // Add `SameValue`
    {$UNDEF TestGrtLssMethods}    // Add `<`, `>`, `<=` and `>=`

    {$DEFINE CustomType := Pointer}
    {$I 'ucCHXTestGroup.inc'}
    {$DEFINE CustomType := TObject}
    {$I 'ucCHXTestGroup.inc'}

    {$POP}

  public
    TestCases : cTestCaseList;
    //< List of cases in this test.
    TestChilds : cCHXTestGroupList;
    // Subtests list.
    TestWriters : cCHXTestWriterList;
    //< Writers for tests results

    TestResults : tCHXTestResults;

    Enabled : Boolean; // If disabled, skip test group.

    property TestName : String read FTestName write SetTestName;
    property TreeDepth : Cardinal read FTreeDepth;

    constructor Create(aTestName : String = '');
    destructor Destroy; override;

    procedure AddRegistered;

    function AddChildTest(const aTestClass : tCHXTestGroupClass;
      const aTestName : String = ''): cCHXTestGroup; overload;
    {< Add a Subtest by class type.

      Creates an instance `aTestClass` and returns it. Tests added this way
      ***will be freed on Destroy***.

      @param(aTestClass Class type inherited from `cCHXTestGroup`.)
      @param(aTestName Custom name for the test group. Defaults to `ClassName`.)
      @returns(Instance of `aTestClass` created (as a `cCHXTestGroup`).)
    }
    procedure AddChildTest(const aTest : cCHXTestGroup;
      aTestName : String = ''); overload;
    {< Add an alredy created instance of a test group as a subtest.

      Tests added this way ***will NOT be freed on Destroy***.

      @param(aTest Instance of a class inherited from `cCHXTestGroup`.)
      @param(aTestName Custom name for the test group. Defaults to `ClassName`.)
    }

    function AddWriter(const WriterClass : tCHXTestWriterClass): cCHXTestWriter;
      overload;
    {< Add a test results writer (or listener or observer) by class type.

      Creates an instance `WriterClass` of and returns it. Writters added this
      way ***will be freed on Destroy***.

      @param(WriterClass Class type inherited from `tCHXTestWriterClassssName`.)
      @returns(Instance of `WriterClass` created (as a `cCHXTestWriter`).)
    }
    procedure AddWriter(const Writer : cCHXTestWriter); overload;
    {< Add an instance of a test results writer (or listener or observer).

      Writters added this way ***will NOT be freed on Destroy***.

      @param(WriterClass Class type inherited from `tCHXTestWriterClassssName`.)
      @returns(Instance of `WriterClass` created (as a `cCHXTestWriter`).)
    }
    procedure AddWriters(const WriterList : cCHXTestWriterList);

    function GetCasePos(const aCaseName: String): Integer;
    procedure SetCaseEnabled(const aCaseName: string; const aEnabled: Boolean);

    function RunCase(const CaseName : String) : Integer;
    function RunCase(TestCase : pTestCase) : Integer;
    function RunAllCases : Integer; virtual;
  end;
  {$POP}

  cCHXTestGroupGenList = specialize TObjectList<cCHXTestGroup>;
  cCHXTestGroupList = class(cCHXTestGroupGenList);

  cCHXEmptyTestGroup = class(cCHXTestGroup);
  {< Empty group class for filling the tree structure. If a proper test with
    the same name in the same place is added latter, it will we substituted.
  }

{
  Procedure for registering Test Groups wich will added to a test group with
    `AddRegistered` method. Usually these are called in `initialization`
    section of the unit where are implemented.

  They will be created with default properties.
}
  tCHXRegTest = record
    TestName : String;
    TestClass : tCHXTestGroupClass;
  end;

procedure RegisterCHXTestGroup(const aTGClass : tCHXTestGroupClass;
  aName : String = '');

var
  CHXRegTests : Array of tCHXRegTest;

implementation

uses
  Math;

{
  VMT published method table

  The compiler stores the published method table referenced by the VMT.
  Its count is a DWord at offset 0, but the entries can start after the
  count or after padding, depending on the target ABI. TypInfo's
  TVmtMethodTable relies on FPC_REQUIRES_PROPER_ALIGNMENT for this, which
  does not match every FPC build, so detect the real offset at runtime
  with a tiny probe class.
}
type
  {$M+}
  TVmtMethodProbe = class
  published
    procedure VmtMethodProbe;
  end;
  {$M-}

procedure TVmtMethodProbe.VmtMethodProbe;
begin
end;

var
  VmtMethodEntryOffset : PtrUInt = 0;

function GetVmtMethodEntryOffset : PtrUInt;
var
  MethodTable : PByte;
  Count : DWord;
  ProbeAddress : CodePointer;
  Candidate : CodePointer;
  EntrySize : PtrUInt;
  Offset : PtrUInt;
  i : DWord;
begin
  if VmtMethodEntryOffset <> 0 then
    Exit(VmtMethodEntryOffset);

  // Fallback for the usual packed layout.
  VmtMethodEntryOffset := SizeOf(DWord);

  MethodTable := PByte(PVmt(TVmtMethodProbe)^.vMethodTable);
  if not Assigned(MethodTable) then
    Exit(VmtMethodEntryOffset);

  Count := PDWord(MethodTable)^;
  ProbeAddress := TVmtMethodProbe.MethodAddress('VmtMethodProbe');
  EntrySize := 2 * SizeOf(Pointer);

  if Count > 0 then
    for i := 0 to Count - 1 do
    begin
      Offset := SizeOf(DWord);
      Move(PByte(MethodTable + Offset + i * EntrySize + SizeOf(Pointer))^,
        Candidate, SizeOf(Candidate));
      if Candidate = ProbeAddress then
      begin
        VmtMethodEntryOffset := Offset;
        Break;
      end;

      Offset := 2 * SizeOf(DWord);
      Move(PByte(MethodTable + Offset + i * EntrySize + SizeOf(Pointer))^,
        Candidate, SizeOf(Candidate));
      if Candidate = ProbeAddress then
      begin
        VmtMethodEntryOffset := Offset;
        Break;
      end;
    end;

  Result := VmtMethodEntryOffset;
end;

{
  GetPublishedMethodList

  Enumerate the published methods of a class by walking its VMT method
  table. This is based on FPC's TestUtils.GetMethodList, kept local to
  avoid the fcl-fpcunit dependency.
}
procedure GetPublishedMethodList(aClass : TClass; aList : TStrings);
var
  Vmt : PVmt;
  MethodTable : PByte;
  MethodEntry : PByte;
  MethodNamePtr : PShortString;
  MethodName : ShortString;
  Count : DWord;
  EntryOffset : PtrUInt;
  EntrySize : PtrUInt;
  i : DWord;
  idx : Integer;
begin
  if not Assigned(aList) then Exit;

  aList.Clear;
  EntryOffset := GetVmtMethodEntryOffset;
  EntrySize := 2 * SizeOf(Pointer);
  Vmt := PVmt(aClass);

  while Assigned(Vmt) do
  begin
    MethodTable := PByte(Vmt^.vMethodTable);

    if Assigned(MethodTable) then
    begin
      Count := PDWord(MethodTable)^;
      MethodEntry := MethodTable + EntryOffset;

      if Count > 0 then
        for i := 0 to Count - 1 do
        begin
          Move(MethodEntry^, MethodNamePtr, SizeOf(MethodNamePtr));

          if Assigned(MethodNamePtr) then
          begin
            MethodName := MethodNamePtr^;

            // An overridden method replaces the inherited one.
            idx := aList.IndexOf(MethodName);
            if idx >= 0 then
              aList.Delete(idx);

            aList.Add(MethodName);
          end;

          Inc(MethodEntry, EntrySize);
        end;
    end;

    Vmt := Vmt^.vParent;
  end;
end;

{
  cCHXTestGroup
}

procedure cCHXTestGroup.SetTestName(const aTestName : String);
begin
  FTestName := aTestName;
  TestResults.TestName := aTestName;
end;

procedure cCHXTestGroup.CopyFrom(const aTest : cCHXTestGroup);
begin
  // Raw copy to not trigger updating childs with duplicate data
  // Hack: Using private methods of another instance.
  Self.FTestName := aTest.FTestName;
  Self.FTreeDepth := aTest.FTreeDepth;
  Self.OwnedChilds.AddRange(aTest.OwnedChilds);
  Self.OwnedWriters.AddRange(aTest.OwnedWriters);
  Self.TestCases.AddRange(aTest.TestCases);
  Self.TestChilds.AddRange(aTest.TestChilds);
  Self.TestWriters.AddRange(aTest.TestWriters);
  Self.Enabled := aTest.Enabled;

  // Removing aTest ownership
  aTest.OwnedChilds.OwnsObjects := False;
  aTest.OwnedWriters.OwnsObjects := False;
end;

procedure cCHXTestGroup.SetTreeDepth(const aTreeDepth : Cardinal);
begin
  FTreeDepth := aTreeDepth;
  TestResults.TreeDepth := aTreeDepth;
end;

procedure cCHXTestGroup.NotifyBeforeStart;
var
  aWriter: cCHXTestWriter;
begin
  for aWriter in TestWriters do
    aWriter.OnBeforeStart;
end;

procedure cCHXTestGroup.NotifyAfterEnd;
var
  aWriter: cCHXTestWriter;
begin
  Inc(TestResults.NSubTests); // Adding main test.
  for aWriter in TestWriters do
    aWriter.OnAfterEnd(TestResults);
end;

procedure cCHXTestGroup.NotifyTestStart;
var
  aWriter: cCHXTestWriter;
begin
  for aWriter in TestWriters do
    aWriter.OnTestStart(TestResults);
end;

procedure cCHXTestGroup.NotifyTestEnd;
var
  aWriter: cCHXTestWriter;
begin
  for aWriter in TestWriters do
    aWriter.OnTestEnd(TestResults);
end;

procedure cCHXTestGroup.NotifyCaseStart(const aCaseResult : tCHXTestResults);
var
  aWriter: cCHXTestWriter;
begin
  for aWriter in TestWriters do
    aWriter.OnCaseStart(aCaseResult);
end;

procedure cCHXTestGroup.NotifyCaseEnd(const aCaseResult : tCHXTestResults);
var
  aWriter: cCHXTestWriter;
begin
  for aWriter in TestWriters do
    aWriter.OnCaseEnd(aCaseResult);
end;

procedure cCHXTestGroup.TestResultInit;
begin
  TestResults.Init(Self.TestName);
  TestResults.TreeDepth := Self.TreeDepth;
  TestResults.NOwnedCases := TestCases.Count;
  TestResults.NCases := TestCases.Count;
  TestResults.NSubTests := TestChilds.Count;
end;

procedure cCHXTestGroup.AddCaseSkip(const aCase : pTestCase);
begin
  aCase^.TestResults.ResultType := rtSkip;
  aCase^.TestResults.NSkip := 1;
end;

procedure cCHXTestGroup.AddCaseSuccess(const aCase : pTestCase);
begin
  aCase^.TestResults.ResultType := rtSuccess;
  aCase^.TestResults.NSuccess := 1;
end;

procedure cCHXTestGroup.AddCaseFail(const aCase : pTestCase; const Msg: String);
begin
  aCase^.TestResults.ResultType := rtFailed;
  aCase^.TestResults.FailedAssert := FailedAssert;
  aCase^.TestResults.Message := Msg;
  aCase^.TestResults.NFailed := 1;
end;

procedure cCHXTestGroup.AddCaseError(const aCase : pTestCase; const Msg: String);
begin
  aCase^.TestResults.ResultType := rtError;
  aCase^.TestResults.FailedAssert := FailedAssert;
  aCase^.TestResults.Message := Msg;
  aCase^.TestResults.NError := 1;
end;

function cCHXTestGroup.CallerAddr(const ParentDepth : SizeInt) : Pointer;
var
  Address : CodePointer;
begin
  if CaptureBacktrace(ParentDepth, 1, @Address) = 1 then
    Result := Address
  else
    Result := nil;
end;

procedure cCHXTestGroup.DoBeforeStart;
begin
  // To be overrided
end;

procedure cCHXTestGroup.DoAfterEnd;
begin
  // To be overrided
end;

procedure cCHXTestGroup.DoTestStart;
begin
  // To be overrided
end;

procedure cCHXTestGroup.DoTestEnd;
begin
  // To be overrided
end;

procedure cCHXTestGroup.DoCaseStart(const aCaseResult : tCHXTestResults);
begin
  // To be overrided
end;

procedure cCHXTestGroup.DoCaseEnd(const aCaseResult : tCHXTestResults);
begin
  // To be overrided
end;

procedure cCHXTestGroup.MustFail(const Sender : String; const Msg : String;
  ErrAdrs: Pointer);
begin
  if Sender <> '' then
    FailedAssert := Sender
  else
    FailedAssert := {$I %CURRENTROUTINE%};

  if not Assigned(ErrAdrs) then
    ErrAdrs := CallerAddr;

  raise eCHXTestFailed.Create(Msg) at ErrAdrs;
end;

procedure cCHXTestGroup.MustTrue(const Condition : Boolean;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Condition then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsNotTrue;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Msg, ErrAdrs);
end;

procedure cCHXTestGroup.MustFalse(const Condition : Boolean;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if not Condition then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsNotFalse;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Msg, ErrAdrs);
end;

{$MACRO ON}

{$PUSH}
{$UNDEF TestMethodsDecl}   // Don't add declarations
{$DEFINE TestMethodsImpl}   // Add implementations
{$DEFINE TestGroupClass := cCHXTestGroup}

// Use same defines as in declaration type
{$DEFINE TestEquMethods}      // `=` and `<>`
{$UNDEF TestSameValueMethods} // `TypeSameValue`
{.DEFINE TypeSameValue := <SameValueFunc>}
{$DEFINE TestGrtLssMethods}   // `<`, `>`, `<=` and `>=`

{$DEFINE FToString := IntToStr}
{$DEFINE CustomType := Int64}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE FToString := UIntToStr}
{$DEFINE CustomType := QWord}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE FToString := String}
{$DEFINE CustomType := Char}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE FToString := String}
{$DEFINE CustomType := String}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE FToString := FloatToStr}
{$DEFINE CustomType := Currency}
{$I 'ucCHXTestGroup.inc'}

{$UNDEF TestEquMethods}          // `=` and `<>`
{$DEFINE TestSameValueMethods}   // `TypeSameValue`
{$DEFINE TypeSameValue := Math.SameValue}
{$DEFINE TestGrtLssMethods}      // `<`, `>`, `<=` and `>=`

{$DEFINE CustomType := Single}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE CustomType := Double}
{$I 'ucCHXTestGroup.inc'}
{.$DEFINE CustomType := Extended}
{.$I 'ucCHXTestGroup.inc'}

{$DEFINE TestEquMethods}     // `=` and `<>`
{$UNDEF TestSameValueMethods}   // `TypeSameValue`
{.$DEFINE TypeSameValue := <SameValueFunc>}
{$UNDEF TestGrtLssMethods}  // `<`, `>`, `<=` and `>=`

{$DEFINE FToString := HexStr}
{$DEFINE CustomType := Pointer}
{$I 'ucCHXTestGroup.inc'}
{$DEFINE CustomType := TObject}
{$I 'ucCHXTestGroup.inc'}

{$POP}

constructor cCHXTestGroup.Create(aTestName : String);
var
  MethodList : tStringList;
  aMethodName : String;
  NewTestCase : tTestCase;
  TempMethod : tTestMethod;
begin
  inherited Create;

  if (aTestName = '') then
    aTestName := Self.ClassName;

  TestName := aTestName;
  FTreeDepth := 0;
  Enabled := True;

  TestChilds := cCHXTestGroupList.Create(False);
  OwnedChilds := cCHXTestGroupList.Create(True);
  TestWriters := cCHXTestWriterList.Create(False);
  OwnedWriters := cCHXTestWriterList.Create(True);
  TestCases := cTestCaseList.Create;

  TestResultInit;

  MethodList := tStringList.Create;
  try
    GetPublishedMethodList(Self.ClassType, MethodList);

    for aMethodName in MethodList do
    begin
      NewTestCase.CaseName := aMethodName;
      TMethod(TempMethod).Code := Self.MethodAddress(aMethodName);
      TMethod(TempMethod).Data := Self;
      NewTestCase.Method := TempMethod;
      NewTestCase.Enabled := True;
      NewTestCase.TestResults.Init(aMethodName);

      TestCases.Add(NewTestCase);
    end;
  finally
    FreeAndNil(MethodList);
  end;
end;

destructor cCHXTestGroup.Destroy;
begin
  TestCases.Free;
  TestWriters.Free;
  OwnedWriters.Free;
  TestChilds.Free;
  OwnedChilds.Free;
  inherited Destroy;
end;

procedure cCHXTestGroup.AddRegistered;
var
  TestReg : tCHXRegTest;
begin
  for TestReg in CHXRegTests do
    AddChildTest(TestReg.TestClass, TestReg.TestName);
end;

function cCHXTestGroup.AddChildTest(const aTestClass : tCHXTestGroupClass;
  const aTestName : String) : cCHXTestGroup;
begin
  Result := aTestClass.Create;
  OwnedChilds.Add(Result); // Adding to owned child list.
  AddChildTest(Result, aTestName);
end;

procedure cCHXTestGroup.AddChildTest(const aTest : cCHXTestGroup;
  aTestName : String);
var
  aTestChild : cCHXTestGroup;
  ParentTestName : String = '';
  aPos : Integer = 0;
begin
  // Searching Tree structure
  // 'Test1/Test1_1\Test1_1_1.Test1_1_1_1'
  aPos := Pos('.', aTestName);
  if aPos <= 0 then aPos := Pos('/', aTestName);
  if aPos <= 0 then aPos := Pos('\', aTestName);
  if aPos > 0 then
  begin
    ParentTestName := Copy(aTestName, 1, aPos - 1);
    aTestName := Copy(aTestName, aPos + 1);
  end;

  // Parent is this Test, removing it and searching tree structure again.
  if ParentTestName = Self.TestName then
  begin
    aPos := Pos('.', aTestName);
    if aPos <= 0 then aPos := Pos('/', aTestName);
    if aPos <= 0 then aPos := Pos('\', aTestName);
    if aPos > 0 then
    begin
      ParentTestName := Copy(aTestName, 1, aPos - 1);
      aTestName := Copy(aTestName, aPos + 1);
    end;
  end;

  if ParentTestName = '' then // Add to this Test
  begin
    // Checking if there is already the same object.
    for aTestChild in TestChilds do
      if aTestChild = aTest then // Comparing instances.
        Exit;

    // Checking if a child have same name.
    for aTestChild in TestChilds do
    begin
      if SameText(aTestChild.TestName, aTest.TestName) then
      begin
        // if it is an empty Test Group then substitude it with current.
        if aTestChild is cCHXEmptyTestGroup then
        begin
          aTest.CopyFrom(aTestChild);

          // Exchange them
          aPos := TestChilds.Remove(aTestChild);
          TestChilds.Insert(aPos, aTest);

          // Freeing aTestChild if owned
          if OwnedChilds.Contains(aTestChild) then
          begin
            OwnedChilds.Remove(aTestChild);
            aTestChild.Free;
          end;
        end;
        // else Same name but different intance.
        // Not sure what to do, by now it's ignored.
        // It can be in OwnedChilds, but it is not in TestChilds.
        // ToDo: Send a message to writers when info/status is implemented?
        // TODO: When reports were implemented... Add stIgnored state
        Exit;
      end;
    end; // for aTestChild in TestChilds

    // Finally, we can add it
    if aTestName = '' then
      aTestName := aTest.ClassName;
    aTest.TestName := aTestName;
    aTest.SetTreeDepth(TreeDepth + 1); // Hack: Private method of another instance
    aTest.AddWriters(Self.TestWriters);
    TestChilds.Add(aTest);
  end
  else // Add to a subtest
  begin
    // Adding to already existing subtest
    for aTestChild in TestChilds do
      if SameText(aTestChild.TestName, ParentTestName) then
      begin
        aTestChild.AddChildTest(aTest, aTestName);
        Exit;
      end;

    // Creating a new owned empty test to add it
    aTestChild := AddChildTest(cCHXEmptyTestGroup, ParentTestName);
    aTestChild.AddChildTest(aTest, aTestName);
  end;
end;

function cCHXTestGroup.AddWriter(const WriterClass : tCHXTestWriterClass)
  : cCHXTestWriter;
var
  aTest : cCHXTestGroup;
begin
  Result := WriterClass.Create; // Creating with default values.
  OwnedWriters.Add(Result); // Adding to owned writers list.
  AddWriter(Result);

  // Adding to childs
  for aTest in TestChilds do
    aTest.AddWriter(Result);
end;

procedure cCHXTestGroup.AddWriter(const Writer : cCHXTestWriter);
var
  aWriter: cCHXTestWriter;
begin
  // Checking already added.
  for aWriter in TestWriters do
    if aWriter = Writer then // Comparing instances
      Exit;

  TestWriters.Add(Writer);
end;

procedure cCHXTestGroup.AddWriters(const WriterList : cCHXTestWriterList);
var
  aWriter: cCHXTestWriter;
begin
  // TestWriters.AddRange(WriterList);
  // Adding one by one, so we we will check if already added.
  for aWriter in WriterList do
    AddWriter(aWriter);
end;

function cCHXTestGroup.GetCasePos(const aCaseName: String): Integer;
var
  i : Integer;
begin
  for i := 0 to (TestCases.Count - 1) do
    if CompareText(TestCases[i].CaseName, aCaseName) = 0 then
      Exit(i);
  Result := -1;
end;

procedure cCHXTestGroup.SetCaseEnabled(const aCaseName: string;
  const aEnabled: Boolean);
var
  i : Integer;
  TempCase : tTestCase;
begin
  for i := 0 to (TestCases.Count - 1) do
  begin
    // ToDo: Maybe, Regex comparison
    if CompareText(TestCases[i].CaseName, aCaseName) = 0 then
    begin
      TempCase := TestCases[i];
      TempCase.Enabled := aEnabled;
      TestCases[i] := TempCase;
      Break; // Don't break with Regex
    end;
  end;
end;

function cCHXTestGroup.RunCase(const CaseName : String) : Integer;
var
  i : Integer;
  aCase : tTestCase;
begin
  i := GetCasePos(CaseName);
  if i = -1 then Exit; // ToDo: Create a TestResults trError.

  aCase := TestCases[i];
  RunCase(@aCase);
  TestCases[i] := aCase;

  Result := Ord(aCase.TestResults.ResultType) - Ord(rtSuccess);
end;

function cCHXTestGroup.RunCase(TestCase : pTestCase) : Integer;
begin
  NCaseAsserts := 0;

  TestCase^.TestResults.Init(TestCase^.CaseName);
  TestCase^.TestResults.TreeDepth := TestResults.TreeDepth;
  TestCase^.TestResults.ResultType := rtStart;
  TestCase^.TestResults.NOwnedCases := 1;
  DoCaseStart(TestCase^.TestResults);
  NotifyCaseStart(TestCase^.TestResults);

  TestCase^.TestResults.TimeElapsed := GetTickCount64;

  try // try..finally
    if not TestCase^.Enabled then
    begin
      AddCaseSkip(TestCase);
      Exit; // Jump to finally
    end;

    try
      TestCase^.Method(); // Ejecución directa del puntero almacenado
      AddCaseSuccess(TestCase);
    except
      on E: eCHXTestFailed do
      begin
        if (ExceptAddr <> nil) then
          TestCase^.TestResults.BackTrace := Trim(BackTraceStrFunc(ExceptAddr));
        AddCaseFail(TestCase, E.Message);
      end;
      on E: Exception do
      begin
        FailedAssert := Format(rsUnexpectedException, [E.ClassName]);
        // Not useful here... it doesn't show the line inside the method...
        if (ExceptAddr <> nil) then
          TestCase^.TestResults.BackTrace := Trim(BackTraceStrFunc(ExceptAddr));
        AddCaseError(TestCase, E.Message);
      end;
    end;
  finally
    TestCase^.TestResults.NAsserts := NCaseAsserts;

    TestCase^.TestResults.TimeElapsed :=
      GetTickCount64 - TestCase^.TestResults.TimeElapsed;

    DoCaseEnd(TestCase^.TestResults);
    NotifyCaseEnd(TestCase^.TestResults);
  end;

  Result := Ord(TestCase^.TestResults.ResultType) - Ord(rtSuccess);
end;

function cCHXTestGroup.RunAllCases : Integer;
var
  i : Integer;
  aCase : tTestCase;
  aSubTestGroup : cCHXTestGroup;
begin
  if TreeDepth = 0 then
  begin
    DoBeforeStart;
    NotifyBeforeStart;
  end;

  TestResultInit;
  if not Enabled then
  begin
    TestResults.ResultType := rtSkip;
    DoTestEnd;
    NotifyTestEnd;
    Exit;
  end;

  TestResults.ResultType := rtStart;
  TestResults.TimeElapsed := GetTickCount64;
  DoTestStart;
  NotifyTestStart;

  // Run a copy and update original
  for i := 0 to TestCases.Count - 1 do
  begin
    aCase := TestCases[i];
    RunCase(@aCase);
    TestResults.AddResult(aCase.TestResults);
    TestCases[i] := aCase;
  end;

  for aSubTestGroup in TestChilds do
  begin
    aSubTestGroup.RunAllCases;
    TestResults.AddResult(aSubTestGroup.TestResults);
  end;

  TestResults.TimeElapsed := GetTickCount64 - TestResults.TimeElapsed;
  DoTestEnd;
  NotifyTestEnd;

  if TreeDepth = 0 then
  begin
    DoAfterEnd;
    NotifyAfterEnd;
  end;

  Result := Ord(TestResults.ResultType) - Ord(rtSuccess);
end;

procedure RegisterCHXTestGroup(const aTGClass : tCHXTestGroupClass;
  aName : String);
var
  TempReg : tCHXRegTest;
begin
  if aName = '' then aName := aTGClass.ClassName;
  for TempReg in CHXRegTests do
    if SameText(TempReg.TestName, aName) then
      Exit;
  SetLength(CHXRegTests, Length(CHXRegTests) + 1);
  CHXRegTests[High(CHXRegTests)].TestName := aName;
  CHXRegTests[High(CHXRegTests)].TestClass := aTGClass;
end;

initialization

finalization

end.
