# Compila Mi Evento para Windows en TU PC (sin GitHub Actions).
# Requisitos (una sola vez):
#   1. Flutter SDK (canal stable): https://docs.flutter.dev/get-started/install/windows
#   2. Visual Studio 2022 (Community, gratis) con la carga de trabajo «Desarrollo para el escritorio con C++»
#   3. Opcional, solo para el instalador: Inno Setup 6 (https://jrsoftware.org/isinfo.php)
# Uso (PowerShell, desde cualquier carpeta):   .\apps\mi_evento\windows\build-local.ps1
$ErrorActionPreference = 'Stop'
$app = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $app

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build windows --release

$rel = 'build\windows\x64\runner\Release'
foreach ($d in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item "$env:WINDIR\System32\$d" $rel -Force
}

$v = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value
New-Item -ItemType Directory -Force dist | Out-Null
Compress-Archive -Path "$rel\*" -DestinationPath "dist\MiEvento-$v-portable.zip" -Force

$iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source
if (-not $iscc) { $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" }
if (Test-Path $iscc) {
  & $iscc "/DAppVersion=$v" windows\installer\mi_evento.iss
  if ($LASTEXITCODE -ne 0) { throw 'Inno Setup falló' }
  Copy-Item "build\installer\MiEvento-Setup-$v.exe" dist\ -Force
} else {
  Write-Warning 'Inno Setup no está instalado: se omite el instalador (queda el ZIP portable).'
}
Write-Host "`nListo. Archivos en: $app\dist" -ForegroundColor Green
Get-ChildItem dist | Format-Table Name, @{n = 'MB'; e = { '{0:N1}' -f ($_.Length / 1MB) } }
Write-Host "También puedes ejecutar directamente: $app\$rel\mi_evento.exe"
