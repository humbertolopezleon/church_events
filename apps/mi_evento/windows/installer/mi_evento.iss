; Instalador de Mi Evento para Windows 10/11 (Inno Setup 6).
; Se instala SIN permisos de administrador, solo para el usuario actual.
; Los datos (Documentos\MiEvento) NO se borran al desinstalar.
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{7B8E6C0A-4F1D-4C57-9A55-2E7F3B1D9C41}
AppName=Mi Evento
AppVersion={#AppVersion}
AppPublisher=Mi Evento
DefaultDirName={autopf}\Mi Evento
DefaultGroupName=Mi Evento
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\build\installer
OutputBaseFilename=MiEvento-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName=Mi Evento
SetupIconFile=..\runner\resources\app_icon.ico

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el Escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Mi Evento"; Filename: "{app}\mi_evento.exe"
Name: "{autodesktop}\Mi Evento"; Filename: "{app}\mi_evento.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\mi_evento.exe"; Description: "Abrir Mi Evento"; Flags: nowait postinstall skipifsilent
