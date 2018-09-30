unit OnlineTesterFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, OnlineOfflineU, Vcl.StdCtrls;

type
  TOnlineTesterForm = class(TForm, iStateChanged)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure OnStateChanged(const NewState: TState);

  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TOnlineTesterForm.FormCreate(Sender: TObject);
begin
  OnlineOffline.StateChangedNotifiers.Add(OnStateChanged);
end;

procedure TOnlineTesterForm.OnStateChanged(const NewState: TState);
const
  ColorArray : array[TState] of TColor = (clRed, clGreen);
  StrArray: array[TState] of String = ('Offline', 'Online');
begin
  Color := ColorArray[NewState];
  Label1.Caption := StrArray[NewState];
end;

end.
