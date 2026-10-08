#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Status','Pool','Host','Build','Install','Start','Stop','Apply','Save','Remove','Setup')][string]$Action)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location -LiteralPath $root
Import-Module (Join-Path $PSScriptRoot 'RunnerDesktop.psm1') -Force
Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
function Test-DesktopCapacity {
    $hostInfo=& ./scripts/host/Test-RunnerHost.ps1 | ConvertFrom-Json
    $config=Get-DesktopTargets
    & ./scripts/config/Test-RunnerResources.ps1 -MaxRunners $config.hostMaxRunners -EngineCPUs $hostInfo.CPUs -EngineMemoryMiB ($hostInfo.EngineMemoryGiB*1024) | Out-Null
}
try {
    # Requests travel via stdin, never secrets or user input in shell command strings.
    $request=if ($Action -in @('Save','Remove','Setup')) { [Console]::In.ReadToEnd() | ConvertFrom-Json } else { $null }
    $output=& {
        switch ($Action) {
            Status {
                if (-not (Get-ScheduledTask -TaskName EphemeralGitHubRunners -ErrorAction SilentlyContinue)) { 'Login supervision is not installed. Use Set up & start or Install login supervision.' }
                elseif (-not (Test-Path .local/controller/state.json)) { 'Login supervision is installed; no runner state yet. Start/resume and refresh.' }
                else { & ./scripts/host/Test-RunnerService.ps1 | Format-List | Out-String }
            }
            Pool { & ./scripts/controller/Test-RunnerPool.ps1 6>&1 | Format-List | Out-String }
            Host { & ./scripts/host/Test-RunnerHost.ps1 | Format-List | Out-String }
            Build { & ./scripts/images/Build-RunnerImage.ps1 2>&1 | Out-String }
            Install { & ./scripts/host/Install-RunnerScheduledTask.ps1 }
            Start { & ./scripts/config/Test-RunnerConfiguration.ps1 -Path .local/targets.json | Out-Null; Test-DesktopCapacity; & ./scripts/host/Start-RunnerService.ps1 -Resume }
            Stop { & ./scripts/controller/Request-RunnerControllerStop.ps1; 'Drain requested. Busy jobs may remain; refresh status before removal.' }
            Apply { Test-DesktopCapacity; & ./scripts/host/Restart-RunnerService.ps1 }
            Save { Save-DesktopTarget -InputTarget $request }
            Remove { Remove-DesktopTarget -Id $request.id }
            Setup {
                & ./scripts/host/Test-RunnerHost.ps1 | Out-Null
                Save-DesktopTarget -InputTarget $request
                Test-DesktopCapacity
                & docker image inspect local/ephemeral-github-runner:dev *> $null
                if ($LASTEXITCODE -ne 0) { & ./scripts/images/Build-RunnerImage.ps1 2>&1 | Out-String }
                & ./scripts/host/Install-RunnerScheduledTask.ps1
                if (Test-Path .local/controller/state.json) { & ./scripts/host/Restart-RunnerService.ps1 }
                else { & ./scripts/host/Start-RunnerService.ps1 -Resume }
                'Setup applied. Refresh the live pool to verify registration; run smoke jobs for workload acceptance.'
            }
        }
    } 3>&1 4>&1 6>&1 | Out-String
    Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
    [Console]::Out.Write((Protect-RunnerDiagnosticText -Text $output))
} catch {
    Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
    [Console]::Error.Write((Protect-RunnerDiagnosticText -Text $_.Exception.Message))
    exit 1
}
