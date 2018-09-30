unit MainU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  OnlineOfflineU, OnlineTesterFormU;

{$R *.dfm}

procedure TMainForm.Button1Click(Sender: TObject);
var
  i, j, VerticalCount, HorizontalCount: Integer;
begin
  Button1.Enabled := False;
  Top := 0;
  Left := 0;

  VerticalCount := (Screen.Height - 5) div 125;
  HorizontalCount := (Screen.Width - Self.Width) div 345;

  for i := 0 to VerticalCount - 1 do
    for j := 0 to HorizontalCount - 1 do
      with TOnlineTesterForm.Create(Self) do
      begin
        Left := (Self.Left + Self.Width) + (10 + j * 345);
        Top := 5 + i * 125;
        Show;
      end;

  Button2.SetFocus;
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  if OnlineOffline.OnlineState = TOnlineState.Offline then
    OnlineOffline.OnlineState := TOnlineState.Online
  else
    OnlineOffline.OnlineState := TOnlineState.Offline;
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
  OnlineOffline.ScanningInterval := 15;
end;

end.
