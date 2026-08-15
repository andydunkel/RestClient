#define AppVersion '1.0.0'
#define AppName 'DA-RestClient'
#define AppCompany 'Dunkel & Iwer GbR'


[Files]
DestDir: {app}; Source: ..\src\out\*; Flags: recursesubdirs overwritereadonly ignoreversion replacesameversion
Source: ..\demo\*; DestDir: {app}\demo; Flags: recursesubdirs createallsubdirs overwritereadonly ignoreversion replacesameversion

[Icons]
Name: {group}\{#AppName}; Filename: {app}\restclient.exe; WorkingDir: {app}; IconFilename: {app}\restclient.exe; IconIndex: 0; Languages: 

Name: {group}\Deinstallieren; Filename: {uninstallexe}; Languages: en
Name: {group}\Uninstall; Filename: {uninstallexe}; Languages: de

[Run]
Filename: {app}\restclient.exe; WorkingDir: {app}; Flags: nowait postinstall; Description: {#AppName} starten

[Setup]
AppCopyright=Dunkel & Iwer GbR
AppName={#AppName}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={pf}\DA-Software\{#AppName}
ShowLanguageDialog=yes
AppID={{F73EE3CE-621D-4BAD-A3E1-F8F99550BB24}
VersionInfoVersion={#AppVersion}
VersionInfoCompany=Dunkel & Iwer GbR
VersionInfoDescription={#AppName}
LanguageDetectionMethod=uilanguage
DefaultGroupName=DA-Software\{#AppName}
ShowUndisplayableLanguages=false
OutputBaseFilename=restclient
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
AppPublisher=Dunkel & Iwer GbR
AppPublisherURL=https://www.da-software.net
AppSupportURL=https://www.da-software.net
AppUpdatesURL=https://www.da-software.net
;WizardImageFile=Icon_inst.bmp
;WizardSmallImageFile=Icon_inst_small.bmp
ChangesAssociations=true
;SignTool=kSign /d $qDA-FormMaker$q /du $qhttp://www.da-software$q /v $f
;SignedUninstaller=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[UninstallDelete]
Name: {app}; Type: filesandordirs

[Code]
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{F73EE3CE-621D-4BAD-A3E1-F8F99550BB24}_is1';
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;


/////////////////////////////////////////////////////////////////////
function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;


/////////////////////////////////////////////////////////////////////
function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
// Return Values:
// 1 - uninstall string is empty
// 2 - error executing the UnInstallString
// 3 - successfully executed the UnInstallString

  // default return value
  Result := 0;

  // get the uninstall string of the old app
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;

/////////////////////////////////////////////////////////////////////
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) then
  begin
    if (IsUpgrade()) then
    begin
      UnInstallOldVersion();
      Sleep(2000);
    end;
  end;
end;
