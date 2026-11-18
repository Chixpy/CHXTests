# ucCHXTestGroup.inc

Macro include that generates the comparison assertions of a test group: the
`=`/`<>`/`<`/`>`/`<=`/`>=` family and the `SameValue` variant, each as a hard
`Must*` and a soft `May*` method.

The unit `ucCHXTestGroup` includes it twice per type (declarations and
implementations) to generate its built-in assertions. A descendant can include
it the same way to add assertions for a custom type.

## Generated methods

For each type and each enabled comparison, two methods are generated:

| Comparison | Hard | Soft |
| --- | --- | --- |
| `=` | `MustEqual` | `MayEqual` |
| `<>` | `MustNotEqual` | `MayNotEqual` |
| `<` | `MustLess` | `MayLess` |
| `>` | `MustGreater` | `MayGreater` |
| `<=` | `MustLssEqu` | `MayLssEqu` |
| `>=` | `MustGrtEqu` | `MayGrtEqu` |
| `SameValue(A, B, Sigma)` | `MustEqual` | `MayEqual` |
| `not SameValue(A, B, Sigma)` | `MustNotEqual` | `MayNotEqual` |

Signature:

```pascal
procedure MustEqual(const Value, Correct : CustomType;
  Sender : String = ''; Msg : String = ''; ErrAdrs: Pointer = nil);
```

(Floats add `Sigma` as a third value parameter.)

Every method calls `MustFail` or `MayFail`, so the behaviour is the same as the
hand-written assertions: hard failures abort the case, soft failures are
recorded and reported at case end.

## Defines

| Define | Meaning |
| --- | --- |
| `TestMethodsDecl` | Emit declarations (interface/class section). |
| `TestMethodsImpl` | Emit implementations. |
| `TestGroupClass` | Class that receives the implementation, for example `cMyTests`. |
| `CustomType` | Type of the generated assertions. |
| `TestEquMethods` | Generate `=` and `<>`. |
| `TestSameValueMethods` | Generate the `SameValue` variant with `Sigma`. |
| `TestGrtLssMethods` | Generate `<`, `>`, `<=` and `>=`. |
| `TypeSameValue` | Function used by the `SameValue` variant. |
| `FToString` | Function that converts a value to string for messages. |

`TestEquMethods` and `TestSameValueMethods` are mutually exclusive for a type,
because both declare `MustEqual`/`MustNotEqual`.

## Usage

### Declarations, inside the class

```pascal
type
  cMyTests = class(cCHXTestGroup)
  published
    procedure ExampleCase;
  {$MACRO ON}

  {$PUSH}
  {$DEFINE TestMethodsDecl}   // Add declarations
  {$UNDEF TestMethodsImpl}    // Don't add implementations

  {$DEFINE TestEquMethods}       // Add `=` and `<>`
  {$UNDEF TestSameValueMethods}  // Don't add SameValue
  {$DEFINE TestGrtLssMethods}    // Add `<`, `>`, `<=` and `>=`

  {$DEFINE CustomType := TDateTime}
  {$I 'ucCHXTestGroup.inc'}
  {$POP}
  end;
```

### Implementations

```pascal
implementation

{$MACRO ON}

{$PUSH}
{$UNDEF TestMethodsDecl}   // Don't add declarations
{$DEFINE TestMethodsImpl}  // Add implementations
{$DEFINE TestGroupClass := cMyTests}

// Same defines as in the declaration
{$DEFINE TestEquMethods}
{$UNDEF TestSameValueMethods}
{$DEFINE TestGrtLssMethods}

{$DEFINE FToString := DateTimeToStr}
{$DEFINE CustomType := TDateTime}
{$I 'ucCHXTestGroup.inc'}
{$POP}
```

The declaration and the implementation sections must use the **same**
`{$DEFINE}` order, otherwise the generated implementations do not match the
declarations.

### Resulting assertions

```pascal
procedure cMyTests.ExampleCase;
begin
  MustEqual(EndDate, StartDate, 'Dates must match');
  MustGreater(EndDate, StartDate);
end;
```

A failure message is produced with `rsEqualFmt`, `rsGreaterFmt`, etc. If `Msg`
is given, it is formatted with `Format(Msg, [FToString(Value),
FToString(Correct)])`, so `%0:s` is `Value` and `%1:s` is `Correct`.

## Constraints and pitfalls

- `FToString` must exist for the type: `IntToStr`, `UIntToStr`,
  `FloatToStr`, `String`, `HexStr` or a custom function.
- `TypeSameValue` must be a callable function with
  `(A, B, Sigma) : Boolean` signature, for example `Math.SameValue`. Name the
  unit explicitly if `SameValue` is ambiguous.
- The include declares methods on `cCHXTestGroup` by default; for a descendant
  you must define `TestGroupClass` in the implementation section.
- To disable a define, use `{$UNDEF}` before the include instead of
  `{.$DEFINE}`: a definition left from a previous block would otherwise leak
  into the next one. Every block should be wrapped in `{$PUSH}`/`{$POP}`.
- The include directory must be in the compiler unit/include path (`-Fi`).
  The examples compile with `fpcfg.cfg`, which sets `-Fi..`.
- Compare floats only with the `SameValue` variant, never with `=`/`<>`.

## Built-in types

`ucCHXTestGroup` generates assertions for:

| Type | Equality | Order | `FToString` | `SameValue` |
| --- | --- | --- | --- | --- |
| `Int64` | `=`/`<>` | yes | `IntToStr` | — |
| `QWord` | `=`/`<>` | yes | `UIntToStr` | — |
| `Char` | `=`/`<>` | yes | `String` | — |
| `String` | `=`/`<>` | yes | `String` | — |
| `Currency` | `=`/`<>` | yes | `FloatToStr` | — |
| `Single` | — | yes | `FloatToStr` | `Math.SameValue` |
| `Double` | — | yes | `FloatToStr` | `Math.SameValue` |
| `Pointer` | `=`/`<>` | — | `HexStr` | — |
| `TObject` | `=`/`<>` | — | `HexStr` | — |

`Extended` is present but commented out in `ucCHXTestGroup.pas`.
