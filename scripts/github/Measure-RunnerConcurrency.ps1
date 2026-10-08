[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json',[Parameter(Mandatory)][string]$TargetId,[ValidateRange(1,100)][int]$Count=20)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'RunnerGitHub.psm1') -Force
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$target=@($config.targets | Where-Object id -eq $TargetId)
if ($target.Count -ne 1 -or $target[0].scope -ne 'repository') { throw 'Expected a repository target.' }
$target=$target[0]
$credential=Get-RunnerInstallationToken -Target $target -RepositoryRoot $repoRoot
try {
    $base="/repos/$($target.owner)/$($target.repository)"
    $runs=Invoke-RunnerGitHubApi -Method GET -Path "$base/actions/runs?per_page=$Count" -Token $credential.token
    $jobs=@()
    foreach ($run in $runs.workflow_runs) {
        $result=Invoke-RunnerGitHubApi -Method GET -Path "$base/actions/runs/$($run.id)/jobs?per_page=100" -Token $credential.token
        $jobs+=@($result.jobs | Where-Object { $_.runner_name -like "pc-$TargetId-*" -and $_.started_at -and $_.status -in @('in_progress','completed') })
    }
    $jobs=@($jobs | Sort-Object id -Unique)
    $events=@()
    $now=[DateTimeOffset]::UtcNow
    foreach ($job in $jobs) {
        $start=[DateTimeOffset]::Parse($job.started_at)
        $end=if ($job.completed_at) { [DateTimeOffset]::Parse($job.completed_at) } else { $now }
        # Skipped jobs have no actual execution interval.
        if ($end -le $start) { continue }
        $events+=[pscustomobject]@{At=$start;Delta=1;Runner=$job.runner_name}
        $events+=[pscustomobject]@{At=$end;Delta=-1;Runner=$job.runner_name}
    }
    $active=[Collections.Generic.HashSet[string]]::new();$peak=0;$peakAt=$null;$peakNames=@()
    foreach ($event in $events | Sort-Object At,Delta) {
        if ($event.Delta -eq 1) { $null=$active.Add($event.Runner) } else { $null=$active.Remove($event.Runner) }
        if ($active.Count -gt $peak) { $peak=$active.Count;$peakAt=$event.At;$peakNames=@($active) }
    }
    [pscustomobject]@{Target=$TargetId;RunsInspected=@($runs.workflow_runs).Count;JobsInspected=$jobs.Count;ObservedPeak=$peak;PeakAtUtc=$(if ($peakAt) { $peakAt.ToUniversalTime().ToString('o') } else { $null });DistinctRunnersAtPeak=($peakNames -join ',');SuccessfulJobs=@($jobs | Where-Object conclusion -eq 'success').Count;ReusedRunnerIdentities=@($jobs | Group-Object runner_name | Where-Object Count -gt 1).Count;Limit='Sampled job execution intervals; does not establish representative resource headroom or that all overlapping jobs succeeded.'}
} finally { $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token;$credential=$null }
