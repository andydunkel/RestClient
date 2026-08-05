unit aboutdlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  FileInfo, Windows;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    ImageIcon: TImage;
    LabelAppName: TLabel;
    LabelVersion: TLabel;
    LabelCopyright: TLabel;
    LabelURL: TLabel;
    LabelFreeware: TLabel;
    ButtonClose: TButton;
    PanelMain: TPanel;
    PanelLeft: TPanel;
    PanelRight: TPanel;
    PanelBottom: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
  end;

implementation

{$R *.lfm}

procedure TAboutForm.FormCreate(Sender: TObject);
var
  Info: TFileVersionInfo;
begin
  ImageIcon.Picture.Icon.Assign(Application.Icon);
  try
    Info := TFileVersionInfo.Create(nil);
    try
      Info.FileName := Application.ExeName;
      Info.ReadFileInfo;
      LabelVersion.Caption := 'Version ' + Info.VersionStrings.Values['FileVersion'];
    finally
      Info.Free;
    end;
  except
    LabelVersion.Caption := '';
  end;
end;

procedure TAboutForm.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

end.
