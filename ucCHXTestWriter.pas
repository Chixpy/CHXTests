unit ucCHXTestWriter;

{$mode ObjFPC}{$H+}{$inline OFF}{$OPTIMIZATION OFF}
{$MODESWITCH FunctionReferences}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH TypeHelpers}

interface

uses
  Generics.Collections, utCHXTestResults;

type

{ cCHXTestWriter }

  cCHXTestWriter = class(tObject)
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure OnBeforeStart; virtual;
    procedure OnTestStart(const TestResult : tCHXTestResults); virtual;
    procedure OnTestEnd(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseStart(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseEnd(const TestResult : tCHXTestResults); virtual;
    procedure OnCaseInfo(const TestResult : tCHXTestResults;
      const Text : String); virtual;
    {< Called when a case sends persistent information.

      `TestResult.Info` already contains the new text appended. Writers that
      only need the final information can ignore this callback and use
      `OnCaseEnd`.
    }
    procedure OnCaseProgress(const TestResult : tCHXTestResults;
      const Text : String; const Percent : Integer); virtual;
    {< Called when a case sends transient progress.

      `Percent` is a value from 0 to 100, or -1 when it is not available.
      Progress is not stored in `TestResult`.
    }
    procedure OnAfterEnd(const TestResult : tCHXTestResults); virtual;
  end;

  tCHXTestWriterClass = class of cCHXTestWriter;

  cCHXTestWriterGenList  = specialize tObjectList<cCHXTestWriter>;
  cCHXTestWriterList  = class(cCHXTestWriterGenList)
  end;

implementation

constructor cCHXTestWriter.Create;
begin
  inherited Create;
end;

destructor cCHXTestWriter.Destroy;
begin
  inherited Destroy;
end;

procedure cCHXTestWriter.OnBeforeStart;
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnTestStart(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnTestEnd(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseStart(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseEnd(const TestResult : TCHXTestResults);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseInfo(const TestResult : TCHXTestResults;
  const Text : String);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnCaseProgress(const TestResult : TCHXTestResults;
  const Text : String; const Percent : Integer);
begin
  // Do nothing by default
end;

procedure cCHXTestWriter.OnAfterEnd(const TestResult : tCHXTestResults);
begin
  // Do nothing by default
end;

initialization

finalization

end.
