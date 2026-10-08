#requires -Version 7.4
[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json',[Parameter(Mandatory)][string]$TargetId)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'RunnerGitHub.psm1') -Force
Import-Module (Join-Path $root 'scripts/controller/RunnerDemand.psm1') -Force
$null=& (Join-Path $root 'scripts/config/Test-RunnerConfiguration.ps1') -Path $ConfigPath
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$targets=@($config.targets | Where-Object id -ceq $TargetId)
if ($targets.Count -ne 1) { throw 'Expected one configured target.' }
$target=$targets[0]
# Verify the required permissions even before demand mode is activated.
$target | Add-Member -NotePropertyName scalingMode -NotePropertyValue demand -Force
$credential=$null
try {
    $credential=Get-RunnerInstallationToken -Target $target -RepositoryRoot $root
    $queued=Get-RunnerQueueDemand -Target $target -Request {
        param($path)
        Invoke-RunnerGitHubApi -Method GET -Path $path -Token $credential.token
    }
    [pscustomobject]@{Target=$target.id;ActionsReadVerified=$true;MatchingQueuedJobs=$queued;Maximum=$target.maxRunners;Note='Bounded queue snapshot; no runners or workflows changed.'}
} finally {
    if ($credential) {
        try { $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token }
        catch { Write-Warning 'Validation token revocation pending expiration.' }
    }
    $credential=$null
}
