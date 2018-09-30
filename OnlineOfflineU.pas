unit OnlineOfflineU;

interface

uses
  System.Threading, System.Generics.Collections, System.MulticastEventU, idHTTP;

{$M+,O+}
{$IFOPT O-}
{$MESSAGE Fatal 'Optimization _must_ be turned on for this unit to work!'}
{$ENDIF}
{$HINTS OFF}

// Hints off in order for hiding message;
// [dcc32 Hint] OnlineOfflineU.pas(29): H2269 Overriding virtual method 'TOnlineOffline.Destroy' has lower visibility (private) than base class 'TThread' (public)
type
  TOnlineState = (Offline, Online);
  TStateChanged = procedure(const NewState: TOnlineState) of object;

  iStateChanged = interface
    ['{47BF0544-238C-4721-A847-ED03C2F77113}']
    procedure OnStateChanged(const NewState: TOnlineState);
  end;

  TMulticastStateChangedEvent = TMulticastEvent<TStateChanged>;

  TOnlineOffline = class
  private const
    DestinationSite = 'http://www.google.com';
    class var FInstance: TOnlineOffline;

  private
    FidHTTP: TIdHTTP;
    FScanningInterval: Integer;
    FOnlineState: TOnlineState;
    FStateChangedNotifiers: TMulticastStateChangedEvent;
    FTask: ITask;
    FTerminated: Boolean;

    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure CheckState(aForceNotify: Boolean = false);
    procedure DoNotify;
    procedure SetOnlineState(const Value: TOnlineState);
    procedure StartTask;
    procedure SetScanningInterval(const Value: Integer);
  public
    class destructor Destroy;
    class function Instance: TOnlineOffline;
    procedure Start;
    procedure Stop;
  published
    property ScanningInterval: Integer read FScanningInterval write SetScanningInterval;
    property OnlineState: TOnlineState read FOnlineState write SetOnlineState;
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
  FOnlineState := TOnlineState.Online;
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
  FreeAndNil(FInstance);
end;

procedure TOnlineOffline.CheckState(aForceNotify: Boolean = false);
var
  NewState: TOnlineState;
begin
  try
    FidHTTP.Get(DestinationSite);
    NewState := TOnlineState.Online;
  except
    NewState := TOnlineState.Offline;
  end;

  if aForceNotify or (NewState <> FOnlineState) then
  begin
    FOnlineState := NewState;
    DoNotify;
  end;
end;

procedure TOnlineOffline.DoNotify;
begin
  TThread.Queue(TThread.Current,
    procedure
    begin
      FStateChangedNotifiers.Invoke(FOnlineState);
    end);
end;

class function TOnlineOffline.Instance: TOnlineOffline;
begin
  if FInstance = nil then
    FInstance := TOnlineOffline.Create;
  Result := FInstance;
end;

procedure TOnlineOffline.SetOnlineState(const Value: TOnlineState);
begin
  FOnlineState := Value;
  DoNotify;
end;

procedure TOnlineOffline.SetScanningInterval(const Value: Integer);
begin
  FScanningInterval := Value;
  StartTask;
end;

procedure TOnlineOffline.Start;
begin
  StartTask;
end;

procedure TOnlineOffline.StartTask;
begin
  Stop;
  FTerminated := false;
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
      until (Terminated) or (Counter = 2);

      if Terminated then
        exit;

      CheckState(True);

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
