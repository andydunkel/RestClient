unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Menus, ActnList, StdCtrls, Clipbrd,
  SynEdit, fphttpclient, opensslsockets, fpjson, jsonparser,
  settings, aboutdlg;

type

  { TForm1 }

  TForm1 = class(TForm)
    actExit: TAction;
    ActionList1: TActionList;
    actOpenFolder: TAction;
    actRefresh: TAction;
    actSend: TAction;
    actNewFile: TAction;
    actCopyResult: TAction;
    actAbout: TAction;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuItemOpenFolder: TMenuItem;
    MenuItemNewFile: TMenuItem;
    MenuItemRecent: TMenuItem;
    MenuItemSep1: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuView: TMenuItem;
    MenuItemRefresh: TMenuItem;
    MenuRequest: TMenuItem;
    MenuItemSend: TMenuItem;
    MenuItemCopyResult: TMenuItem;
    MenuHelp: TMenuItem;
    MenuItemAbout: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButtonOpenFolder: TToolButton;
    ToolButtonRefresh: TToolButton;
    ToolButtonSep1: TToolButton;
    ToolButtonNewFile: TToolButton;
    ToolButtonSep2: TToolButton;
    ToolButtonSend: TToolButton;
    ToolButtonCopyResult: TToolButton;
    PanelLeft: TPanel;
    TreeView1: TTreeView;
    PopupMenuTree: TPopupMenu;
    PopupItemNewFile: TMenuItem;
    PopupItemRefresh: TMenuItem;
    SplitterMain: TSplitter;
    PanelRight: TPanel;
    SynEditSend: TSynEdit;
    SplitterRight: TSplitter;
    SynEditResult: TSynEdit;
    StatusBar1: TStatusBar;
    procedure actExitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actOpenFolderExecute(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actSendExecute(Sender: TObject);
    procedure actNewFileExecute(Sender: TObject);
    procedure actCopyResultExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure MenuItemExitClick(Sender: TObject);
  private
    FProjectDir: string;
    FCurrentFile: string;
    FSettings: TAppSettings;
    procedure LoadTree;
    procedure FillNode(ParentNode: TTreeNode; const Dir: string);
    procedure SaveCurrentFile;
    procedure OpenFile(const APath: string);
    procedure LoadProjectDir(const ADir: string);
    procedure RebuildRecentMenu;
    procedure RecentFolderClick(Sender: TObject);
    function  BeautifyJSON(const S: string): string;
    procedure ParseAndSend;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  SynEditResult.ReadOnly := True;
  FProjectDir  := '';
  FCurrentFile := '';
  FSettings := TAppSettings.Create;
  FSettings.Load;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  RebuildRecentMenu;
  // Reopen last folder if it still exists
  if (FSettings.RecentFolders.Count > 0)
    and DirectoryExists(FSettings.RecentFolders[0]) then
    LoadProjectDir(FSettings.RecentFolders[0]);
  if FProjectDir = '' then
    Caption := APP_NAME;
end;

procedure TForm1.actExitExecute(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.FormDestroy(Sender: TObject);

  procedure FreeNodeData(Node: TTreeNode);
  var
    i: Integer;
  begin
    if Assigned(Node.Data) then
    begin
      Dispose(PString(Node.Data));
      Node.Data := nil;
    end;
    for i := 0 to Node.Count - 1 do
      FreeNodeData(Node.Items[i]);
  end;

var
  i: Integer;
begin
  for i := 0 to TreeView1.Items.Count - 1 do
    if TreeView1.Items[i].Level = 0 then
      FreeNodeData(TreeView1.Items[i]);
  FSettings.Save;
  FSettings.Free;
end;

// ── Tree ──────────────────────────────────────────────────────────────────────

procedure TForm1.FillNode(ParentNode: TTreeNode; const Dir: string);
var
  SR: TSearchRec;
  Node: TTreeNode;
  P: PString;
begin
  // Subdirectories first
  if FindFirst(Dir + '\*', faDirectory, SR) = 0 then
  try
    repeat
      if (SR.Name = '.') or (SR.Name = '..') then Continue;
      if (SR.Attr and faDirectory) = 0 then Continue;
      Node := TreeView1.Items.AddChild(ParentNode, SR.Name);
      Node.ImageIndex := 4;
      Node.SelectedIndex := 4;
      FillNode(Node, Dir + '\' + SR.Name);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;

  // .rest files
  if FindFirst(Dir + '\*.rest', faAnyFile, SR) = 0 then
  try
    repeat
      if (SR.Attr and faDirectory) <> 0 then Continue;
      Node := TreeView1.Items.AddChild(ParentNode, ChangeFileExt(SR.Name, ''));
      Node.ImageIndex := 3;
      Node.SelectedIndex := 3;
      New(P);
      P^ := Dir + '\' + SR.Name;
      Node.Data := P;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

procedure TForm1.LoadTree;
var
  RootNode: TTreeNode;

  procedure FreeAll(Node: TTreeNode);
  var i: Integer;
  begin
    if Assigned(Node.Data) then begin Dispose(PString(Node.Data)); Node.Data := nil; end;
    for i := 0 to Node.Count - 1 do FreeAll(Node.Items[i]);
  end;

var
  i: Integer;
begin
  if FProjectDir = '' then Exit;

  TreeView1.Items.BeginUpdate;
  try
    for i := 0 to TreeView1.Items.Count - 1 do
      if TreeView1.Items[i].Level = 0 then
        FreeAll(TreeView1.Items[i]);
    TreeView1.Items.Clear;

    RootNode := TreeView1.Items.Add(nil, ExtractFileName(FProjectDir));
    RootNode.ImageIndex := 4;
    RootNode.SelectedIndex := 4;
    FillNode(RootNode, FProjectDir);
    RootNode.Expand(False);
  finally
    TreeView1.Items.EndUpdate;
  end;

  actRefresh.Enabled  := True;
  actNewFile.Enabled  := True;
end;

// ── File I/O ──────────────────────────────────────────────────────────────────

procedure TForm1.SaveCurrentFile;
begin
  if FCurrentFile = '' then Exit;
  SynEditSend.Lines.SaveToFile(FCurrentFile);
end;

procedure TForm1.OpenFile(const APath: string);
begin
  if not FileExists(APath) then Exit;
  SaveCurrentFile;
  FCurrentFile := APath;
  SynEditSend.Lines.LoadFromFile(APath);
  SynEditResult.Lines.Clear;
  StatusBar1.SimpleText := APath;
  actSend.Enabled := True;
end;

// ── Actions ───────────────────────────────────────────────────────────────────

procedure TForm1.LoadProjectDir(const ADir: string);
begin
  SaveCurrentFile;
  FCurrentFile := '';
  SynEditSend.Lines.Clear;
  SynEditResult.Lines.Clear;
  FProjectDir := ADir;
  LoadTree;
  Caption := APP_NAME + ' — ' + ADir;
  StatusBar1.SimpleText := 'Opened: ' + ADir;
end;

procedure TForm1.RebuildRecentMenu;
var
  i: Integer;
  Item: TMenuItem;
begin
  while MenuItemRecent.Count > 0 do
    MenuItemRecent.Delete(0);
  if FSettings.RecentFolders.Count = 0 then
  begin
    MenuItemRecent.Enabled := False;
    Exit;
  end;
  MenuItemRecent.Enabled := True;
  for i := 0 to FSettings.RecentFolders.Count - 1 do
  begin
    Item := TMenuItem.Create(MenuItemRecent);
    Item.Caption := FSettings.RecentFolders[i];
    Item.Tag     := i;
    Item.OnClick := @RecentFolderClick;
    MenuItemRecent.Add(Item);
  end;
end;

procedure TForm1.RecentFolderClick(Sender: TObject);
var
  Path: string;
begin
  Path := TMenuItem(Sender).Caption;
  if not DirectoryExists(Path) then
  begin
    ShowMessage('Folder no longer exists:' + LineEnding + Path);
    FSettings.RecentFolders.Delete(TMenuItem(Sender).Tag);
    RebuildRecentMenu;
    Exit;
  end;
  LoadProjectDir(Path);
  FSettings.AddRecentFolder(Path);
  RebuildRecentMenu;
end;

procedure TForm1.actOpenFolderExecute(Sender: TObject);
var
  Dir: string;
begin
  Dir := FProjectDir;
  if SelectDirectory('Select REST project folder', '', Dir) then
  begin
    LoadProjectDir(Dir);
    FSettings.AddRecentFolder(Dir);
    RebuildRecentMenu;
  end;
end;

procedure TForm1.actRefreshExecute(Sender: TObject);
begin
  SaveCurrentFile;
  LoadTree;
end;

procedure TForm1.actSendExecute(Sender: TObject);
begin
  ParseAndSend;
end;

procedure TForm1.actNewFileExecute(Sender: TObject);
var
  FileName, FilePath: string;
  TargetDir: string;
  Node, N: TTreeNode;
  P: PString;
  NewNode: TTreeNode;
begin
  if FProjectDir = '' then Exit;

  // Determine target directory from selected node
  Node := TreeView1.Selected;
  if Assigned(Node) and not Assigned(Node.Data) then
    TargetDir := FProjectDir + '\' + Node.Text  // rough — use stored path for dirs
  else
    TargetDir := FProjectDir;

  // For directory nodes we need the real path — rebuild from node path
  if Assigned(Node) then
  begin
    if not Assigned(Node.Data) then
    begin
      // Build path from root
      TargetDir := '';
      N := Node;
      while Assigned(N) and (N.Level > 0) do
      begin
        if TargetDir = '' then
          TargetDir := N.Text
        else
          TargetDir := N.Text + '\' + TargetDir;
        N := N.Parent;
      end;
      TargetDir := FProjectDir + '\' + TargetDir;
    end
    else
      TargetDir := ExtractFileDir(PString(Node.Data)^);
  end
  else
    TargetDir := FProjectDir;

  FileName := '';
  if not InputQuery('New REST File', 'File name (without .rest):', FileName) then Exit;
  FileName := Trim(FileName);
  if FileName = '' then Exit;

  FilePath := TargetDir + '\' + FileName + '.rest';
  if FileExists(FilePath) then
  begin
    ShowMessage('File already exists: ' + FilePath);
    Exit;
  end;

  // Create empty file
  with TStringList.Create do
  try
    SaveToFile(FilePath);
  finally
    Free;
  end;

  // Add node to tree
  TreeView1.Items.BeginUpdate;
  try
    if Assigned(Node) and not Assigned(Node.Data) then
      NewNode := TreeView1.Items.AddChild(Node, FileName)
    else if Assigned(Node) and Assigned(Node.Data) then
      NewNode := TreeView1.Items.AddChild(Node.Parent, FileName)
    else
      NewNode := TreeView1.Items.AddChild(TreeView1.Items[0], FileName);
    New(P);
    P^ := FilePath;
    NewNode.Data := P;
  finally
    TreeView1.Items.EndUpdate;
  end;

  TreeView1.Selected := NewNode;
  OpenFile(FilePath);
end;

procedure TForm1.actAboutExecute(Sender: TObject);
var
  F: TAboutForm;
begin
  F := TAboutForm.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TForm1.actCopyResultExecute(Sender: TObject);
begin
  Clipboard.AsText := SynEditResult.Lines.Text;
  StatusBar1.SimpleText := 'Result copied to clipboard';
end;

procedure TForm1.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
    OpenFile(PString(Node.Data)^);
end;

procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  SaveCurrentFile;
  Close;
end;

// ── HTTP ──────────────────────────────────────────────────────────────────────

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
  FirstLine, Method, FullURL, Line, HeaderName, HeaderValue: string;
  i, SpacePos, ColonPos: Integer;
begin
  Lines          := TStringList.Create;
  BodyLines      := TStringList.Create;
  ResponseStream := TStringStream.Create('');
  ResultText     := TStringList.Create;
  Client         := TFPHTTPClient.Create(nil);
  try
    Lines.Text := SynEditSend.Lines.Text;
    if Lines.Count = 0 then begin SynEditResult.Lines.Text := 'Error: Empty request'; Exit; end;

    FirstLine := Trim(Lines[0]);
    SpacePos  := Pos(' ', FirstLine);
    if SpacePos = 0 then begin SynEditResult.Lines.Text := 'Error: First line must be "METHOD URL"'; Exit; end;
    Method  := UpperCase(Trim(Copy(FirstLine, 1, SpacePos - 1)));
    FullURL := Trim(Copy(FirstLine, SpacePos + 1, Length(FirstLine)));

    i := 1;
    while (i < Lines.Count) and (Trim(Lines[i]) <> '') do
    begin
      Line     := Lines[i];
      ColonPos := Pos(':', Line);
      if ColonPos > 0 then
      begin
        HeaderName  := Trim(Copy(Line, 1, ColonPos - 1));
        HeaderValue := Trim(Copy(Line, ColonPos + 1, Length(Line)));
        Client.AddHeader(HeaderName, HeaderValue);
      end;
      Inc(i);
    end;
    if (i < Lines.Count) and (Trim(Lines[i]) = '') then Inc(i);
    while i < Lines.Count do begin BodyLines.Add(Lines[i]); Inc(i); end;

    Client.AllowRedirect := True;
    try
      if BodyLines.Count > 0 then
      begin
        RequestBodyStream  := TStringStream.Create(Trim(BodyLines.Text));
        Client.RequestBody := RequestBodyStream;
        try
          Client.HTTPMethod(Method, FullURL, ResponseStream, []);
        finally
          Client.RequestBody := nil;
          RequestBodyStream.Free;
        end;
      end
      else
        Client.HTTPMethod(Method, FullURL, ResponseStream, []);

      ResultText.Add(Format('HTTP %d', [Client.ResponseStatusCode]));
      ResultText.Add('');
      for i := 0 to Client.ResponseHeaders.Count - 1 do
        ResultText.Add(Client.ResponseHeaders[i]);
      ResultText.Add('');
      ResultText.Add('--- Body ---');
      ResultText.Add('');
      ResultText.Add(BeautifyJSON(ResponseStream.DataString));
      StatusBar1.SimpleText := Format('HTTP %d  |  %s %s', [Client.ResponseStatusCode, Method, FullURL]);
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
    Lines.Free; BodyLines.Free; ResponseStream.Free; ResultText.Free; Client.Free;
  end;
end;

end.
