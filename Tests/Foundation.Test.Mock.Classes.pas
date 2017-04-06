unit Foundation.Test.Mock.Classes;

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
  System.Classes,
  TestFramework,
  Foundation.System;

type
  TStringsWriter = class(TStringList)
  public
    procedure Write(const Value: string); overload;
    procedure Write(const Value: string; const Args: array of const); overload;
  end;

  TWriterTestCase = class(TTestCase)
  protected
    FWriter: TStringsWriter;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

///  This classes is not implemented to mock the databases components, it is
///  only used to help test others classes simulating an understandable
///  behaviour.
///
///  For real database tests, it is best to use Spring4D with In-memory SQLite.
  TDatabaseObject = class
  protected
    FWriter: TStringsWriter;
  public
    constructor Create(Writer: TStringsWriter); virtual;
    destructor Destroy; override;
  end;

  TQuery = class(TDatabaseObject)
  private
    FRecordCount: Integer;
    FIndex: Integer;
  public
    constructor Create(Writer: TStringsWriter); override;
    procedure Close;
    function EOF: Boolean;
    function IsEmpty: Boolean;
    function Next: Boolean;
    function Open(const SQL: string): Boolean;
    function RecordCount: Integer;
    function Value: string;
  end;

  TQuerable = class(TDatabaseObject)
  public
    function Query: TQuery;
  end;

  TTransaction = class(TQuerable)
  public
    procedure Commit;
    procedure RollBack;
  end;

  TDatabase = class(TQuerable)
  public
    procedure Open(const DatabaseName: string);
    procedure Close;

    function StartTransaction: TTransaction;
  end;

  ITracer = interface(IInterface)
    ['{46BB4358-F84E-49B5-82A3-802FCF3B5E5C}']
    procedure Enter(const MethodName: string);
    procedure Exit;
    procedure Step(const Msg: string = '');
  end;

  TTrace = class(TInterfacedObject, ITracer)
  private
    FMethodName: string;
    FStep: Integer;
    FWriter: TStringsWriter;
  public
    constructor Create(Writer: TStringsWriter);
    class function Method(Writer: TStringsWriter; const MethodName: string; var TraceProc: ITracer): IDeferrer;
    procedure Enter(const MethodName: string);
    procedure Exit;
    procedure Step(const Msg: string = '');
  end;

implementation

uses
  System.SysUtils;


{ TDatabaseObject }

constructor TDatabaseObject.Create(Writer: TStringsWriter);
begin
  inherited Create;
  FWriter := Writer;
end;

destructor TDatabaseObject.Destroy;
begin
  FWriter.Write(Self.ClassName + '.Free');
  inherited;
end;

{ TQuery }

procedure TQuery.Close;
begin
  FWriter.Write('TQuery.Close');
end;

function TQuery.Next: Boolean;
begin
  Result := FIndex < FRecordCount;
  if Result then
    Inc(FIndex);

  FWriter.Write('TQuery.Next = ' + BoolToStr(Result, True));
end;

function TQuery.EOF: Boolean;
begin
  Result := FIndex = FRecordCount;
  FWriter.Write('TQuery.EOF = ' + BoolToStr(Result, True));
end;

function TQuery.IsEmpty: Boolean;
begin
  Result := FRecordCount = 0;
  FWriter.Write('TQuery.IsEmpty = ' + BoolToStr(Result, True));
end;

function TQuery.Open(const SQL: string): Boolean;
begin
  Result := True;
  FRecordCount := 2;
  FWriter.Write('TQuery.Open(' + SQL + ') = ' + BoolToStr(Result, True));
end;

function TQuery.RecordCount: Integer;
begin
  Result := FRecordCount;
  FWriter.Write('TQuery.RecordCount = ' + IntToStr(Result));
end;

function TQuery.Value: string;
begin
  FWriter.Write('TQuery.Value = ' + IntToStr(FIndex));
end;

constructor TQuery.Create(Writer: TStringsWriter);
begin
  inherited Create(Writer);
  FIndex := 0;
  FRecordCount := 0;
  FWriter.Write('TQuery.Create');
end;

{ TStringListWriter }

procedure TStringsWriter.Write(const Value: string);
begin
  Append(Value);
end;

procedure TStringsWriter.Write(const Value: string; const Args: array of const);
begin
  Write(Format(Value, Args));
end;

{ TTransaction }

procedure TTransaction.Commit;
begin
  FWriter.Write('TTransaction.Commit');
end;

procedure TTransaction.RollBack;
begin
  FWriter.Write('TTransaction.RollBack');
end;

{ TDatabase }

procedure TDatabase.Open(const DatabaseName: string);
begin
  FWriter.Write('TDatabase.Open = ' + DatabaseName);
end;

procedure TDatabase.Close;
begin
  FWriter.Write('TDatabase.Close');
end;

function TDatabase.StartTransaction: TTransaction;
begin
  FWriter.Write('TDatabase.StartTransaction');
  Result := TTransaction.Create(FWriter);
end;

function TQuerable.Query: TQuery;
begin
  FWriter.Write(Self.ClassName + '.Query');
  Result := TQuery.Create(FWriter);
end;

{ TCallStack }

constructor TTrace.Create(Writer: TStringsWriter);
begin
  inherited Create;
  FWriter := Writer;
end;

procedure TTrace.Enter(const MethodName: string);
begin
  FStep := 0;
  FMethodName := MethodName;
  FWriter.Write('> Enter %s', [FMethodName]);
end;

procedure TTrace.Exit;
begin
  FStep := 0;
  FWriter.Write('< Exit %s', [FMethodName])
end;

procedure TTrace.Step(const Msg: string = '');
begin
  Inc(FStep);

  if Msg <> '' then
    FWriter.Write('  %d. %s: %s', [FStep, FMethodName, Msg])
  else
    FWriter.Write('  %d. %s', [FStep, FMethodName]);
end;

class function TTrace.Method(Writer: TStringsWriter; const MethodName: string; var TraceProc: ITracer): IDeferrer;
var
  {! Workaround "Defer(ITracer.Exit)" : E2010 Incompatible types: 'TProc' and 'procedure, untyped pointer or untyped parameter' }
  Trace: TTrace;
begin
  Trace := TTrace.Create(Writer);
  Trace.Enter(MethodName);
  Result := Defer(Trace.Exit);
  Supports(Trace, ITracer, TraceProc)
end;

{ TWriterTestCase }

procedure TWriterTestCase.SetUp;
begin
  inherited;
  FWriter := TStringsWriter.Create;
end;

procedure TWriterTestCase.TearDown;
begin
  inherited;
  FWriter.Free;
end;

end.
