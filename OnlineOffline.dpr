program OnlineOffline;

uses
  Vcl.Forms,
  MainU in 'MainU.pas' {MainForm},
  OnlineOfflineU in 'OnlineOfflineU.pas',
  System.MulticastEventU in 'System.MulticastEventU.pas',
  OnlineTesterFormU in 'OnlineTesterFormU.pas' {OnlineTesterForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
