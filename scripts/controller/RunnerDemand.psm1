#requires -Version 7.4
Set-StrictMode -Version Latest

function Test-RunnerJobLabels {
    param($Job,[string[]]$Labels)
    $requested=@($Job.labels)
    if ($Job.status -ne 'queued' -or -not $requested.Count) { return $false }
    $supported=@('self-hosted','linux','x64')+@($Labels)
    foreach ($label in $requested) { if ($label -notin $supported) { return $false } }
    # A dedicated target label prevents a generic self-hosted job scaling every target.
    return @($requested | Where-Object { $_ -in $Labels }).Count -gt 0
}

function Get-RunnerQueueDemand {
    param([Parameter(Mandatory)]$Target,[Parameter(Mandatory)][scriptblock]$Request)
    # Request is a host-only authenticated GET callback. No tokens in demand/state.
    $repositories=@()
    if ($Target.scope -eq 'repository') { $repositories=@([pscustomobject]@{name=$Target.repository;owner=[pscustomobject]@{login=$Target.owner}}) }
    else {
        for ($page=1;$page -le 10;$page++) {
            $result=& $Request "/installation/repositories?per_page=100&page=$page"
            $repositories+=@($result.repositories | Where-Object { $_.owner.login -ieq $Target.owner -and -not $_.archived })
            if (@($result.repositories).Count -lt 100) { break }
            if ($page -eq 10) { throw 'Repository polling limit reached; queue snapshot unavailable.' }
        }
    }
    $count=0
    foreach ($repository in $repositories) {
        $base="/repos/$($Target.owner)/$($repository.name)/actions/runs"
        $seenRuns=@{}
        # In-progress runs may contain queued parallel or dependent jobs.
        foreach ($status in @('queued','in_progress')) {
            for ($page=1;$page -le 10;$page++) {
                $runs=& $Request "${base}?status=$status&per_page=100&page=$page"
                foreach ($run in $runs.workflow_runs) {
                    if ($seenRuns.ContainsKey([string]$run.id)) { continue }
                    $seenRuns[[string]$run.id]=$true
                    if ([long]$run.id -le 0 -or [int]$run.run_attempt -le 0) { throw 'Invalid run identity; queue snapshot unavailable.' }
                    for ($jobPage=1;$jobPage -le 10;$jobPage++) {
                        $jobs=& $Request "${base}/$($run.id)/attempts/$($run.run_attempt)/jobs?per_page=100&page=$jobPage"
                        foreach ($job in $jobs.jobs) {
                            if (Test-RunnerJobLabels -Job $job -Labels $Target.labels) {
                                $count++
                                if ($count -ge $Target.maxRunners) { return [int]$Target.maxRunners }
                            }
                        }
                        if (@($jobs.jobs).Count -lt 100) { break }
                        if ($jobPage -eq 10) { throw 'Job polling limit reached; queue snapshot unavailable.' }
                    }
                }
                if (@($runs.workflow_runs).Count -lt 100) { break }
                if ($page -eq 10) { throw 'Run polling limit reached; queue snapshot unavailable.' }
            }
        }
    }
    return $count
}

function Get-RunnerDesiredSlots {
    param([int]$Queued,[int]$Busy,[int]$Maximum)
    if ($Queued -lt 0 -or $Busy -lt 0 -or $Maximum -lt 1) { throw 'Invalid demand counts.' }
    return [Math]::Min($Maximum,$Queued+$Busy)
}
Export-ModuleMember -Function Test-RunnerJobLabels,Get-RunnerQueueDemand,Get-RunnerDesiredSlots
