object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Demo'
  ClientHeight = 296
  ClientWidth = 130
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 11
    Top = 8
    Width = 105
    Height = 25
    Caption = 'Start the fun'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 11
    Top = 39
    Width = 105
    Height = 25
    Caption = 'Change State'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 11
    Top = 70
    Width = 105
    Height = 25
    Caption = 'Change interval'
    TabOrder = 2
    OnClick = Button3Click
  end
end
