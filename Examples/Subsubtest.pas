program Subsubtests;
{< Simple test of 3 nested test groups.

  (c) 2026 Chixpy https://github.com/Chixpy
}
{$MODE ObjFPC}{$H+}{$INLINE ON}{.$WARN 6058 OFF}

uses
  SysUtils, ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON;

type

  cTest1 = class(cCHXTestGroup)
  published
    procedure Test1_1;
  end;

  cTest1a = class(cCHXTestGroup)
  published
    procedure Test1a_1;
  end;

  cTest1a1 = class(cCHXTestGroup)
  published
    procedure Test1a1_1;
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
  cTest1a1
}

procedure cTest1a1.Test1a1_1;
begin
  MustTrue(True);
  Sleep(80);
end;

{
  Main program
}

var
  MainTest, SubTest : cCHXTestGroup;

begin
  MainTest := cTest1.Create;
  MainTest.AddWriter(cCHXTWConsole);
  if ParamCount >= 1 then
    cCHXTWJSON(MainTest.AddWriter(cCHXTWJSON)).FileName := ParamStr(1);
  // Adding by class type, parent test frees it on destroy.
  SubTest := MainTest.AddChildTest(cTest1a);
  SubTest.AddChildTest(cTest1a1);
  ExitCode := MainTest.RunAllCases;
  MainTest.Free;
end.
