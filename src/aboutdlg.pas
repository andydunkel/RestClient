unit aboutdlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    ImageIcon: TImage;
    LabelAppName: TLabel;
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
begin
  ImageIcon.Picture.Icon.Assign(Application.Icon);
end;

procedure TAboutForm.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

end.
