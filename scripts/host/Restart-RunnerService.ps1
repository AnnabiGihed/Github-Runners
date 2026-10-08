[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners',[ValidateRange(30,900)][int]$WaitSeconds=420)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $repoRoot 'scripts/controller/Request-RunnerControllerStop.ps1') | Out-Null
$deadline=[DateTimeOffset]::UtcNow.AddSeconds($WaitSeconds)
do {
    $service=& (Join-Path $PSScriptRoot 'Test-RunnerService.ps1') -TaskName $TaskName
    if (-not $service.SupervisorLockHeld -and -not $service.ControllerLockHeld) { break }
    Start-Sleep -Seconds 5
} while ([DateTimeOffset]::UtcNow -lt $deadline)
if ($service.SupervisorLockHeld -or $service.ControllerLockHeld) { throw 'Service still draining; stop request retained, restart not attempted.' }
& (Join-Path $PSScriptRoot 'Start-RunnerService.ps1') -TaskName $TaskName -Resume
Write-Output 'Graceful service restart requested; prior busy state, if any, will be preserved for reconciliation.'
