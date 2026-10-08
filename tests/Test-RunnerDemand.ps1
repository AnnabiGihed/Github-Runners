#requires -Version 7.4
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/controller/RunnerDemand.psm1') -Force
function Assert([bool]$Value,[string]$Message) { if (-not $Value) { throw $Message } }
$target=[pscustomobject]@{scope='repository';owner='Fixture';repository='Repo';labels=@('fixture');maxRunners=4}
foreach ($case in @(
    @{status='queued';labels=@('self-hosted','Linux','X64','fixture');expected=$true},
    @{status='queued';labels=@('fixture');expected=$true},
    @{status='queued';labels=@('self-hosted');expected=$false},
    @{status='queued';labels=@('fixture','Windows');expected=$false},
    @{status='queued';labels=@('ubuntu-latest');expected=$false},
    @{status='completed';labels=@('fixture');expected=$false},
    @{status='in_progress';labels=@('fixture');expected=$false},
    @{status='waiting';labels=@('fixture');expected=$false}
)) { Assert ((Test-RunnerJobLabels ([pscustomobject]$case) $target.labels) -eq $case.expected) 'Status/label matching failed.' }
Assert ((Get-RunnerDesiredSlots 0 0 4) -eq 0) 'Empty demand must scale to zero.'
Assert ((Get-RunnerDesiredSlots 3 2 4) -eq 4) 'Demand exceeded cap.'
Assert ((Get-RunnerDesiredSlots 0 2 4) -eq 2) 'Busy jobs lost capacity.'
$script:jobCalls=0
$request={
    param($path)
    if ($path -like '*status=*') { return [pscustomobject]@{workflow_runs=@([pscustomobject]@{id=7;run_attempt=2})} }
    if ($path -like '*/7/attempts/2/jobs*') {
        $script:jobCalls++
        return [pscustomobject]@{jobs=@([pscustomobject]@{status='queued';labels=@('fixture')},[pscustomobject]@{status='queued';labels=@('other')})}
    }
    throw 'Unexpected fixture endpoint.'
}
Assert ((Get-RunnerQueueDemand $target $request) -eq 1) 'Matching demand count failed.'
Assert ($script:jobCalls -eq 1) 'Duplicate run or obsolete attempt counted.'
$capped={param($path)
    if ($path -like '*status=*') { return [pscustomobject]@{workflow_runs=@([pscustomobject]@{id=8;run_attempt=1})} }
    [pscustomobject]@{jobs=@(for ($i=0;$i -lt 12;$i++) { [pscustomobject]@{status='queued';labels=@('fixture')} })}
}
Assert ((Get-RunnerQueueDemand $target $capped) -eq 4) 'Queue count exceeded configured capacity.'
$paged={param($path)
    if ($path -like '*status=in_progress*') { return [pscustomobject]@{workflow_runs=@()} }
    if ($path -like '*status=queued*page=1') { return [pscustomobject]@{workflow_runs=@(for ($i=1;$i -le 100;$i++) { [pscustomobject]@{id=$i;run_attempt=1} })} }
    if ($path -like '*status=queued*page=2') { return [pscustomobject]@{workflow_runs=@([pscustomobject]@{id=101;run_attempt=1})} }
    [pscustomobject]@{jobs=@(if ($path -like '*/101/attempts/1/jobs*') { [pscustomobject]@{status='queued';labels=@('fixture')} })}
}
Assert ((Get-RunnerQueueDemand $target $paged) -eq 1) 'Queued run pagination missed a matching job.'
$empty={param($path);[pscustomobject]@{workflow_runs=@()}}
Assert ((Get-RunnerQueueDemand $target $empty) -eq 0) 'Empty queue miscounted.'
$failed=$false
try { Get-RunnerQueueDemand $target {param($path);throw 'offline'} | Out-Null } catch { $failed=$true }
Assert $failed 'API failure was mistaken for zero demand.'
$org=[pscustomobject]@{scope='organization';owner='Fixture';labels=@('fixture');maxRunners=4}
$orgRequest={param($path)
    if ($path -like '/installation/repositories*') { return [pscustomobject]@{repositories=@([pscustomobject]@{name='Repo';archived=$false;owner=[pscustomobject]@{login='Fixture'}},[pscustomobject]@{name='Excluded';archived=$false;owner=[pscustomobject]@{login='Other'}})} }
    & $request $path
}
Assert ((Get-RunnerQueueDemand $org $orgRequest) -eq 1) 'Organization repository filtering failed.'
'Demand tests passed: zero/busy/cap, label/status matching, current attempt, duplicate runs, API failure and organization installation scope.'
