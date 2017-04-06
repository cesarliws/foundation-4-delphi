unit Foundation.Pattern.Defer.Auto.Test;

{******************************************************************************}
{                                                                              }
{ Foundation Framework                                                         }
{                                                                              }
{ Copyright (c) 2012 - 2017                                                    }
{   Cesar Romero <cesarliws@gmail.com>                                         }
{                                                                              }
{******************************************************************************}

interface

uses
  System.SysUtils,
  ///
  TestFramework,
  ///
  Foundation.Pattern.Defer.Auto,
  Foundation.Test.Mock.Classes;

type
  TestTDeferAuto = class(TWriterTestCase)
  private
    procedure AnonymousMethodExecute;
    procedure ProcDeferOrderExecute;
    procedure DelegateDeferToTraceExecute;
  published
    procedure DelegateDeferToTrace;
    procedure ProcDeferOrder;

    ///  RaceCondition test is only used to check how defer behave being called
    ///  for different threads
    procedure RaceCondition;
  end;

implementation

uses
  System.Classes,
  Foundation.Pattern.Defer.Test.Consts;

{ TTestDefer }

type
  TTestDefer = class(TObject)
  public
    FDeferred: Boolean;
    procedure DeferThis;
    procedure CallDefer;
  end;

procedure TTestDefer.CallDefer;
begin
  FDeferred := False;
  Defer(DeferThis);
end;

procedure TTestDefer.DeferThis;
begin
  FDeferred := True;
end;

{ TAutoTrace }

type
  TAutoTrace = class(TTrace)
  public
    class function TraceMethod(Writer: TStringsWriter; const MethodName: string; out Tracer: ITracer): IDeferrer;
    constructor Create(Writer: TStringsWriter; const MethodName: string; out Tracer: ITracer; out Deferrer: IDeferrer);
    destructor Destroy; override;
  end;

class function TAutoTrace.TraceMethod(Writer: TStringsWriter; const MethodName: string; out Tracer: ITracer): IDeferrer;
begin
  TAutoTrace.Create(Writer, MethodName, Tracer, Result);
end;

constructor TAutoTrace.Create(Writer: TStringsWriter; const MethodName: string; out Tracer: ITracer; out Deferrer: IDeferrer);
begin
  inherited Create(Writer);
  Self.Enter(MethodName);
  Deferrer := Defer(Self.Exit, 4);
  Tracer := Self;
end;

destructor TAutoTrace.Destroy;
begin
  inherited
end;

procedure TestTDeferAuto.AnonymousMethodExecute;
var
  Database: TDatabase;
begin
  Database := TDatabase.Create(FWriter);
  Defer(
    procedure
    begin
      Database.Free;
    end
  );
end;

procedure TestTDeferAuto.ProcDeferOrder;
begin
  FWriter.Clear;
  ProcDeferOrderExecute;
  CheckEquals(PROC_DEFER_ORDER_STEPS, FWriter.Text);

  FWriter.Clear;
  AnonymousMethodExecute;
  CheckEquals('TDatabase.Free' + sLineBreak, FWriter.Text);
end;

procedure TestTDeferAuto.ProcDeferOrderExecute;
var
  Database: TDatabase;
  Query: TQuery;
  Transaction: TTransaction;
begin
  Database := TDatabase.Create(FWriter);
  Defer(Database.Free);

  Database.Open('foundation-db');
  Defer(Database.Close);

  Transaction := Database.StartTransaction;
  Defer(Transaction.Free);
  Defer(Transaction.Commit);

  Query := Transaction.Query;
  Defer(Query.Free);

  if Query.Open('select value from table') then
  begin
    Defer(Query.Close);
    Query.RecordCount;
  end;

  while not Query.EOF do
  begin
    Query.Value;
    Query.Next;
  end;
end;

procedure TestTDeferAuto.RaceCondition;
var
  Obj1: TTestDefer;
  Obj2: TTestDefer;
  Thread1: TThread;
  Thread2: TThread;
  Thread3: TThread;
  Thread4: TThread;
  Thread5: TThread;
  Thread6: TThread;
  Thread7: TThread;
  Thread8: TThread;
  Thread9: TThread;
begin
  Obj1 := TTestDefer.Create;
  Defer(Obj1.Free);
  Obj1.CallDefer;

  Thread1 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread2 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread3 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread4 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread5 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread6 := TThread.CreateAnonymousThread(
    procedure
    var
      Obj: TTestDefer;
    begin
      Obj := TTestDefer.Create;
      Defer(Obj.Free);
      Obj.CallDefer;
    end
  );

  Thread7 := TThread.CreateAnonymousThread(
    procedure
    var
      Trace: ITracer;
      Writer: TStringsWriter;
    begin
      // FWriter cannot be shared beetwen different threads
      Writer := TStringsWriter.Create;
      Defer(Writer.Free);
      TAutoTrace.TraceMethod(Writer, 'TThread.CreateAnonymousThread7', Trace);

      Trace.Step('First');
      Trace.Step('Second');
      Trace.Step('Third');
    end
  );

  Thread8 := TThread.CreateAnonymousThread(
    procedure
    var
      Trace: ITracer;
      Writer: TStringsWriter;
    begin
      // FWriter cannot be shared beetwen different threads
      Writer := TStringsWriter.Create;
      Defer(Writer.Free);
      TAutoTrace.TraceMethod(Writer, 'TThread.CreateAnonymousThread8', Trace);

      Trace.Step('First');
      Trace.Step('Second');
      Trace.Step('Third');
    end
  );

  Thread9 := TThread.CreateAnonymousThread(
    procedure
    var
      Trace: ITracer;
      Writer: TStringsWriter;
    begin
      // FWriter cannot be shared beetwen different threads
      Writer := TStringsWriter.Create;
      Defer(Writer.Free);
      TAutoTrace.TraceMethod(Writer, 'TThread.CreateAnonymousThread9', Trace);

      Trace.Step('First');
      Trace.Step('Second');
      Trace.Step('Third');
    end
  );

  Thread1.Start;
  Thread2.Start;
  Thread3.Start;
  Thread4.Start;
  Thread5.Start;
  Thread6.Start;
  Thread7.Start;
  Thread8.Start;
  Thread9.Start;

  Obj2 := TTestDefer.Create;
  Defer(Obj2.Free);
  Obj2.CallDefer;
end;

procedure TestTDeferAuto.DelegateDeferToTrace;
begin
  DelegateDeferToTraceExecute;
  CheckEquals(DELEGATE_DEFER_TO_TRACE_RECORDING, FWriter.Text);
end;

procedure TestTDeferAuto.DelegateDeferToTraceExecute;
var
  Tracer: ITracer;
begin
  TAutoTrace.TraceMethod(FWriter, 'DelegateDeferToTraceExecute', Tracer);

  Tracer.Step('First');
  Tracer.Step('Second');
  Tracer.Step('Third');
end;

initialization
  RegisterTest(TestTDeferAuto.Suite);

end.
