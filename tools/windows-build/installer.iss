; Windows installer of ESIBD Explorer (this fork), compiled with Inno Setup 6 by installer.sh.
; installer.sh defines AppVersion, NumericVersion, Dist (the PyInstaller output), Repo and OutputDir.
;
; Installs for all users in Program Files (administrator rights), with shortcuts in the Start menu and,
; optionally, on the desktop. Settings, configuration and data are stored outside the program folder:
; installing, updating and uninstalling keep them. An ESIBD Explorer installed by an earlier installer
; (InstallForge, as for 1.0.2) is uninstalled first, after confirmation.

#ifndef AppVersion
  #error Define AppVersion, NumericVersion, Dist, Repo and OutputDir: run installer.sh
#endif
#define AppGuid "CA73038C-FC31-45C1-9CDE-EAD2AF4DF42E"

[Setup]
AppId={{{#AppGuid}}
AppName=ESIBD Explorer
AppVersion={#AppVersion}
AppVerName=ESIBD Explorer {#AppVersion}
AppPublisher=ESIBD Lab
AppPublisherURL=https://github.com/odurif0/ESIBD-Explorer
AppSupportURL=https://esibd-explorer.readthedocs.io
AppUpdatesURL=https://github.com/odurif0/ESIBD-Explorer/releases
VersionInfoVersion={#NumericVersion}
DefaultDirName={autopf}\ESIBD Lab\ESIBD Explorer
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
LicenseFile={#Repo}\LICENSE
SetupIconFile={#Repo}\esibd\media\ESIBD_Explorer.ico
UninstallDisplayIcon={app}\ESIBD Explorer.exe
UninstallDisplayName=ESIBD Explorer {#AppVersion}
OutputDir={#OutputDir}
OutputBaseFilename=ESIBD-Explorer-{#AppVersion}-setup
Compression=lzma2/normal
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; Files of an earlier version that this one no longer has would stay otherwise.
Type: filesandordirs; Name: "{app}\_internal"

[Files]
Source: "{#Dist}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\ESIBD Lab\ESIBD Explorer"; Filename: "{app}\ESIBD Explorer.exe"
Name: "{autodesktop}\ESIBD Explorer"; Filename: "{app}\ESIBD Explorer.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ESIBD Explorer.exe"; Description: "{cm:LaunchProgram,ESIBD Explorer}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Folders Explorer's libraries create at run time (QtWebEngine locales), not listed in the install log.
Type: filesandordirs; Name: "{app}\_internal"

[Code]
const
  UninstallRoot = 'Software\Microsoft\Windows\CurrentVersion\Uninstall';
  OwnKey = '{{#AppGuid}}_is1';

// An ESIBD Explorer installed by another installer: its uninstall entry.
function EarlierInstallation(var RootKey: Integer; var SubKey, DisplayName, UninstallString: String): Boolean;
var
  Roots: array[0..2] of Integer;
  Names: TArrayOfString;
  I, J: Integer;
begin
  Result := False;
  Roots[0] := HKLM64;
  Roots[1] := HKLM32;
  Roots[2] := HKCU;
  for I := 0 to 2 do
    if RegGetSubkeyNames(Roots[I], UninstallRoot, Names) then
      for J := 0 to GetArrayLength(Names) - 1 do
        if (CompareText(Names[J], OwnKey) <> 0)
          and RegQueryStringValue(Roots[I], UninstallRoot + '\' + Names[J], 'DisplayName', DisplayName)
          and (Pos('ESIBD Explorer', DisplayName) = 1)
          and RegQueryStringValue(Roots[I], UninstallRoot + '\' + Names[J], 'UninstallString', UninstallString) then
        begin
          RootKey := Roots[I];
          SubKey := UninstallRoot + '\' + Names[J];
          Result := True;
          Exit;
        end;
end;

// "C:\path\Uninstall.exe" /args, or C:\path\Uninstall.exe /args: the program and its arguments.
procedure SplitCommand(Command: String; var Exe, Params: String);
var
  I: Integer;
begin
  Command := Trim(Command);
  Params := '';
  if Copy(Command, 1, 1) = '"' then
  begin
    Delete(Command, 1, 1);
    I := Pos('"', Command);
    Exe := Copy(Command, 1, I - 1);
    Params := Trim(Copy(Command, I + 1, Length(Command)));
  end
  else
  begin
    Exe := Command;
    I := Pos('.exe ', Lowercase(Command));
    if I > 0 then
    begin
      Exe := Copy(Command, 1, I + 3);
      Params := Trim(Copy(Command, I + 5, Length(Command)));
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  RootKey, ResultCode, Waited: Integer;
  SubKey, DisplayName, UninstallString, Exe, Params: String;
begin
  Result := '';
  if not EarlierInstallation(RootKey, SubKey, DisplayName, UninstallString) then
    Exit;
  if not WizardSilent() then
    if MsgBox(DisplayName + ' is installed by an earlier installer. It is uninstalled first; ' +
              'its settings, configuration and data are kept.', mbConfirmation, MB_OKCANCEL) <> IDOK then
    begin
      Result := 'Uninstall ' + DisplayName + ' first, or let this setup do it.';
      Exit;
    end;
  SplitCommand(UninstallString, Exe, Params);
  Log('Uninstalling the earlier ' + DisplayName + ': ' + UninstallString);
  if not Exec(Exe, Params, '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
  begin
    Result := 'The uninstaller of ' + DisplayName + ' did not start: ' + SysErrorMessage(ResultCode);
    Exit;
  end;
  // Some uninstallers go on in a copy of themselves: wait until the entry is gone.
  Waited := 0;
  while RegKeyExists(RootKey, SubKey) do
    if WizardSilent() then
    begin
      if Waited >= 120000 then
        Break;
      Sleep(1000);
      Waited := Waited + 1000;
    end
    else if MsgBox('Finish uninstalling ' + DisplayName + ', then click OK.', mbInformation, MB_OKCANCEL) <> IDOK then
      Break;
  if RegKeyExists(RootKey, SubKey) then
    Result := DisplayName + ' is still installed. Uninstall it in Windows Settings, Apps, then run this setup again.';
end;
