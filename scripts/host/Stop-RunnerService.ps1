#requires -Version 7.4
[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners',[ValidateRange(30,900)][int]$WaitSeconds=420,[ValidateRange(0,3600)][int]$DrainSeconds=300)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$stateDir=Join-Path $root '.local/controller'
if (-not (Test-Path -LiteralPath $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
& (Join-Path $root 'scripts/controller/Request-RunnerControllerStop.ps1') | Out-Null
function Test-StopLock([string]$Name) {
    $path=Join-Path $stateDir $Name
    if (-not (Test-Path $path)) { return $false }
    try { $probe=[IO.File]::Open($path,'Open','ReadWrite','None');$probe.Dispose();return $false }
    catch [IO.IOException] { return $true }
}
$deadline=[DateTimeOffset]::UtcNow.AddSeconds($WaitSeconds)
while ((Test-StopLock 'controller.lock') -or (Test-StopLock 'supervisor.lock')) {
    if ([DateTimeOffset]::UtcNow -ge $deadline) { throw 'Service is still draining. Stop remains requested; no jobs were forcibly terminated.' }
    Start-Sleep -Seconds 5
}
$statePath=Join-Path $stateDir 'state.json'
if (-not (Test-Path $statePath)) { Write-Output 'Stopped: no recorded runner environments.';return }
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if (@($state.slots).Count) {
    # Resume only ownership-checked teardown, even after the supervisor was interrupted.
    & (Join-Path $root 'scripts/controller/Start-RunnerController.ps1') -CleanupOnly -DrainSeconds $DrainSeconds
}
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if (@($state.slots).Count) { throw 'Cleanup remains pending: busy jobs or a cleanup failure retained environments. Memory release is blocked; retry Stop & clean after jobs/API/Docker recover.' }
Write-Output 'Stopped and cleaned: zero recorded runner environments; persistent stop prevents replenishment.'
