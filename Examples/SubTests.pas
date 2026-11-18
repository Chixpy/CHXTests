program SubTests;
{

}
{$MODE ObjFPC}{$H+}{$INLINE ON}{.$WARN 6058 OFF}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON,
  utCHXTestResults;

type

  cTest1 = class(cCHXTestGroup)
  published
    procedure Test1_1;
  end;

  cTest1a = class(cCHXTestGroup)
  published
    procedure Test1a_1;
  end;

  cTest1b = class(cCHXTestGroup)
  published
    procedure Test1b_1;
  end;

{
  cTest1
}

procedure cTest1.Test1_1;
begin
  MustTrue(True);
  Sleep(50);
end;

{
  cTest1a
}

procedure cTest1a.Test1a_1;
begin
  MustTrue(True);
  Sleep(25);
end;

{
  cTest1b
}

procedure cTest1b.Test1b_1;
begin
  MustTrue(True);
  Sleep(80);
end;

{
  Main program
}

var
  MainTest : cTest1;

begin
  MainTest := cTest1.Create;
  MainTest.AddWriter(cCHXTWConsole);
  if ParamCount >= 1 then
    cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON)).FileName := ParamStr(1);
  MainTest.AddChildTest(cTest1a);
  MainTest.AddChildTest(cTest1b);
  ExitCode := MainTest.RunAllCases;
  MainTest.Free;
end.
