$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependencies failed' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analyzer failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
flutter build web
if ($LASTEXITCODE -ne 0) { throw 'Web build failed' }
Write-Host 'All checks passed.'
