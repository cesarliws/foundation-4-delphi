unit Foundation.Pattern.Defer;

{******************************************************************************}
{                                                                              }
{ Foundation Framework                                                         }
{                                                                              }
{ Copyright (c) 2012 - 2017                                                    }
{   Cesar Romero <cesarliws@gmail.com>                                         }
{                                                                              }
{******************************************************************************}

///  Dicas sobre Defer:
///  https://imasters.com.br/desenvolvimento/dicas-de-como-utilizar-go-defer/

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  /// <summary>
  ///  IDeferrer define o padr�o "defer execute procedure", que deve agendar a
  ///  procedure TProc para ser executada imediatamente ap�s o fim do m�todo que
  ///  fez a chamada ao Defer(Proc).
  ///
  ///  Adiar a execu��o de procedures tem algumas vantagens:
  ///  * Garante que voc� n�o vai esquecer de finalizar/fechar um recurso,
  ///  um erro bem comum quando � feito a manuten��o do c�digo e novas condi��es
  ///  s�o adicionadas, criando um novo caminho para o fluxo da procedure;
  ///  * O c�digo de finaliza��o fica junto ao de inicializa��o, que �
  ///  mais leg�vel do que colocar no fim do m�todo;
  ///  * Dispensa a necessidade de blocos try/finally para garantir que um
  ///  recurso seja finalizado.
  ///  * Mesmo que ocorra uma Exception, todos os m�todos agendados no defer
  ///  ser�o executados.
  ///
  ///  Exemplos da sua utiliza��o s�o desbloquear um CriticalSection, fechar um
  ///  arquivo ou fechar uma conex�o com o banco de dados.
  ///
  ///  Evite usar defer dentro de loops, isso pode causar um aumento excessivo
  ///  de mem�ria se muitos objetos forem alocados, podendo ocasionar o erro
  ///  "Out of memory".
  ///
  ///  Ao usar com m�todos anonimos tenha em mente que o estado � capturado,
  ///  qualquer vari�vel utilizada, ter� o valor capturado no momento em que
  ///  o defer for declarado e n�o o valor alterado durante o fluxo da
  ///  procedure.
  ///
  ///  Esta padr�o � baseado na function Defer em #Golang e n�o tem rela��o
  ///  aos padr�es "Deferred/Promise" e "Deferred Choice".
  /// </summary>
  IDeferrer = Interface(IInterface)
    ['{CD71BF2E-9E61-4867-B74A-2D8535636A03}']
    ///  Defer adiciona uma procedure a pilha para ser ser executada na
    ///  finaliza��o
    function Defer(Proc: TProc): IDeferrer;
  end;

  ///  TDeferrer implementa o padr�o defer execute procedure utilizando uma
  ///  pilha "Stack" para armazenar as procedures adiadas e as executa quando
  ///  o TDeferrer � destru�do.
  ///
  ///  A ordem de execu��o das procedures � inversa, a �ltima procedure
  ///  adicionada ao Defer ser� a primeira a ser executada;
  TDeferrer = class(TInterfacedObject, IDeferrer)
  strict private
    type
      TStackItem = record
        Proc: TProc;
      end;
  strict private
    FStack: TStack<TStackItem>;
    procedure Push(Proc: TProc);
    procedure ProcessStack;
  public
    constructor Create; overload;
    constructor Create(Proc: TProc); overload;
    destructor Destroy; override;

    function Defer(Proc: TProc): IDeferrer;
  end;

  EDefer = class(Exception)
  end;

resourcestring
  SDEFER_PROC_CANNOT_BE_NIL = 'Defer Proc cannot be nil.';

implementation

constructor TDeferrer.Create;
begin
  inherited Create;
  FStack := TStack<TStackItem>.Create;
end;

destructor TDeferrer.Destroy;
begin
  ProcessStack;
  FStack.Free;
  inherited;
end;

procedure TDeferrer.ProcessStack;
var
  StackItem: TStackItem;
begin
  while FStack.Count > 0 do
  begin
    StackItem := FStack.Pop;
    StackItem.Proc()
  end;
end;

function TDeferrer.Defer(Proc: TProc): IDeferrer;
begin
  Result := Self;
  if not Assigned(Proc) then
  begin
    raise EDefer.Create(SDEFER_PROC_CANNOT_BE_NIL);
  end;
  Push(Proc);
end;

procedure TDeferrer.Push(Proc: TProc);
var
  StackItem: TStackItem;
begin
  StackItem.Proc := Proc;
  FStack.Push(StackItem);
end;

constructor TDeferrer.Create(Proc: TProc);
begin
  Create;
  Defer(Proc);
end;

end.

