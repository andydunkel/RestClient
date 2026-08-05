unit settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

const
  MAX_RECENT = 10;
  APP_NAME   = 'DA-RestClient';

type

  { TAppSettings }

  TAppSettings = class
  private
    FRecentFolders: TStringList;
    function GetSettingsPath: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    procedure AddRecentFolder(const APath: string);
    property RecentFolders: TStringList read FRecentFolders;
  end;

implementation

{ TAppSettings }

constructor TAppSettings.Create;
begin
  FRecentFolders := TStringList.Create;
end;

destructor TAppSettings.Destroy;
begin
  FRecentFolders.Free;
  inherited;
end;

function TAppSettings.GetSettingsPath: string;
begin
  Result := GetEnvironmentVariable('APPDATA')
    + PathDelim + APP_NAME + PathDelim + 'settings.ini';
end;

procedure TAppSettings.Load;
var
  Ini: TIniFile;
  i, Count: Integer;
  Path: string;
begin
  FRecentFolders.Clear;
  if not FileExists(GetSettingsPath) then Exit;

  Ini := TIniFile.Create(GetSettingsPath);
  try
    Count := Ini.ReadInteger('Recent', 'Count', 0);
    for i := 0 to Count - 1 do
    begin
      Path := Ini.ReadString('Recent', 'Folder' + IntToStr(i), '');
      if (Path <> '') and DirectoryExists(Path) then
        FRecentFolders.Add(Path);
    end;
  finally
    Ini.Free;
  end;
end;

procedure TAppSettings.Save;
var
  Ini: TIniFile;
  Dir: string;
  i: Integer;
begin
  Dir := ExtractFileDir(GetSettingsPath);
  if not DirectoryExists(Dir) then
    ForceDirectories(Dir);

  Ini := TIniFile.Create(GetSettingsPath);
  try
    Ini.WriteInteger('Recent', 'Count', FRecentFolders.Count);
    for i := 0 to FRecentFolders.Count - 1 do
      Ini.WriteString('Recent', 'Folder' + IntToStr(i), FRecentFolders[i]);
  finally
    Ini.Free;
  end;
end;

procedure TAppSettings.AddRecentFolder(const APath: string);
var
  Idx: Integer;
begin
  Idx := FRecentFolders.IndexOf(APath);
  if Idx >= 0 then
    FRecentFolders.Delete(Idx);
  FRecentFolders.Insert(0, APath);
  while FRecentFolders.Count > MAX_RECENT do
    FRecentFolders.Delete(FRecentFolders.Count - 1);
end;

end.
