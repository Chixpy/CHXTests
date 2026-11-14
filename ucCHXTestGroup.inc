{%MainUnit ucCHXTestGroup.pas}
(*
  Include file for creating `Must[x]` asserting methods for `cCHXTestGroup` (or
  any descendant) for types.

  With this unit next methods can be declared an implemented:
    - `MustEqual`, `MustNotEqual` with `=` and `<>` comparisons
    - `MustEqual`, `MustNotEqual` with a `<TypeSameValue>(Var1, Var2, Sigma)`
      function.
    - `MustGreater`, `MustLess`, `MustGrtEqu`, `MustLssEqu` with `<`, `>`,
      `<=` and `>=` comparisons.

  For implementation, a function that converts it to a string is needed (to
    show values on failed asserts).

  For method declaration:

  ```
    <cTestClass> = class(cCHXTestGroup)
      [...]
      {$MACRO ON}

      {$PUSH}
      {$DEFINE TestMethodsDecl}   // Add declarations
      {$UNDEF TestMethodsImpl}    // Don't add implementation

      {$DEFINE TestEquMethods}        // Add `=` and `<>`
      {$DEFINE TestSameValueMethods} // Add <TypeSameValue>
      {$DEFINE TestGrtLssMethods}    // Add `<`, `>`, `<=` and `>=`

      {$DEFINE CustomType := <CustomType>} // Type for assertions
      {$I 'ucCHXTestGroup.inc'}

      {$POP}
      [...]
    end;
  ```

  For method implementation:

  ```
  implementation
  [...]
  {$MACRO ON}

  {$PUSH}
  {$UNDEF TestMethodsDecl}   // Don't add declarations
  {$DEFINE TestMethodsImpl}   // Add implementations
  {$DEFINE TestGroupClass := <cTestClass>}

  // Same defines as in declaration of current type
  {$DEFINE TestEquMethods}     // `=` and `<>`
  {$DEFINE TestSameValueMethods} // <TypeSameValue>
  {$DEFINE TypeSameValue := <SameValueFunc>}
  {$DEFINE TestGrtLssMethods} // `<`, `>`, `<=` and `>=`

  {$DEFINE FToString := <FunctionToString>}
  {$DEFINE CustomType := <CustomType>}
  {$I 'ucCHXTestGroup.inc'}
  {$POP}
  [...]
  ```

  ***NOTE***: Instead do not define a value with `{.$DEFINE`, it's better
  undefine it with `{$UNDEF` before include this file.

  ***NOTE***: Maybe set `ucCHXTestGroup.inc` directory is needed to be added.
*)

// Test group declaration

{$IFDEF TestMethodsDecl}

  {$IFDEF TestEquMethods}

procedure MustEqual(const Value, Correct: CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
procedure MustNotEqual(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;

  {$ENDIF}

  {$IFDEF TestSameValueMethods}

procedure MustEqual(const Value, Correct, Sigma: CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
procedure MustNotEqual(const Value, Correct, Sigma : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;

  {$ENDIF}

  {$IFDEF TestGrtLssMethods}

procedure MustGreater(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
procedure MustLess(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
procedure MustGrtEqu(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
procedure MustLssEqu(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;

  {$ENDIF}

{$ENDIF}

// ---- Implementation section

{$IFDEF TestMethodsImpl}

  {$IFDEF TestEquMethods}

procedure TestGroupClass.MustEqual(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value = Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsEqualFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

procedure TestGroupClass.MustNotEqual(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value <> Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsNotEqualFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

  {$ENDIF}

  {$IFDEF TestSameValueMethods}

procedure TestGroupClass.MustEqual(const Value, Correct, Sigma: CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
begin
  Inc(NCaseAsserts);
  if TypeSameValue(Value, Correct, Sigma) then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsEqualFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

procedure TestGroupClass.MustNotEqual(const Value, Correct, Sigma : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
  overload;
begin
  Inc(NCaseAsserts);
  if not TypeSameValue(Value, Correct, Sigma) then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsNotEqualFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

  {$ENDIF}

  {$IFDEF TestGrtLssMethods}

procedure TestGroupClass.MustGreater(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value > Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsGreaterFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

procedure TestGroupClass.MustLess(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value < Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsLessFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

procedure TestGroupClass.MustGrtEqu(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value >= Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsGrtEquFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

procedure TestGroupClass.MustLssEqu(const Value, Correct : CustomType;
  Sender, Msg : String; ErrAdrs: Pointer);
begin
  Inc(NCaseAsserts);
  if Value <= Correct then Exit; // OK

  if Sender = '' then Sender := {$I %CURRENTROUTINE%};
  if Msg = '' then Msg := rsLssEquFmt;
  if not Assigned(ErrAdrs) then ErrAdrs := CallerAddr;

  MustFail(Sender, Format(Msg, [FToString(Value), FToString(Correct)]), ErrAdrs);
end;

  {$ENDIF}

{$ENDIF}
