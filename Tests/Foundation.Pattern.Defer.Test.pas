unit Foundation.Pattern.Defer.Test;

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
  System.Generics.Collections,
  System.SysUtils,
  TestFramework,
  Foundation.Test.Mock.Classes,
  Foundation.Pattern.Defer,
  Foundation.Pattern.Defer.Test.Consts,
  Foundation.System;

type
  ///  In order to test Defer, the defer process must happen inside other
  ///  method becouse Defer only happen when exits from the methods,
  ///  after the "end;" of the method caller.
  ///
  ///  AnonymousMethod calls AnonymousMethodExecute so the defer can be recorded
  ///  in FWriter and then tested with Check* methods.
  TestIDeferrer = class(TWriterTestCase)
  private
    procedure AnonymousMethodExecute;
    procedure ExceptionBreakFlowExecute;
    procedure MultipleDeferInstancesExecute;
    procedure ProcDeferOrderExecute;
    procedure DelegateDeferToTraceExecute;
  published
    procedure AnonymousMethod;
    procedure ExceptionBreakFlow;
    procedure MultipleDeferInstances;
    procedure NilProc;
    procedure ProcDeferOrder;
    procedure DelegateDeferToTrace;
  end;

implementation

procedure TestIDeferrer.AnonymousMethod;
begin
  AnonymousMethodExecute;
  CheckEquals('TDatabase.Free' + sLineBreak, FWriter.Text);
end;

procedure TestIDeferrer.AnonymousMethodExecute;
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

procedure TestIDeferrer.ExceptionBreakFlow;
begin
  try
    // this test is not to check an expected exception
    // it is to check the defer flow until the exception
    ExceptionBreakFlowExecute;
  except
    // keep the flow to check FWriter.Text
  end;

  CheckEquals(EXCEPTION_BREAK_FLOW_RECORDING, FWriter.Text);
end;

procedure TestIDeferrer.ExceptionBreakFlowExecute;
var
  Database: TDatabase;
  Exec: IDeferrer;
  Query: TQuery;
  Transaction: TTransaction;
begin
  Database := TDatabase.Create(FWriter);
  Exec := Defer(Database.Free);

  Database.Open('foundation-db');
  Exec.Defer(Database.Close);

  Transaction := Database.StartTransaction;
  Exec.Defer(Transaction.Free);
  Exec.Defer(Transaction.Commit);

  // exception breaks the flow, but Defer still will process all deferred procs
  raise Exception.Create('');

  // the next lines will not be executed or deferred
  Query := Transaction.Query;
  Exec.Defer(Query.Free);

  if Query.Open('select value from table') then
  begin
    Exec.Defer(Query.Close);
  end;
end;

procedure TestIDeferrer.MultipleDeferInstances;
begin
  MultipleDeferInstancesExecute;
  CheckEquals(PROC_DEFER_ORDER_STEPS, FWriter.Text);
end;

procedure TestIDeferrer.MultipleDeferInstancesExecute;
var
  Database: TDatabase;
  Query: TQuery;
  Transaction: TTransaction;
begin
  // this test is not keeping the IDeferrer instance reference
  // neither is using auto defer
  // at the end will be 6 instances of IDeferrer
  // that will be released in the reverse order as the TDeferrer.Stack
  // need to check if this behaviour is consistent, Tested Win7 32 and Win10 66
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

procedure TestIDeferrer.NilProc;
var
  Exec: IDeferrer;
  ProcDeferOrder: TProc;
begin
  ProcDeferOrder := nil;
  StartExpectingException(EDefer);
  Exec := Defer(ProcDeferOrder);
  StopExpectingException('');
end;

procedure TestIDeferrer.ProcDeferOrder;
begin
  ProcDeferOrderExecute;
  CheckEquals(PROC_DEFER_ORDER_STEPS, FWriter.Text);
end;

procedure TestIDeferrer.ProcDeferOrderExecute;
var
  Database: TDatabase;
  Exec: IDeferrer;
  Query: TQuery;
  Transaction: TTransaction;
begin
  Database := TDatabase.Create(FWriter);
  Exec := Defer(Database.Free);

  Database.Open('foundation-db');
  Exec.Defer(Database.Close);

  Transaction := Database.StartTransaction;
  Exec.Defer(Transaction.Free);
  Exec.Defer(Transaction.Commit);

  Query := Transaction.Query;
  Exec.Defer(Query.Free);

  if Query.Open('select value from table') then
  begin
    Exec.Defer(Query.Close);
    Query.RecordCount;
  end;

  while not Query.EOF do
  begin
    Query.Value;
    Query.Next;
  end;
end;

procedure TestIDeferrer.DelegateDeferToTrace;
begin
  DelegateDeferToTraceExecute;
  CheckEquals(DELEGATE_DEFER_TO_TRACE_RECORDING, FWriter.Text);
end;

procedure TestIDeferrer.DelegateDeferToTraceExecute;
var
  Trace: ITracer;
begin
  TTrace.Method(FWriter, 'DelegateDeferToTraceExecute', Trace);

  Trace.Step('First');
  Trace.Step('Second');
  Trace.Step('Third');
end;

initialization
  RegisterTest(TestIDeferrer.Suite);

end.
