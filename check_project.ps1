$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$commands = @(
    @('pub', 'get'),
    @('analyze'),
    @('test'),
    @('build', 'web')
)
foreach ($arguments in $commands) {
    Write-Host ("flutter " + ($arguments -join ' '))
    & flutter @arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Check failed: flutter " + ($arguments -join ' '))
    }
}
Write-Host 'Dependency resolution, analyzer, tests and web build passed.'
