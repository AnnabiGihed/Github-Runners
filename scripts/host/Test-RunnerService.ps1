[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$stateDir=Join-Path $repoRoot '.local/controller'
function Test-LockHeld([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $probe=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $probe.Dispose();return $false
    } catch [IO.IOException] { return $true }
}
$task=Get-ScheduledTask -TaskName $TaskName
$stateFile=Join-Path $stateDir 'state.json'
$state=Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
$logs=@(Get-ChildItem -LiteralPath (Join-Path $repoRoot '.local/diagnostics') -File)
$logAcl=Get-Acl -LiteralPath (Join-Path $repoRoot '.local/diagnostics')
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$privateLogs=($logAcl.AreAccessRulesProtected -and @($logAcl.Access | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ne $sid }).Count -eq 0)
[pscustomobject]@{
    TaskName=$task.TaskName
    TaskState=$task.State
    LogonType=$task.Principal.LogonType
    RunLevel=$task.Principal.RunLevel
    SupervisorLockHeld=(Test-LockHeld (Join-Path $stateDir 'supervisor.lock'))
    ControllerLockHeld=(Test-LockHeld (Join-Path $stateDir 'controller.lock'))
    StopRequested=(Test-Path -LiteralPath (Join-Path $stateDir 'stop'))
    DemandSnapshots=if ($state.PSObject.Properties['demandSnapshots']) { @($state.demandSnapshots) } else { @() }
    RecordedSlots=@($state.slots).Count
    ValidationSlots=@($state.slots | Where-Object { $_.PSObject.Properties['validation'] -and $_.validation }).Count
    StateAgeSeconds=[Math]::Round(([DateTime]::UtcNow-(Get-Item -LiteralPath $stateFile).LastWriteTimeUtc).TotalSeconds)
    DiagnosticFiles=$logs.Count
    DiagnosticBytes=($logs | Measure-Object Length -Sum).Sum
    PrivateDiagnosticDirectory=$privateLogs
}
