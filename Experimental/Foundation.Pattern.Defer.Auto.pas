unit Foundation.Pattern.Defer.Auto;

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
  WinApi.Windows,
  Foundation.Pattern.Defer;

type
  IDeferrer = Foundation.Pattern.Defer.IDeferrer;
  EDefer    = Foundation.Pattern.Defer.EDefer;

function Defer(Proc: TProc; Level: Integer = 2): IDeferrer;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  {$IFDEF CPUX86}Foundation.Vendor.JclDebug{$ELSE}JclDebug{$ENDIF};

type
  TDeferrerEx = class(TDeferrer)
  strict private
    FKey: string;
  public
    destructor Destroy; override;
    property Key: string read FKey write FKey;
  end;

  IDeferCallerList = interface(IInterface)
    ['{25C54A83-DC5F-490E-80F7-B8B1801B5319}']
    function Get(CallerRef: Pointer; out Value: TDeferrerEx): Boolean;
    function GetCallerKey(CallerRef: Pointer): string;
    procedure Add(CallerRef: Pointer; Deferrer: TDeferrerEx);
    procedure Remove(Deferrer: TDeferrerEx);
  end;

  TDeferCallerList = class(TInterfacedObject, IDeferCallerList)
  private
    type
      TCallerList = class(TDictionary<string, TDeferrerEx>)
      end;
  private
    FList: TCallerList;
    class var Ref: TDeferCallerList;
    class var Instance: IDeferCallerList;
    class procedure CreateInstance; inline;
  public
    constructor Create;
    destructor Destroy; override;
  private
    function Get(CallerRef: Pointer; out Value: TDeferrerEx): Boolean;
    function GetCallerKey(CallerRef: Pointer): string;
    procedure Add(CallerRef: Pointer; Deferrer: TDeferrerEx);
    procedure Remove(Deferrer: TDeferrerEx);
  end;

function CallerList: IDeferCallerList;
begin
  if TDeferCallerList.Instance = nil then
  begin
    TDeferCallerList.CreateInstance;
  end;
  Result := TDeferCallerList.Instance;
end;

function Defer(Proc: TProc; Level: Integer = 2): IDeferrer;
var
  CallerRef: Pointer;
  Deferrer: TDeferrerEx;
begin
  CallerRef := Caller(Level, False);

  if CallerList.Get(CallerRef, Deferrer) then
  begin
    Result := IDeferrer(Deferrer);
    Result._Release;
    Result.Defer(Proc);
  end
  else
  begin
    Deferrer := TDeferrerEx.Create(Proc);
    CallerList.Add(CallerRef, Deferrer);
    Supports(Deferrer, IDeferrer, Result);
  end;
end;

destructor TDeferrerEx.Destroy;
begin
  CallerList.Remove(Self);
  inherited;
end;

{ TDeferCallerList }

class procedure TDeferCallerList.CreateInstance;
var
  ExchangeResult: Pointer;
  NewInstance: TDeferCallerList;
begin
  NewInstance := TDeferCallerList.Create;
  ExchangeResult := InterlockedCompareExchangePointer(
    PPointer(@TDeferCallerList.Ref)^,
    PPointer(@NewInstance)^, nil);

  if ExchangeResult = nil then
    Supports(TDeferCallerList.Ref, IDeferCallerList, TDeferCallerList.Instance)
  else
    NewInstance.Free;
end;

constructor TDeferCallerList.Create;
const
  LIST_CAPACITY = 16;
begin
  inherited Create;
  FList := TCallerList.Create(LIST_CAPACITY);
end;

destructor TDeferCallerList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TDeferCallerList.Get(CallerRef: Pointer; out Value: TDeferrerEx): Boolean;
begin
  TMonitor.Enter(Self);
  Result := FList.TryGetValue(GetCallerKey(CallerRef), Value);
  TMonitor.Exit(Self);
end;

procedure TDeferCallerList.Add(CallerRef: Pointer; Deferrer: TDeferrerEx);
begin
  TMonitor.Enter(Self);
  Deferrer.Key := CallerList.GetCallerKey(CallerRef);
  FList.Add(Deferrer.Key, Deferrer);
  TMonitor.Exit(Self);
end;

function TDeferCallerList.GetCallerKey(CallerRef: Pointer): string;
begin
  Result := IntToStr(TThread.Current.ThreadID) + '.' + IntToStr(NativeInt(CallerRef));
end;

procedure TDeferCallerList.Remove(Deferrer: TDeferrerEx);
begin
  TMonitor.Enter(Self);
  FList.Remove(Deferrer.Key);
  TMonitor.Exit(Self);
end;

end.
