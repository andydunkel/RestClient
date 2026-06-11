unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  SynEdit;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonStart: TButton;
    EditUrl: TEdit;
    LabelURL: TLabel;
    PanelContent: TPanel;
    Splitter1: TSplitter;
    SynEditSend: TSynEdit;
    SynEditResult: TSynEdit;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

