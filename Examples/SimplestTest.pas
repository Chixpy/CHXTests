program SimplestTest;
{< Simples test of cCHXTestGroup. }
{$MODE ObjFPC}{$H+}{$INLINE ON}{.$WARN 6058 OFF} // Inline not inlined

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON;

type

  {$PUSH}
  {$M+} // or {$TYPEINFO ON} Actually not needed, `cCHXTestGroup` adds it.
  cTestCases = class(cCHXTestGroup)
  published
    // A test group without any test case must show a warning.
    procedure ExampleCase;
  end;
  {$POP}

{
  cTestCases
}

procedure cTestCases.ExampleCase;
begin
  // A test case without any assertion must show a warning.
  MustTrue(True);
end;

{
  Main program
}

var
  MainTest : cTestCases;

begin
  MainTest := cTestCases.Create;
  // Writers added by class type are autofreed on test destroy.
  MainTest.AddWriter(cCHXTWConsole);
  if ParamCount >= 1 then
    cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON)).FileName := ParamStr(1);
  ExitCode := MainTest.RunAllCases;
  MainTest.Free;
end.
