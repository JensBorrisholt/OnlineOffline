unit System.MulticastEventU;

(*
  Credit to ALLEN, and his blogpost Multicast events using generics (https://community.embarcadero.com/blogs/entry/multicast-events-using-generics-38865)
  This is mainly his code. There have only been added support for 64 bit.
*)

interface

uses
  Classes, SysUtils, Generics.Collections, ObjAuto, TypInfo;

{$IFNDEF MSWINDOWS}
{$MESSAGE Fatal 'WINDOWS ONLY!'}
{$ENDIF}

{$O+}
{$IFOPT O-}
{$MESSAGE Fatal 'Optimization _must_ be turned on for this unit to work!'}
{$ENDIF}

type
  TMultiCastEvent = class
  strict private
  type
    TEvent = procedure of object;
  strict private
    FHandlers: array of TMethod;
    FInternalDispatcher: TMethod; // this class needs to keep it's own reference for cleanup later
    procedure InternalInvoke(Params: PParameters; StackSize: Integer);
    procedure InternalInvokeAMethod(const aMethod: TMethod; const aParams: PParameters; aStackSize: Integer);
    procedure ReleaseInternalDispatcher;
    procedure SetDispatcher(var aMethod: TMethod; aTypeData: PTypeData);
  protected
    procedure InternalAdd;
    procedure InternalSetDispatcher;
  public
    constructor Create; virtual;
    procedure BeforeDestruction; override;
    procedure Add(const aEvent: TEvent); overload;
  end;

  TMultiCastEvent<T> = class(TMultiCastEvent)
  strict private
    FInvoke: T;
    procedure SetEventDispatcher(var ADispatcher: T; aTypeData: PTypeData);
  public
    constructor Create; overload; override;
    constructor Create(aEvents: array of T); reintroduce; overload;
    procedure Add(const aMethod: T); overload;
    property Invoke: T read FInvoke;
  end;

implementation

procedure TMultiCastEvent.Add(const aEvent: TEvent);
begin
  FHandlers := FHandlers + [TMethod(aEvent)];
end;

procedure TMultiCastEvent.SetDispatcher(var aMethod: TMethod; aTypeData: PTypeData);
begin
  ReleaseInternalDispatcher;
  FInternalDispatcher := CreateMethodPointer(InternalInvoke, aTypeData);
  aMethod := FInternalDispatcher;
end;

procedure TMultiCastEvent.BeforeDestruction;
begin
  inherited;
  ReleaseInternalDispatcher;
end;

constructor TMultiCastEvent.Create;
begin
  inherited;
  FHandlers := [];
end;

procedure TMultiCastEvent.InternalAdd;
asm
  {$IFDEF Win32}
  xchg  [esp],eax
  pop   eax
  {$IFOPT o-}
  pop   ecx
  {$IFEND}
  pop   ebp
  jmp   Add
  {$IFEND}
  {$IFDEF Win64}
  xchg  [rsp],rax
  pop   rax
  lea   rsp,[rbp+$20]
  pop   rbp
  jmp   Add
  {$IFEND}
end;

procedure TMultiCastEvent.InternalInvoke(Params: PParameters; StackSize: Integer);
var
  M: TMethod;
begin
  for M in FHandlers do
    if Assigned(M.Code) then
      InternalInvokeAMethod(M, Params, StackSize);
end;

procedure TMultiCastEvent.InternalInvokeAMethod(const aMethod: TMethod; const aParams: PParameters; aStackSize: Integer);
var
  Method_Code: Pointer;
  Method_Data: Pointer;
  Method_Params: PParameters;
  Params_StackSize: Integer;
{$IFDEF Win32}
  asm
    // store aMethod.Code
    mov eax, aMethod.Code
    mov Method_Code, eax

    // store aMethod.Data
    mov eax, aMethod.Data
    mov Method_Data, eax

    // store aParams
    mov eax, aParams
    mov Method_Params, eax

    // store aStackSize
    mov eax, aStackSize
    mov Params_StackSize, eax

    // Check to see if there is anything in the TParameters.Stack
    cmp Params_StackSize, 0
    jle @InvokeMethod

    // Parameters.Stack has data, allocate a space and move data over.
    // The data are parameters pass to event handler
    sub esp, Params_StackSize     // Allocate storage spaces
    mov eax, Method_Params        // source
    lea eax, [eax].TParameters.Stack
    mov edx, esp                  // destination
    mov ecx, Params_StackSize     // count
    call System.Move

  @InvokeMethod:

    // Load parameters to rdx (1st), r8 (2nd) and r9 (3rd).
    // 4th parameters shall loaded in last step
    mov eax, Method_Params
    mov edx, [eax].TParameters.Registers.DWORD[0] // 1st parameter
    mov ecx, [eax].TParameters.Registers.DWORD[4] // 2nd parameter

    // EAX is always "Self", move TMethod.Data to the register
    mov eax, Method_Data

    // Call method
    call Method_Code
end;
{$IFEND}
{$IFDEF win64}
asm
  // store aMethod.Code
  mov rax, aMethod.Code
  mov Method_Code, rax

  // store aMethod.Data
  mov rax, aMethod.Data
  mov Method_Data, rax

  // store aParams
  mov rax, aParams
  mov Method_Params, rax

  // store aStackSize
  mov Params_StackSize, aStackSize

  // Check to see if there is anything in the TParameters.Stack
  cmp Params_StackSize, 0
  jle @InvokeMethod

  // Parameters.Stack has data, allocate a space and move data over.
  // The data are parameters pass to event handler
  sub esp, Params_StackSize   // Allocate storage spaces
  mov rcx, Method_Params      // source
  lea rcx, [rcx].TParameters.Stack
  mov rdx, rsp                // destination
  mov r8d, Params_StackSize   // count
  call System.Move

@InvokeMethod:

  // Load parameters to rdx (1st), r8 (2nd) and r9 (3rd).
  // 4th parameters shall loaded in last step
  mov rax, Method_Params
  mov rdx, [rax].TParameters.Stack.QWORD[$08]  // 1st parameter
  mov r8,  [rax].TParameters.Stack.QWORD[$10]  // 2nd parameter
  mov r9,  [rax].TParameters.Stack.QWORD[$18]  // 3rd parameter

  // RCX is always "Self", move TMethod.Data to the register
  mov rcx, Method_Data

  // Call method
  call Method_Code
end;
{$IFEND}

procedure TMultiCastEvent.InternalSetDispatcher;
asm
  {$IFDEF Win32}
  xchg  [esp],eax
  pop   eax
  {$IFOPT o-}
  mov esp,ebp{$IFEND}
  pop   ebp
  jmp   SetDispatcher
  {$IFEND}
  {$IFDEF Win64}
  xchg  [rsp],rax
  pop   rax
  lea   rsp,[rbp+$20]
  pop   rbp
  jmp   SetDispatcher
  {$IFEND}
end;

procedure TMultiCastEvent.ReleaseInternalDispatcher;
begin
  if Assigned(FInternalDispatcher.Code) and Assigned(FInternalDispatcher.Data) then
    ReleaseMethodPointer(FInternalDispatcher);
end;

procedure TMultiCastEvent<T>.Add(const aMethod: T);
begin
  InternalAdd;
end;

constructor TMultiCastEvent<T>.Create;
var
  M: PTypeInfo;
  D: PTypeData;
begin
  inherited Create;
  M := TypeInfo(T);
  D := GetTypeData(M);
  Assert(M.Kind = tkMethod, 'T must be a method pointer type');
  SetEventDispatcher(FInvoke, D);
end;

constructor TMultiCastEvent<T>.Create(aEvents: array of T);
var
  E: T;
begin
  Create;
  for E in aEvents do
    Add(E);
end;

procedure TMultiCastEvent<T>.SetEventDispatcher(var ADispatcher: T; aTypeData: PTypeData);
begin
  InternalSetDispatcher;
end;

end.
