#requires -Version 7.4
[CmdletBinding()]
param([ValidateRange(30,900)][int]$WaitSeconds=420,[ValidateRange(0,3600)][int]$DrainSeconds=300)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $PSScriptRoot 'Stop-RunnerService.ps1') -WaitSeconds $WaitSeconds -DrainSeconds $DrainSeconds
$stateDir=Join-Path $root '.local/controller'
$supervisorLock=$null;$controllerLock=$null
try {
    $supervisorLock=[IO.File]::Open((Join-Path $stateDir 'supervisor.lock'),'OpenOrCreate','ReadWrite','None')
    $controllerLock=[IO.File]::Open((Join-Path $stateDir 'controller.lock'),'OpenOrCreate','ReadWrite','None')
    if (-not (Test-Path (Join-Path $stateDir 'stop'))) { throw 'A persistent stop is required for memory release.' }
    $statePath=Join-Path $stateDir 'state.json'
    if ((Test-Path $statePath) -and @( (Get-Content $statePath -Raw | ConvertFrom-Json).slots ).Count) { throw 'Recorded environments remain; Docker shutdown refused.' }
    $running=& docker ps --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify Docker workloads. No shutdown attempted; Docker may already be stopped.' }
    if ($running) { throw 'Other Docker containers are running. Memory release refused to avoid interrupting them.' }
    & docker desktop stop
    if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop shutdown failed; inspect Desktop. Runners remain stopped.' }
    Write-Output 'Docker Desktop stopped after clean drain. Its backend can release memory; other WSL distributions remain untouched. Exact RAM reclaimed depends on Windows/WSL.'
} finally { if ($controllerLock) { $controllerLock.Dispose() };if ($supervisorLock) { $supervisorLock.Dispose() } }
