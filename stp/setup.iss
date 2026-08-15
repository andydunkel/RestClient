#define AppVersion '1.0.0'
#define AppName 'DA-WebsiteChecker'
#define AppCompany 'Dunkel & Iwer GbR'


[Files]
DestDir: {app}; Source: ..\src\out\*; Flags: recursesubdirs overwritereadonly ignoreversion replacesameversion

[Icons]
Name: {group}\{#AppName}; Filename: {app}\websitechecker.exe; WorkingDir: {app}; IconFilename: {app}\websitechecker.exe; IconIndex: 0; Languages: 

Name: {group}\Deinstallieren; Filename: {uninstallexe}; Languages: en
Name: {group}\Uninstall; Filename: {uninstallexe}; Languages: de

[Run]
Filename: {app}\websitechecker.exe; WorkingDir: {app}; Flags: nowait postinstall; Description: {#AppName} starten

[Setup]
AppCopyright=Dunkel & Iwer GbR
AppName={#AppName}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={pf}\DA-Software\{#AppName}
ShowLanguageDialog=yes
AppID={{9B2293B5-B101-492C-8A52-63ED16AA2195}
VersionInfoVersion={#AppVersion}
VersionInfoCompany=Dunkel & Iwer GbR
VersionInfoDescription={#AppName}
LanguageDetectionMethod=uilanguage
DefaultGroupName=DA-Software\{#AppName}
ShowUndisplayableLanguages=false
OutputBaseFilename=websitechecker
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

[Tasks]
; Wizard checkbox for autostart (unchecked by default)
Name: "autostart_reg"; \
    Description: "{cm:AutoStartTaskDesc}"; \
    GroupDescription: "{cm:StartupOptions}"; \
    Flags: unchecked

[CustomMessages]
; Text for the checkbox (EN/DE)
en.StartupOptions=Startup options:
de.StartupOptions=Startoptionen:

en.AutoStartTaskDesc=Start {#AppName} with Windows
de.AutoStartTaskDesc={#AppName} zusammen mit Windows starten


[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Registry]
; Per-user autorun entry (removed automatically on uninstall)
Root: HKCU; \
    Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
    ValueType: string; \
    ValueName: "{#AppName}"; \
    ValueData: """{app}\websitechecker.exe"""; \
    Flags: uninsdeletevalue; \
    Tasks: autostart_reg

[UninstallDelete]
Name: {app}; Type: filesandordirs

[Code]
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{9B2293B5-B101-492C-8A52-63ED16AA2195}_is1';
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