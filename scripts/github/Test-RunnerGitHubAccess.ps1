#requires -Version 7.2
[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $repoRoot 'scripts/config/Test-RunnerConfiguration.ps1') -Path $ConfigPath | Out-Null
Import-Module (Join-Path $PSScriptRoot 'RunnerGitHub.psm1') -Force
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
foreach ($target in $config.targets) {
    $credential=$null
    try {
        $credential=Get-RunnerInstallationToken -Target $target -RepositoryRoot $repoRoot
        $path=if ($target.scope -eq 'repository') { "/repos/$($target.owner)/$($target.repository)/actions/runners?per_page=1" } else { "/orgs/$($target.owner)/actions/runners?per_page=1" }
        $null=Invoke-RunnerGitHubApi -Method GET -Path $path -Token $credential.token
        [pscustomobject]@{Target=$target.id;InstallationOwnerVerified=$true;RunnerApiReadVerified=$true;RegistrationVerified=$false}
    } finally {
        if ($credential) {
            # Revoke the short-lived validation credential after use.
            try { $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token }
            catch { Write-Warning 'Validation token revocation failed; it remains valid until expiration.' }
        }
        $credential=$null
    }
}
