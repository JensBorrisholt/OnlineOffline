unit OnlineOfflineU;

interface

uses
  System.Threading, System.Generics.Collections, System.MulticastEventU, idHTTP;

{$M+}
{$O+}
{$HINTS OFF}

// Hints off inorder for hideing message;
// [dcc32 Hint] OnlineOfflineU.pas(29): H2269 Overriding virtual method 'TOnlineOffline.Destroy' has lower visibility (private) than base class 'TThread' (public)
type
  TState = (Offline, Online);
  TStateChanged = procedure(const NewState: TState) of object;

  iStateChanged = interface
    ['{47BF0544-238C-4721-A847-ED03C2F77113}']
    procedure OnStateChanged(const NewState: TState);
  end;

  TMulticastStateChangedEvent = TMulticastEvent<TStateChanged>;

  TOnlineOffline = class
  private const
    DestinationSite = 'http://www.google.com';
    class var FInstance: TOnlineOffline;

  private
    FidHTTP: TIdHTTP;
    FScanningInterval: Integer;
    FState: TState;
    FStateChangedNotifiers: TMulticastStateChangedEvent;
    FTask: ITask;
    FTerminated: Boolean;

    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure CheckState;
    procedure DoNotify;
    procedure SetState(const Value: TState);
    procedure StartTask;
  public
    class destructor Destroy;
    class function Instance: TOnlineOffline;
    procedure Start;
    procedure Stop;
  published
    property ScanningInterval: Integer read FScanningInterval write FScanningInterval;
    property State: TState read FState write SetState;
    property StateChangedNotifiers: TMulticastStateChangedEvent read FStateChangedNotifiers;
    property Terminated: Boolean read FTerminated;
  end;
{$HINTS ON}

function OnlineOffline: TOnlineOffline;

implementation

uses
  System.Classes, System.Sysutils;
{ TOnlineOffline }

function OnlineOffline: TOnlineOffline;
begin
  Result := TOnlineOffline.Instance;
end;

constructor TOnlineOffline.Create;
begin
  inherited Create;
  FScanningInterval := 10;
  FStateChangedNotifiers := TMulticastStateChangedEvent.Create;
  FState := TState.Offline;
  FidHTTP := TIdHTTP.Create(nil);
  Start;
end;

destructor TOnlineOffline.Destroy;
begin
  Stop;
  FStateChangedNotifiers.Free;
  FidHTTP.Free;
  inherited;
end;

class destructor TOnlineOffline.Destroy;
begin
  if FInstance <> nil then
    FreeAndNil(FInstance);
end;

procedure TOnlineOffline.CheckState;
var
  NewState: TState;
begin
  try
    FidHTTP.Get(DestinationSite);
    NewState := TState.Online;
  except
    NewState := TState.Offline;
  end;

  if NewState <> FState then
  begin
    FState := NewState;
    DoNotify;
  end;
end;

procedure TOnlineOffline.DoNotify;
begin
  TThread.Queue(TThread.Current,
    procedure
    begin
      FStateChangedNotifiers.Invoke(FState);
    end);
end;

class function TOnlineOffline.Instance: TOnlineOffline;
begin
  if FInstance = nil then
    FInstance := TOnlineOffline.Create;
  Result := FInstance;
end;

procedure TOnlineOffline.SetState(const Value: TState);
begin
  FState := Value;
  DoNotify;
end;

procedure TOnlineOffline.Start;
begin
  StartTask;
end;

procedure TOnlineOffline.StartTask;
begin
  FTerminated := False;
  FTask := TTask.Run(
    procedure
    var
      Counter: Integer;
    const
      InternalSleepInterval = 100;
    begin

      Counter := 0;
      repeat
        Sleep(InternalSleepInterval);
        Inc(Counter);
      until (Terminated) or (Counter = 1 * MSecsPerSec div InternalSleepInterval);

      if Terminated then
        exit;

      CheckState;

      while not Terminated do
      begin
        Counter := 0;
        repeat
          Sleep(InternalSleepInterval);
          Inc(Counter);
        until (Terminated) or (Counter = (FScanningInterval * MSecsPerSec) div InternalSleepInterval);

        if not Terminated then
          CheckState;
      end;
    end);

end;

procedure TOnlineOffline.Stop;
begin
  FTerminated := True;
  if Assigned(FTask) then
    FTask.Wait;
end;

end.
