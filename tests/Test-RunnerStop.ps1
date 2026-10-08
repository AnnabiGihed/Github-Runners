#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$fixture=Join-Path $root ('.local/tests/stop-'+[guid]::NewGuid().ToString('N'))
function Assert([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
$script:dockerFixture=@{OtherContainer=$false;DesktopStopped=$false}
function docker {
    $global:LASTEXITCODE=0
    if ($args[0] -eq 'ps') { if ($dockerFixture.OtherContainer) { 'unrelated-fixture' };return }
    if ($args[0] -eq 'desktop' -and $args[1] -eq 'stop') { $dockerFixture.DesktopStopped=$true;return }
    throw 'Unexpected Docker mutation in fixture.'
}
try {
    foreach ($dir in @('scripts/host','scripts/controller','.local/controller')) { New-Item -ItemType Directory -Path (Join-Path $fixture $dir) -Force | Out-Null }
    foreach ($file in @('scripts/host/Stop-RunnerService.ps1','scripts/host/Release-RunnerMemory.ps1','scripts/controller/Request-RunnerControllerStop.ps1','scripts/controller/RunnerDiagnostics.psm1')) { Copy-Item (Join-Path $root $file) (Join-Path $fixture $file) }
    $statePath=Join-Path $fixture '.local/controller/state.json'
    $stopPath=Join-Path $fixture '.local/controller/stop'
    $mockController=Join-Path $fixture 'scripts/controller/Start-RunnerController.ps1'
    @'
param($ConfigPath,[switch]$CleanupOnly,[switch]$Continuous,$DrainSeconds)
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $CleanupOnly -or $Continuous) { throw 'Fixture must only receive cleanup mode.' }
if (-not (Test-Path (Join-Path $root '.local/retain'))) { '{"slots":[]}' | Set-Content (Join-Path $root '.local/controller/state.json') }
'@ | Set-Content $mockController
    '{"slots":[{"name":"stale-fixture"}]}' | Set-Content $statePath
    & (Join-Path $fixture 'scripts/host/Stop-RunnerService.ps1') -DrainSeconds 0 | Out-Null
    Assert (Test-Path $stopPath) 'Stop did not persist.'
    Assert (@((Get-Content $statePath -Raw | ConvertFrom-Json).slots).Count -eq 0) 'Interrupted-supervisor cleanup not invoked.'
    '{"slots":[{"name":"busy-fixture"}]}' | Set-Content $statePath
    New-Item (Join-Path $fixture '.local/retain') -ItemType File | Out-Null
    $rejected=$false
    try { & (Join-Path $fixture 'scripts/host/Release-RunnerMemory.ps1') -DrainSeconds 0 | Out-Null } catch { $rejected=$true }
    Assert ($rejected -and -not $dockerFixture.DesktopStopped) 'Retained job did not block shutdown.'
    Remove-Item (Join-Path $fixture '.local/retain')
    '{"slots":[]}' | Set-Content $statePath
    $dockerFixture.OtherContainer=$true;$rejected=$false
    try { & (Join-Path $fixture 'scripts/host/Release-RunnerMemory.ps1') -DrainSeconds 0 | Out-Null } catch { $rejected=$true }
    Assert ($rejected -and -not $dockerFixture.DesktopStopped) 'Unrelated container did not block shutdown.'
    $dockerFixture.OtherContainer=$false
    & (Join-Path $fixture 'scripts/host/Release-RunnerMemory.ps1') -DrainSeconds 0 | Out-Null
    Assert $dockerFixture.DesktopStopped 'Clean empty engine did not request Desktop stop.'
    # A stopping supervisor must keep retrying teardown rather than replenish or exit with a busy slot.
    @'
param($ConfigPath,[switch]$CleanupOnly,[switch]$Continuous,$DrainSeconds)
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $CleanupOnly -or $Continuous) { throw 'Stopped supervisor selected provisioning.' }
$path=Join-Path $root '.local/retry-count'
$count=if (Test-Path $path) { [int](Get-Content $path) } else { 0 }
$count++;Set-Content $path $count
if ($count -ge 2) { '{"slots":[]}' | Set-Content (Join-Path $root '.local/controller/state.json') }
'@ | Set-Content $mockController
    '{"slots":[{"name":"busy-then-finished-fixture"}]}' | Set-Content $statePath
    $supervisor=Join-Path $fixture 'scripts/controller/Start-RunnerSupervisor.ps1'
    $text=[IO.File]::ReadAllText((Join-Path $root 'scripts/controller/Start-RunnerSupervisor.ps1'))
    $text=$text.Replace('Set-Location -LiteralPath $repoRoot',"Set-Location -LiteralPath `$repoRoot`nfunction docker { `$global:LASTEXITCODE=0; 'fixture-engine' }")
    $text=$text.Replace('Start-Sleep -Seconds 30','Start-Sleep -Milliseconds 1')
    [IO.File]::WriteAllText($supervisor,$text)
    & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File $supervisor
    Assert ($LASTEXITCODE -eq 0) 'Stopped supervisor fixture failed.'
    Assert ([int](Get-Content (Join-Path $fixture '.local/retry-count')) -eq 2) 'Supervisor did not retry retained environment cleanup.'
    Assert (@((Get-Content $statePath -Raw | ConvertFrom-Json).slots).Count -eq 0) 'Supervisor exited with completed environment retained.'
    'Stop tests passed: interrupted-controller teardown, busy/unrelated shutdown guards, clean-engine shutdown request and stopped-supervisor cleanup retries. Docker/API/service effects were mocked.'
} finally {
    $resolved=[IO.Path]::GetFullPath($fixture)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup outside workspace refused.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
