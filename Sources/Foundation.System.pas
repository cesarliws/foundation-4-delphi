unit Foundation.System;

interface

uses
  System.SysUtils,
  Foundation.Pattern.Defer;

type
  IDeferrer = Foundation.Pattern.Defer.IDeferrer;

/// <summary>
///  Defer é a função que cria uma instância TDeferrer e retorna a Interface
///  IDeferrer. Esta instância é criada no contexto no método que fez a chamada
///  e será finalizada automaticamente no final do método, executando
///  automaticamente em ordem inversa todos as procedures empilhadas.
///
///    procedure ProcessFile(const FileName: string);
///    var
///      File: TFile;
///    begin
///      File := TFile.Open(FileName);
///      Defer(File.Close);
///      while not File.EOF do
///      begin
///        ... process file
///      end;
///    end; // Defer será executado aqui [File.Close]
///
///    procedure ExecSql(const ConnectionString, Sql: string);
///    var
///      Database: TDatabase;
///      Exec: IDeferred;
///      Query: TQuery;
///    begin
///      Database := TDatabase.Create(ConnectionString);
///      Exec := Defer(Database.Free);
///      Database.Open;
///      Exec.Defer(Database.Close);
///
///      Query := Database.Query(SQL);
///      Exec.Defer(Query.Free);
///      Exec.Defer(Query.Close);
///      if Query.IsEmpty then
///        Exit;
///
///      while not Query.EOF do
///      begin
///        ... process query
///      end;
///
///      Exec.Defer(
///        procedure
///        begin
///          Writeln('ExecSql finalizado');
///        end
///      );
///    end; // Defer será executado aqui [Writeln, Query.Close, Database.Close, Database.Free]
/// </summary>
function Defer(Proc: TProc): IDeferrer;

var
  /// <summary>
  ///  ApplicationTerminateHandle is used to notify any background thread that
  ///  the application is being terminated.
  ///
  ///  In MainForm.OnFormClose add the code:
  ///
  ///    ApplicationTerminateHandle := CreateEvent(nil, True, False, nil);
  /// </summary>
  ApplicationTerminateHandle: THandle;

implementation

function Defer(Proc: TProc): IDeferrer;
begin
  Result := TDeferrer.Create(Proc);
end;

end.
