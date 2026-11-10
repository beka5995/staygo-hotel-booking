$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
$staygoGateway = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', 'dart run tool/hotel_proxy.dart') -WorkingDirectory $PSScriptRoot -PassThru -NoNewWindow
try {
    $staygoReady = $false
    for ($attempt = 0; $attempt -lt 1200; $attempt++) {
        if ($staygoGateway.HasExited) { throw 'Gateway could not start. Check whether port 8765 is already in use.' }
        $staygoSocket = New-Object System.Net.Sockets.TcpClient
        try { $staygoSocket.Connect('127.0.0.1', 8765); $staygoReady = $true } catch {} finally { $staygoSocket.Dispose() }
        if ($staygoReady) { break }
        Start-Sleep -Milliseconds 250
    }
    if (-not $staygoReady) { throw 'Gateway did not start on port 8765' }
    flutter run -d chrome --web-port=7359 --dart-define=STAYGO_API_URL=http://127.0.0.1:8765/api
} finally {
    if (-not $staygoGateway.HasExited) { taskkill.exe /PID $staygoGateway.Id /T /F | Out-Null }
}
