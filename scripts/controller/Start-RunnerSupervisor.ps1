#requires -Version 7.4
[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location -LiteralPath $repoRoot
Import-Module (Join-Path $PSScriptRoot 'RunnerDiagnostics.psm1') -Force
$stateDir=Join-Path $repoRoot '.local/controller'
$diagnosticPath=Join-Path $repoRoot '.local/diagnostics'
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
Initialize-RunnerDiagnosticDirectory -Path $diagnosticPath
$lock=[IO.File]::Open((Join-Path $stateDir 'supervisor.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
function Write-ServiceEvent([string]$Message) {
    $path=Join-Path $diagnosticPath 'supervisor.log'
    if ((Test-Path $path) -and (Get-Item $path).Length -gt 5MB) {
        Move-Item -LiteralPath $path -Destination (Join-Path $diagnosticPath 'supervisor.1.log') -Force
    }
    Add-Content -LiteralPath $path -Value ("$([DateTimeOffset]::UtcNow.ToString('o')) "+(Protect-RunnerDiagnosticText $Message)) -Encoding utf8
    Limit-RunnerDiagnostics -Path $diagnosticPath
}
try {
    Write-ServiceEvent 'Supervisor started; continuous operation under the interactive Windows account.'
    $nextDesktopAttempt=[DateTimeOffset]::MinValue
    while ($true) {
        $stopping=Test-Path (Join-Path $stateDir 'stop')
        if ($stopping) {
            $statePath=Join-Path $stateDir 'state.json'
            if (-not (Test-Path $statePath)) { break }
            $pending=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
            if (@($pending.slots).Count -eq 0) { break }
        }
        & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            if ($stopping) {
                Write-ServiceEvent 'Stopped provisioning; cleanup awaits Docker availability. Recorded environments retained.'
                Start-Sleep -Seconds 30
                continue
            }
            $desktopPath=Join-Path $env:ProgramFiles 'Docker/Docker/Docker Desktop.exe'
            if ([DateTimeOffset]::UtcNow -ge $nextDesktopAttempt -and (Test-Path -LiteralPath $desktopPath)) {
                Start-Process -FilePath $desktopPath -WindowStyle Hidden
                $nextDesktopAttempt=[DateTimeOffset]::UtcNow.AddMinutes(5)
                Write-ServiceEvent 'Started Docker Desktop; waiting for its local engine.'
            }
            Start-Sleep -Seconds 30
            continue
        }
        $nextDesktopAttempt=[DateTimeOffset]::MinValue
        try {
            $mode=if ($stopping) { @{CleanupOnly=$true} } else { @{Continuous=$true} }
            & (Join-Path $PSScriptRoot 'Start-RunnerController.ps1') -ConfigPath $ConfigPath @mode -DrainSeconds 300 *>&1 | ForEach-Object {
                Write-ServiceEvent ([string]$_)
            }
        } catch {
            # Do not log exceptions that can include API bodies, credentials or host paths.
            Write-ServiceEvent 'Controller exited with an error; state retained, retry after 60 seconds.'
        }
        if (-not (Test-Path (Join-Path $stateDir 'stop'))) { Start-Sleep -Seconds 60 }
        elseif (Test-Path (Join-Path $stateDir 'state.json')) {
            $remaining=Get-Content (Join-Path $stateDir 'state.json') -Raw | ConvertFrom-Json
            if (@($remaining.slots).Count) { Write-ServiceEvent 'Stop requested; continuing cleanup retries without replenishment.';Start-Sleep -Seconds 30 }
        }
    }
    Write-ServiceEvent 'Supervisor stopped after persistent stop request.'
} finally { $lock.Dispose() }
