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
  ///  IDeferrer define o padrão "defer execute procedure", que deve agendar a
  ///  procedure TProc para ser executada imediatamente após o fim do método que
  ///  fez a chamada ao Defer(Proc).
  ///
  ///  Adiar a execução de procedures tem algumas vantagens:
  ///  * Garante que você não vai esquecer de finalizar/fechar um recurso,
  ///  um erro bem comum quando é feito a manutenção do código e novas condições
  ///  são adicionadas, criando um novo caminho para o fluxo da procedure;
  ///  * O código de finalização fica junto ao de inicialização, que é
  ///  mais legível do que colocar no fim do método;
  ///  * Dispensa a necessidade de blocos try/finally para garantir que um
  ///  recurso seja finalizado.
  ///  * Mesmo que ocorra uma Exception, todos os métodos agendados no defer
  ///  serão executados.
  ///
  ///  Exemplos da sua utilização são desbloquear um CriticalSection, fechar um
  ///  arquivo ou fechar uma conexão com o banco de dados.
  ///
  ///  Evite usar defer dentro de loops, isso pode causar um aumento excessivo
  ///  de memória se muitos objetos forem alocados, podendo ocasionar o erro
  ///  "Out of memory".
  ///
  ///  Ao usar com métodos anonimos tenha em mente que o estado é capturado,
  ///  qualquer variável utilizada, terá o valor capturado no momento em que
  ///  o defer for declarado e não o valor alterado durante o fluxo da
  ///  procedure.
  ///
  ///  Esta padrão é baseado na function Defer em #Golang e não tem relação
  ///  aos padrões "Deferred/Promise" e "Deferred Choice".
  /// </summary>
  IDeferrer = Interface(IInterface)
    ['{CD71BF2E-9E61-4867-B74A-2D8535636A03}']
    ///  Defer adiciona uma procedure a pilha para ser ser executada na
    ///  finalização
    function Defer(Proc: TProc): IDeferrer;
  end;

  ///  TDeferrer implementa o padrão defer execute procedure utilizando uma
  ///  pilha "Stack" para armazenar as procedures adiadas e as executa quando
  ///  o TDeferrer é destruído.
  ///
  ///  A ordem de execução das procedures é inversa, a última procedure
  ///  adicionada ao Defer será a primeira a ser executada;
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

