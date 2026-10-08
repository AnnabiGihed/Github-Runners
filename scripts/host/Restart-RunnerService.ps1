[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners',[ValidateRange(30,900)][int]$WaitSeconds=420)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $repoRoot 'scripts/controller/Request-RunnerControllerStop.ps1') | Out-Null
$deadline=[DateTimeOffset]::UtcNow.AddSeconds($WaitSeconds)
do {
    $service=& (Join-Path $PSScriptRoot 'Test-RunnerService.ps1') -TaskName $TaskName
    # The stopping supervisor intentionally stays alive while busy jobs remain.
    # Resume as soon as the controller releases its lock after bounded drain;
    # the same supervisor can then reconcile busy state with the new config.
    if (-not $service.ControllerLockHeld -and ($service.RecordedSlots -gt 0 -or -not $service.SupervisorLockHeld)) {
        try {
            & (Join-Path $PSScriptRoot 'Start-RunnerService.ps1') -TaskName $TaskName -Resume
            Write-Output 'Graceful service restart requested; busy environments retained for reconciliation.'
            return
        } catch [IO.IOException] {
            # A cleanup retry raced lock acquisition. Keep the stop and retry.
        }
    }
    Start-Sleep -Seconds 5
} while ([DateTimeOffset]::UtcNow -lt $deadline)
throw 'Controller has not released its lock; stop request retained. After drain, explicitly Start / resume.'
