$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependencies failed' }
flutter run -d chrome --web-port=7358
