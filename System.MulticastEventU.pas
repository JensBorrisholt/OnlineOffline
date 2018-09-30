unit System.MulticastEventU;

interface

uses
  Classes, SysUtils, Generics.Collections, ObjAuto, TypInfo;

{$O+}
{$IFDEF MSWINDOWS}
{$IFNDEF WIN32}
{$MESSAGE Fatal 'Target platform is the native 32-bit Windows platform.'}
{$ENDIF}
{$ELSE}
{$MESSAGE Fatal 'WINDOWS ONLY!'}
{$ENDIF}

type
  // you MUST also have optimization turned on in your project options for this
  // to work! Not sure why.
{$STACKFRAMES on}
{$IFOPT O-}
{$MESSAGE Fatal 'optimisation _must_ be turned on for this unit to work!'}
{$ENDIF}
{$HINTS OFF}
  (*
    HINTS OFF in order to hide theese false positive Warnings
    [dcc32 Hint] System.MulticastEventU.pas(25): H2219 Private symbol 'Add' declared but never used
    [dcc32 Hint] System.MulticastEventU.pas(26): H2219 Private symbol 'Remove' declared but never used
    [dcc32 Hint] System.MulticastEventU.pas(27): H2219 Private symbol 'IndexOf' declared but never used

    They gets called form their respective InternalXXX methods
  *)
  TMulticastEvent = class
  strict protected
  type
    TEvent = procedure of object;
  strict private
    FHandlers: TList<TMethod>;
    FInternalDispatcher: TMethod;

    procedure InternalInvoke(Params: PParameters; StackSize: Integer);
    procedure SetDispatcher(var AMethod: TMethod; ATypeData: PTypeData);
    procedure Add(const AMethod: TEvent); overload;
    procedure Remove(const AMethod: TEvent); overload;
    function IndexOf(const AMethod: TEvent): Integer; overload;
  protected
    procedure InternalAdd;
    procedure InternalRemove;
    procedure InternalIndexOf;
    procedure InternalSetDispatcher;
  public
    constructor Create;
    destructor Destroy; override;
  end;

{$HINTS ON}

  TMulticastEvent<T> = class(TMulticastEvent)
  strict private
    FInvoke: T;
    procedure SetEventDispatcher(var ADispatcher: T; ATypeData: PTypeData);
  public
    constructor Create;
    procedure Add(const AMethod: T); overload;
    procedure Remove(const AMethod: T); overload;
    function IndexOf(const AMethod: T): Integer; overload;

    property Invoke: T read FInvoke;
  end;

implementation

{ TMulticastEvent }

procedure TMulticastEvent.Add(const AMethod: TEvent);
begin
  FHandlers.Add(TMethod(AMethod))
end;

constructor TMulticastEvent.Create;
begin
  inherited;
  FHandlers := TList<TMethod>.Create;
end;

destructor TMulticastEvent.Destroy;
begin
  ReleaseMethodPointer(FInternalDispatcher);
  FreeAndNil(FHandlers);
  inherited;
end;

function TMulticastEvent.IndexOf(const AMethod: TEvent): Integer;
begin
  result := FHandlers.IndexOf(TMethod(AMethod));
end;

procedure TMulticastEvent.InternalAdd;
asm
  XCHG  EAX,[ESP]
  POP   EAX
  POP   EBP
  JMP   Add
end;

procedure TMulticastEvent.InternalIndexOf;
asm
  XCHG  EAX,[ESP]
  POP   EAX
  POP   EBP
  JMP   IndexOf
end;

procedure TMulticastEvent.InternalInvoke(Params: PParameters; StackSize: Integer);
var
  LMethod: TMethod;
begin
  for LMethod in FHandlers do
  begin
    // Check to see if there is anything on the stack.
    if StackSize > 0 then
      asm
        // if there are items on the stack, allocate the space there and
        // move that data over.
        MOV ECX,StackSize
        SUB ESP,ECX
        MOV EDX,ESP
        MOV EAX,Params
        LEA EAX,[EAX].TParameters.Stack[8]
        CALL System.Move
      end;
    asm
      // Now we need to load up the registers. EDX and ECX may have some data
      // so load them on up.
      MOV EAX,Params
      MOV EDX,[EAX].TParameters.Registers.DWORD[0]
      MOV ECX,[EAX].TParameters.Registers.DWORD[4]
      // EAX is always "Self" and it changes on a per method pointer instance, so
      // grab it out of the method data.
      MOV EAX,LMethod.Data
      // Now we call the method. This depends on the fact that the called method
      // will clean up the stack if we did any manipulations above.
      CALL LMethod.Code
    end;
  end;
end;

procedure TMulticastEvent.InternalRemove;
asm
  XCHG  EAX,[ESP]
  POP   EAX
  POP   EBP
  JMP   Remove
end;

procedure TMulticastEvent.InternalSetDispatcher;
asm
  XCHG  EAX,[ESP]
  POP   EAX
  POP   EBP
  JMP   SetDispatcher;
end;

procedure TMulticastEvent.Remove(const AMethod: TEvent);
begin
  FHandlers.Remove(TMethod(AMethod));
end;

procedure TMulticastEvent.SetDispatcher(var AMethod: TMethod; ATypeData: PTypeData);
begin
  if Assigned(FInternalDispatcher.Code) and Assigned(FInternalDispatcher.Data) then
    ReleaseMethodPointer(FInternalDispatcher);
  FInternalDispatcher := CreateMethodPointer(InternalInvoke, ATypeData);
  AMethod := FInternalDispatcher;
end;

{ TMulticastEvent<T> }

procedure TMulticastEvent<T>.Add(const AMethod: T);
begin
  InternalAdd;
end;

constructor TMulticastEvent<T>.Create;
var
  MethInfo: PTypeInfo;
  TypeData: PTypeData;
begin
  MethInfo := TypeInfo(T);
  TypeData := GetTypeData(MethInfo);
  inherited Create;
  Assert(MethInfo.Kind = tkMethod, 'T must be a method pointer type');
  SetEventDispatcher(FInvoke, TypeData);
end;

function TMulticastEvent<T>.IndexOf(const AMethod: T): Integer;
begin
  InternalIndexOf;
end;

procedure TMulticastEvent<T>.Remove(const AMethod: T);
begin
  InternalRemove;
end;

procedure TMulticastEvent<T>.SetEventDispatcher(var ADispatcher: T; ATypeData: PTypeData);
begin
  InternalSetDispatcher;
end;

end.
