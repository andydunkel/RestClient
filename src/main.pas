unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Clipbrd,
  SynEdit, fphttpclient, opensslsockets, fpjson, jsonparser;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonStart: TButton;
    ButtonPaste: TButton;
    ButtonCopy: TButton;
    PanelContent: TPanel;
    StatusBar1: TStatusBar;
    Splitter1: TSplitter;
    SynEditSend: TSynEdit;
    SynEditResult: TSynEdit;
    procedure ButtonStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonPasteClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
  private
    function BeautifyJSON(const S: string): string;
    procedure ParseAndSend;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.BeautifyJSON(const S: string): string;
var
  J: TJSONData;
begin
  Result := S;
  if Trim(S) = '' then Exit;
  try
    J := GetJSON(S);
    try
      Result := J.FormatJSON();
    finally
      J.Free;
    end;
  except
    // not valid JSON — return raw
  end;
end;

procedure TForm1.ParseAndSend;
var
  Lines, BodyLines, ResultText: TStringList;
  Client: TFPHTTPClient;
  ResponseStream, RequestBodyStream: TStringStream;
  FirstLine, Method, FullURL: string;
  Line, HeaderName, HeaderValue: string;
  i, SpacePos, ColonPos: Integer;
begin
  Lines         := TStringList.Create;
  BodyLines     := TStringList.Create;
  ResponseStream := TStringStream.Create('');
  ResultText    := TStringList.Create;
  Client        := TFPHTTPClient.Create(nil);
  try
    Lines.Text := SynEditSend.Lines.Text;

    if Lines.Count = 0 then
    begin
      SynEditResult.Lines.Text := 'Error: Empty request';
      Exit;
    end;

    // First line: METHOD /path
    FirstLine := Trim(Lines[0]);
    SpacePos  := Pos(' ', FirstLine);
    if SpacePos = 0 then
    begin
      SynEditResult.Lines.Text := 'Error: First line must be "METHOD /path"';
      Exit;
    end;
    Method  := UpperCase(Trim(Copy(FirstLine, 1, SpacePos - 1)));
    FullURL := Trim(Copy(FirstLine, SpacePos + 1, Length(FirstLine)));

    // Parse request headers (until blank line)
    i := 1;
    while (i < Lines.Count) and (Trim(Lines[i]) <> '') do
    begin
      Line      := Lines[i];
      ColonPos  := Pos(':', Line);
      if ColonPos > 0 then
      begin
        HeaderName  := Trim(Copy(Line, 1, ColonPos - 1));
        HeaderValue := Trim(Copy(Line, ColonPos + 1, Length(Line)));
        Client.AddHeader(HeaderName, HeaderValue);
      end;
      Inc(i);
    end;

    // Skip blank separator
    if (i < Lines.Count) and (Trim(Lines[i]) = '') then
      Inc(i);

    // Collect body
    while i < Lines.Count do
    begin
      BodyLines.Add(Lines[i]);
      Inc(i);
    end;

    Client.AllowRedirect := True;

    try
      if BodyLines.Count > 0 then
      begin
        RequestBodyStream    := TStringStream.Create(Trim(BodyLines.Text));
        Client.RequestBody   := RequestBodyStream;
        try
          Client.HTTPMethod(Method, FullURL, ResponseStream, []);
        finally
          Client.RequestBody := nil;
          RequestBodyStream.Free;
        end;
      end
      else
        Client.HTTPMethod(Method, FullURL, ResponseStream, []);

      // Status
      ResultText.Add(Format('HTTP %d', [Client.ResponseStatusCode]));
      ResultText.Add('');

      // Response headers
      for i := 0 to Client.ResponseHeaders.Count - 1 do
        ResultText.Add(Client.ResponseHeaders[i]);

      ResultText.Add('');
      ResultText.Add('--- Body ---');
      ResultText.Add('');
      ResultText.Add(BeautifyJSON(ResponseStream.DataString));

      StatusBar1.SimpleText := Format('HTTP %d  |  %s %s',
        [Client.ResponseStatusCode, Method, FullURL]);

    except
      on E: Exception do
      begin
        ResultText.Clear;
        ResultText.Add('Error: ' + E.Message);
        StatusBar1.SimpleText := 'Error: ' + E.Message;
      end;
    end;

    SynEditResult.Lines.Text := ResultText.Text;

  finally
    Lines.Free;
    BodyLines.Free;
    ResponseStream.Free;
    ResultText.Free;
    Client.Free;
  end;
end;

procedure TForm1.ButtonPasteClick(Sender: TObject);
begin
  SynEditSend.Lines.Text := Clipboard.AsText;
end;

procedure TForm1.ButtonCopyClick(Sender: TObject);
begin
  Clipboard.AsText := SynEditResult.Lines.Text;
  StatusBar1.SimpleText := 'Result copied to clipboard';
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  ParseAndSend;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption              := 'REST Client';
  SynEditResult.ReadOnly := True;
end;

end.
