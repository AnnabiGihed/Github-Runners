[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $repoRoot
$drainDeadline=[DateTimeOffset]::UtcNow.AddMinutes(6)
do {
    $service=& (Join-Path $repoRoot 'scripts/host/Test-RunnerService.ps1') -TaskName $TaskName
    if (-not $service.StopRequested) { throw 'Request graceful stop before Docker restart validation.' }
    if ($service.RecordedSlots -eq 0 -and -not $service.ControllerLockHeld -and -not $service.SupervisorLockHeld) { break }
    Start-Sleep -Seconds 5
} while ([DateTimeOffset]::UtcNow -lt $drainDeadline)
if ($service.RecordedSlots -ne 0 -or $service.ControllerLockHeld -or $service.SupervisorLockHeld) { throw 'Drain did not finish; no Docker restart attempted.' }
$containers=& docker ps --quiet
if ($LASTEXITCODE -ne 0 -or $containers) { throw 'Docker must be available with no running containers; no unrelated workload may be interrupted.' }
$guard=[IO.File]::Open((Join-Path $repoRoot '.local/controller/controller.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$guard.Dispose()
& docker desktop stop
if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop stop failed; inspect Desktop before continuing.' }
& (Join-Path $repoRoot 'scripts/host/Start-RunnerService.ps1') -TaskName $TaskName -Resume
$deadline=[DateTimeOffset]::UtcNow.AddMinutes(6)
$ready=$false
do {
    & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready=$true;break }
    Start-Sleep -Seconds 5
} while ([DateTimeOffset]::UtcNow -lt $deadline)
if (-not $ready) { throw 'Supervisor did not restore Docker within six minutes; production start pending.' }
Write-Output 'Passed: stopped Docker Desktop with no active containers; scheduled supervisor restored the local engine.'
$deadline=[DateTimeOffset]::UtcNow.AddMinutes(3)
do {
    $pool=@(& (Join-Path $repoRoot 'scripts/controller/Test-RunnerPool.ps1'))
    if ($pool.Count -eq 4 -and @($pool | Where-Object { -not $_.Online -or -not $_.ConfiguredEphemeral -or -not $_.ResourceLimitsMatch }).Count -eq 0) { break }
    Start-Sleep -Seconds 5
} while ([DateTimeOffset]::UtcNow -lt $deadline)
if ($pool.Count -ne 4 -or @($pool | Where-Object { -not $_.Online -or -not $_.ConfiguredEphemeral -or -not $_.ResourceLimitsMatch }).Count) { throw 'Four-slot production restoration not yet verified.' }
Write-Output 'Passed: four online production runners restored with effective resource and isolation checks.'
