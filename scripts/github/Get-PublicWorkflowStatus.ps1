[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json', [string]$TargetId='personal-raidmanager', [long[]]$RunIds=@(), [ValidateRange(1,100)][int]$Count=3, [switch]$AppAuthentication)
$ErrorActionPreference='Stop'
$config=Get-Content $ConfigPath -Raw | ConvertFrom-Json
$targets=@($config.targets | Where-Object id -eq $TargetId)
if ($targets.Count -ne 1 -or $targets[0].scope -ne 'repository') { throw 'Expected a repository target.' }
$target=$targets[0]
$base="https://api.github.com/repos/$($target.owner)/$($target.repository)"
$headers=@{Accept='application/vnd.github+json';'X-GitHub-Api-Version'='2026-03-10';'User-Agent'='runner-validation'}
$credential=$null
try {
if ($AppAuthentication) {
    Import-Module (Join-Path $PSScriptRoot 'RunnerGitHub.psm1') -Force
    $repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $credential=Get-RunnerInstallationToken -Target $target -RepositoryRoot $repoRoot
    $headers.Authorization="Bearer $($credential.token)"
}
$selectedRuns=if ($RunIds.Count) { foreach ($runId in $RunIds) { Invoke-RestMethod -Uri "$base/actions/runs/$runId" -Headers $headers -TimeoutSec 30 } } else { (Invoke-RestMethod -Uri "$base/actions/runs?per_page=$Count" -Headers $headers -TimeoutSec 30).workflow_runs }
foreach ($run in $selectedRuns) {
    [pscustomobject]@{RunId=$run.id;Workflow=$run.name;HeadSha=$run.head_sha;Branch=$run.head_branch;CreatedAt=$run.created_at;Status=$run.status;Conclusion=$run.conclusion;URL=$run.html_url}
    $jobs=Invoke-RestMethod -Uri "$base/actions/runs/$($run.id)/jobs?per_page=100" -Headers $headers -TimeoutSec 30
    foreach ($job in $jobs.jobs) {
        [pscustomobject]@{Job=$job.name;Status=$job.status;Conclusion=$job.conclusion;Runner=$job.runner_name;ActiveSteps=(@($job.steps | Where-Object status -eq 'in_progress' | ForEach-Object name) -join ',');FailedSteps=(@($job.steps | Where-Object conclusion -eq 'failure' | ForEach-Object name) -join ',')}
        if ($job.conclusion -eq 'failure' -and $job.check_run_url.StartsWith("$base/check-runs/")) {
            $annotations=Invoke-RestMethod -Uri "$($job.check_run_url)/annotations?per_page=20" -Headers $headers -TimeoutSec 30
            foreach ($annotation in $annotations) {
                $message=[string]$annotation.message
                $message=$message -replace '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+)','[REDACTED]'
                [pscustomobject]@{Job=$job.name;Annotation=$message.Substring(0,[Math]::Min($message.Length,2000))}
            }
        }
    }
}
} finally {
    if ($credential) { $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token; $credential=$null }
}
