#requires -Version 7.4
[CmdletBinding()]
param(
    [string]$ConfigPath='.local/targets.json',
    [ValidateRange(30,86400)][int]$RunSeconds=3600,
    [ValidateRange(1,1440)][int]$IdleMinutes=60,
    [ValidateRange(0,3600)][int]$DrainSeconds=300,
    [switch]$ValidationOnly,
    [switch]$Continuous,
    [switch]$CleanupOnly,
    [string]$ValidationApiFailureFile,
    [switch]$ResetStopRequest
)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if ($ValidationApiFailureFile -and -not $ValidationOnly) { throw 'API failure injection is available only for validation probes.' }
if ($CleanupOnly -and ($Continuous -or $ResetStopRequest)) { throw 'Cleanup-only cannot replenish or reset a stop request.' }
& (Join-Path $repoRoot 'scripts/config/Test-RunnerConfiguration.ps1') -Path $ConfigPath | Out-Null
Import-Module (Join-Path $repoRoot 'scripts/github/RunnerGitHub.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'RunnerDiagnostics.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'RunnerDemand.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'RunnerAttachment.psm1') -Force
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$resources=Get-Content (Join-Path $repoRoot 'config/runner-resources.json') -Raw | ConvertFrom-Json
$images=Get-Content (Join-Path $repoRoot 'config/docker-images.lock.json') -Raw | ConvertFrom-Json
if ($images.daemon -notmatch '@sha256:[a-f0-9]{64}$') { throw 'Pinned daemon image required.' }
$stateDir=Join-Path $repoRoot '.local/controller'
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
$lock=[IO.File]::Open((Join-Path $stateDir 'controller.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
if ($ResetStopRequest -and (Test-Path -LiteralPath (Join-Path $stateDir 'stop'))) { Remove-Item -LiteralPath (Join-Path $stateDir 'stop') }
$statePath=Join-Path $stateDir 'state.json'
$state=if (Test-Path $statePath) { Get-Content $statePath -Raw | ConvertFrom-Json } else { [pscustomobject]@{owner=[guid]::NewGuid().ToString('N');slots=@()} }
$tokens=@{}
$attachments=@{}
$failedStarts=@{}
$demand=@{}
$diagnosticPath=Join-Path $repoRoot '.local/diagnostics'
Initialize-RunnerDiagnosticDirectory -Path $diagnosticPath
$lastDiagnostics=[DateTimeOffset]::MinValue
$runnerImageId=$null
if (-not $CleanupOnly) {
    $runnerImageId=(& docker image inspect local/ephemeral-github-runner:dev --format '{{.Id}}').Trim()
    if ($LASTEXITCODE -ne 0 -or $runnerImageId -notmatch '^sha256:[a-f0-9]{64}$') { $lock.Dispose(); throw 'Build the runner image before starting the controller.' }
}
function Save-State {
    $temp="$statePath.tmp"
    $polling=@(foreach ($id in $demand.Keys) {
        $snapshot=$demand[$id]
        [pscustomobject]@{targetId=$id;valid=$snapshot.valid;queued=$snapshot.queued;lastSuccessUtc=$snapshot.lastSuccess;nextPollUtc=$snapshot.next.ToString('o')}
    })
    $state | Add-Member -NotePropertyName demandSnapshots -NotePropertyValue $polling -Force
    $state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $temp -Encoding utf8
    Move-Item -LiteralPath $temp -Destination $statePath -Force
}
function Invoke-ControllerDocker {
    param([string[]]$Arguments)
    $result=& docker @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Docker $($Arguments[0]) failed; inspect local diagnostics." }
    return $result
}
function Target-For($slot) {
    $target=@($config.targets | Where-Object id -eq $slot.targetId)
    if ($target.Count -ne 1) { throw 'State refers to a removed target; restore its configuration before cleanup.' }
    return $target[0]
}
function Api($target,[string]$method,[string]$suffix) {
    if ($ValidationOnly -and $ValidationApiFailureFile -and (Test-Path -LiteralPath $ValidationApiFailureFile)) { throw 'Injected API outage for validation.' }
    if (-not $tokens.ContainsKey($target.id) -or [DateTimeOffset]::Parse($tokens[$target.id].expires_at) -lt [DateTimeOffset]::UtcNow.AddMinutes(5)) {
        $tokens[$target.id]=Get-RunnerInstallationToken -Target $target -RepositoryRoot $repoRoot
    }
    $base=if ($target.scope -eq 'repository') { "/repos/$($target.owner)/$($target.repository)/actions/runners" } else { "/orgs/$($target.owner)/actions/runners" }
    Invoke-RunnerGitHubApi -Method $method -Path "$base$suffix" -Token $tokens[$target.id].token
}
function Remote-Runner($target,[string]$name) {
    for ($page=1; $page -le 100; $page++) {
        $list=Api $target GET "?per_page=100&page=$page"
        $found=@($list.runners | Where-Object name -ceq $name)
        if ($found.Count) { return $found[0] }
        if (@($list.runners).Count -lt 100) { return $null }
    }
    throw 'Runner pagination limit reached; cannot safely reconcile.'
}
function Remove-OwnedContainer([string]$name) {
    $raw=& docker inspect $name 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Distinguish absent resource from an unavailable engine before forgetting state.
        $null=Invoke-ControllerDocker @('info','--format','{{.ServerVersion}}')
        return
    }
    $resource=($raw | ConvertFrom-Json)[0]
    if ($resource.Config.Labels.'runner.controller' -ne $state.owner) { throw 'Container ownership mismatch; cleanup refused.' }
    $null=Invoke-ControllerDocker @('rm','-f','-v',$name)
}
function Cleanup($slot) {
    $target=Target-For $slot
    $remote=Remote-Runner $target $slot.name
    if ($remote -and $remote.busy) { throw 'Busy runner cannot be cleaned up before draining.' }
    # Deregister an idle listener before destroying it. If GitHub rejects deletion
    # because assignment raced the busy check, preserve all local resources.
    $raw=& docker inspect $slot.name 2>$null
    $runnerExists=($LASTEXITCODE -eq 0)
    if ($runnerExists) {
        $resource=($raw | ConvertFrom-Json)[0]
        if ($resource.Config.Labels.'runner.controller' -ne $state.owner) { throw 'Container ownership mismatch; diagnostics refused.' }
    } else { $null=Invoke-ControllerDocker @('info','--format','{{.ServerVersion}}') }
    if ($remote) { $null=Api $target DELETE "/$($remote.id)" }
    if ($runnerExists) {
        Save-RunnerDiagnostics -Container $slot.name -Path $diagnosticPath
    }
    if ($attachments.ContainsKey($slot.name) -and $attachments[$slot.name].process.HasExited) {
        $errorText=$attachments[$slot.name].stderr.GetAwaiter().GetResult()
        if ($errorText) { Write-Warning (Protect-RunnerDiagnosticText ($errorText.Substring(0,[Math]::Min($errorText.Length,1500)))) }
    }
    Remove-OwnedContainer $slot.name
    Remove-OwnedContainer $slot.daemon
    $volumes=@($slot.socket,$slot.work)
    if ($slot.PSObject.Properties['externals']) { $volumes+=@($slot.externals) }
    foreach ($volume in $volumes) {
        $raw=& docker volume inspect $volume 2>$null
        if ($LASTEXITCODE -eq 0) {
            $resource=($raw | ConvertFrom-Json)[0]
            if ($resource.Labels.'runner.controller' -ne $state.owner) { throw 'Volume ownership mismatch.' }
            $null=Invoke-ControllerDocker @('volume','rm',$volume)
        } else { $null=Invoke-ControllerDocker @('info','--format','{{.ServerVersion}}') }
    }
    $raw=& docker network inspect $slot.network 2>$null
    if ($LASTEXITCODE -eq 0) {
        $resource=($raw | ConvertFrom-Json)[0]
        if ($resource.Labels.'runner.controller' -ne $state.owner) { throw 'Network ownership mismatch.' }
        $null=Invoke-ControllerDocker @('network','rm',$slot.network)
    } else { $null=Invoke-ControllerDocker @('info','--format','{{.ServerVersion}}') }
    if ($attachments.ContainsKey($slot.name)) { $attachments[$slot.name].process.Dispose(); $attachments.Remove($slot.name) }
    $state.slots=@($state.slots | Where-Object name -ne $slot.name)
    Save-State
    Write-Output "Removed disposable environment for $($target.id)."
}
function Provision($target) {
    # Public production routing requires an explicit trusted-trigger policy.
    if (-not $ValidationOnly -and $target.scope -eq 'repository') {
        $null=Api $target GET '?per_page=1'
        $metadata=Invoke-RunnerGitHubApi -Method GET -Path "/repos/$($target.owner)/$($target.repository)" -Token $tokens[$target.id].token
        if (-not $metadata.private -and (-not $target.PSObject.Properties['trustedPublicWorkflows'] -or $target.trustedPublicWorkflows -ne $true)) { throw 'Public target needs explicit trustedPublicWorkflows configuration and reviewed trigger policy.' }
    }
    $name="pc-$($target.id)-$([guid]::NewGuid().ToString('N').Substring(0,12))"
    $slot=[pscustomobject]@{targetId=$target.id;name=$name;daemon="$name-docker";socket="$name-socket";work="$name-work";externals="$name-externals";network="$name-net";created=[DateTimeOffset]::UtcNow.ToString('o');seenOnline=$false;validation=[bool]$ValidationOnly}
    $state.slots=@($state.slots)+$slot
    Save-State
    $label="runner.controller=$($state.owner)"
    $null=Invoke-ControllerDocker @('volume','create','--label',$label,$slot.socket)
    $null=Invoke-ControllerDocker @('volume','create','--label',$label,$slot.work)
    $null=Invoke-ControllerDocker @('volume','create','--label',$label,$slot.externals)
    # Docker copies the pinned runner's bundled runtimes into a fresh named volume.
    $null=Invoke-ControllerDocker @('run','--rm','--network','none','--mount',"type=volume,src=$($slot.externals),dst=/home/runner/externals",'--entrypoint','true',$runnerImageId)
    $null=Invoke-ControllerDocker @('network','create','--label',$label,$slot.network)
    # Validate aggregate limits against the live engine before creating any slot.
    $daemonCPU=([double]$resources.daemon.cpus).ToString('0.##',[Globalization.CultureInfo]::InvariantCulture)
    $null=Invoke-ControllerDocker @('run','-d','--name',$slot.daemon,'--label',$label,'--privileged','--network',$slot.network,'--restart','no','--memory',"$($resources.daemon.memoryMiB)m",'--cpus',$daemonCPU,'--pids-limit',[string]$resources.daemon.pids,'--log-opt','max-size=10m','--log-opt','max-file=2','--mount',"type=volume,src=$($slot.socket),dst=/job-socket",'--mount',"type=volume,src=$($slot.work),dst=/job-work",'--mount',"type=volume,src=$($slot.externals),dst=/home/runner/externals,readonly",'--entrypoint','dockerd',$images.daemon,'--host=unix:///job-socket/docker.sock','--group=123','--data-root=/var/lib/docker')
    # Official runner UID/GID are discovered from the pinned local image, not guessed.
    $uid=(Invoke-ControllerDocker @('run','--rm','--network','none','--entrypoint','id',$runnerImageId,'-u')).Trim()
    $gid=(Invoke-ControllerDocker @('run','--rm','--network','none','--entrypoint','id',$runnerImageId,'-g')).Trim()
    # Daemon's socket group is corrected before an unprivileged runner connects.
    $ready=$false
    for ($i=0;$i -lt 60;$i++) {
        & docker exec $slot.daemon test -S /job-socket/docker.sock 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready=$true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'Job daemon startup timed out.' }
    $null=Invoke-ControllerDocker @('exec',$slot.daemon,'chown',"${uid}:${gid}",'/job-work','/job-socket/docker.sock')
    # Shared daemon network namespace lets services published by the nested engine use localhost.
    $runnerCPU=([double]$resources.runner.cpus).ToString('0.##',[Globalization.CultureInfo]::InvariantCulture)
    $null=Invoke-ControllerDocker @('create','-i','--name',$name,'--label',$label,'--network',"container:$($slot.daemon)",'--restart','no','--cap-drop','ALL','--security-opt','no-new-privileges','--memory',"$($resources.runner.memoryMiB)m",'--cpus',$runnerCPU,'--pids-limit',[string]$resources.runner.pids,'--log-opt','max-size=10m','--log-opt','max-file=2','--mount',"type=volume,src=$($slot.socket),dst=/job-socket",'--mount',"type=volume,src=$($slot.work),dst=/job-work",'--mount',"type=volume,src=$($slot.externals),dst=/home/runner/externals,readonly",$runnerImageId)
    $registration=Api $target POST '/registration-token'
    $url=if ($target.scope -eq 'repository') { "https://github.com/$($target.owner)/$($target.repository)" } else { "https://github.com/$($target.owner)" }
    $labels=if ($ValidationOnly) { @("probe-$($state.owner)") } else { @($target.labels) }
    $bootstrap=@{token=$registration.token;url=$url;name=$name;labels=@($labels);validation=[bool]$ValidationOnly} | ConvertTo-Json -Compress
    # Isolated from the supervisor's console so its closure never signals a busy job.
    $attachments[$name]=Start-RunnerAttachment -Container $name
    $process=$attachments[$name].process
    $process.StandardInput.WriteLine($bootstrap);$process.StandardInput.Close()
    $bootstrap=$null;$registration=$null
    Write-Output "Provisioned fresh runner for $($target.id)."
}
try {
    Save-State
    if (-not $CleanupOnly) {
        $hostInfo=& (Join-Path $repoRoot 'scripts/host/Test-RunnerHost.ps1') | ConvertFrom-Json
        $null=& (Join-Path $repoRoot 'scripts/config/Test-RunnerResources.ps1') -Path (Join-Path $repoRoot 'config/runner-resources.json') -MaxRunners $config.hostMaxRunners -EngineCPUs $hostInfo.CPUs -EngineMemoryMiB ($hostInfo.EngineMemoryGiB*1024)
    }
    # Remove only recorded stale environments; never reuse a partially used workspace.
    foreach ($slot in @($state.slots)) {
        $remote=Remote-Runner (Target-For $slot) $slot.name
        if ($remote -and $remote.busy) { Write-Output 'Retaining an existing busy job until completion; no workspace reuse.';continue }
        Cleanup $slot
    }
    $end=[DateTimeOffset]::UtcNow.AddSeconds($RunSeconds)
    while (-not $CleanupOnly -and ($Continuous -or [DateTimeOffset]::UtcNow -lt $end) -and -not (Test-Path (Join-Path $stateDir 'stop'))) {
        foreach ($slot in @($state.slots)) {
            $target=Target-For $slot
            $remote=Remote-Runner $target $slot.name
            if ($remote -and $remote.status -eq 'online') { $slot.seenOnline=$true }
            $inspect=Invoke-ControllerDocker @('inspect',$slot.name)
            $running=($inspect | ConvertFrom-Json)[0].State.Running
            if (-not $running -and -not $slot.seenOnline) {
                if (-not $failedStarts.ContainsKey($target.id)) { $failedStarts[$target.id]=0 }
                $failedStarts[$target.id]++
                if ($failedStarts[$target.id] -ge 3) { throw 'Three runner startup failures; provisioning stopped for diagnosis.' }
            }
            if (-not $running -or ($slot.seenOnline -and -not $remote) -or (-not $slot.seenOnline -and [DateTimeOffset]::Parse($slot.created) -lt [DateTimeOffset]::UtcNow.AddMinutes(-3)) -or ($remote -and -not $remote.busy -and [DateTimeOffset]::Parse($slot.created) -lt [DateTimeOffset]::UtcNow.AddMinutes(-$IdleMinutes))) { Cleanup $slot }
        }
        foreach ($target in $config.targets) {
            $desired=[int]$target.maxRunners
            $freshDemand=$false
            $demandMode=(-not $ValidationOnly -and $target.PSObject.Properties['scalingMode'] -and $target.scalingMode -eq 'demand')
            if ($demandMode) {
                if (-not $demand.ContainsKey($target.id)) { $demand[$target.id]=@{next=[DateTimeOffset]::MinValue;valid=$false;queued=0;lastSuccess=$null} }
                $snapshot=$demand[$target.id]
                if ([DateTimeOffset]::UtcNow -ge $snapshot.next) {
                    $interval=if ($target.PSObject.Properties['pollSeconds']) { [int]$target.pollSeconds } else { 60 }
                    $snapshot.next=[DateTimeOffset]::UtcNow.AddSeconds($interval)
                    $snapshot.valid=$false
                    try {
                        # Refresh management token through the same host-only cache.
                        $null=Api $target GET '?per_page=1'
                        $snapshot.queued=Get-RunnerQueueDemand -Target $target -Request {
                            param($path)
                            Invoke-RunnerGitHubApi -Method GET -Path $path -Token $tokens[$target.id].token
                        }
                        $snapshot.valid=$true
                        $freshDemand=$true
                        $snapshot.lastSuccess=[DateTimeOffset]::UtcNow.ToString('o')
                        Write-Output "Queue snapshot for $($target.id): $($snapshot.queued) matching queued jobs (bounded by capacity)."
                    } catch { Write-Warning 'Queue snapshot unavailable; retain existing capacity and retry without scaling.' }
                }
                if (-not $snapshot.valid) { continue }
                $busy=0
                foreach ($slot in @($state.slots | Where-Object targetId -eq $target.id)) {
                    $remote=Remote-Runner $target $slot.name
                    if ($remote -and $remote.busy) { $busy++ }
                }
                $desired=Get-RunnerDesiredSlots -Queued $snapshot.queued -Busy $busy -Maximum $target.maxRunners
                # Never remove a busy job. A two-minute startup grace absorbs assignment races.
                foreach ($slot in @($state.slots | Where-Object targetId -eq $target.id)) {
                    if (@($state.slots | Where-Object targetId -eq $target.id).Count -le $desired) { break }
                    $remote=Remote-Runner $target $slot.name
                    if ($remote -and $remote.busy) { continue }
                    if ([DateTimeOffset]::Parse($slot.created) -gt [DateTimeOffset]::UtcNow.AddSeconds(-120)) { continue }
                    try { Cleanup $slot } catch { Write-Warning 'Scale-down pending; environment retained for safe retry.' }
                }
            }
            # Cached queued counts may already be assigned. Scale up only on a
            # new successful scan, avoiding duplicate idle capacity between scans.
            if (-not $demandMode -or $freshDemand) {
                while (@($state.slots | Where-Object targetId -eq $target.id).Count -lt $desired) { Provision $target }
            }
        }
        Save-State
        if ([DateTimeOffset]::UtcNow - $lastDiagnostics -ge [TimeSpan]::FromMinutes(1)) {
            foreach ($slot in @($state.slots)) {
                try { Save-RunnerDiagnostics -Container $slot.name -Path $diagnosticPath } catch { Write-Warning 'Diagnostic checkpoint unavailable; will retry before cleanup.' }
            }
            $lastDiagnostics=[DateTimeOffset]::UtcNow
        }
        Start-Sleep -Seconds 10
    }
} finally {
    # Stop replenishment and allow busy jobs to drain. Leave busy state recorded if timeout expires.
    $deadline=[DateTimeOffset]::UtcNow.AddSeconds($DrainSeconds)
    do {
        foreach ($slot in @($state.slots)) {
            try { Cleanup $slot } catch { Write-Warning 'Cleanup pending: busy runner, API/network failure, or owned resource unavailable. State retained.' }
        }
        if ($state.slots.Count -eq 0 -or [DateTimeOffset]::UtcNow -ge $deadline) { break }
        Start-Sleep -Seconds 10
    } while ($true)
    foreach ($token in $tokens.Values) {
        try { $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $token.token } catch { Write-Warning 'Controller token revocation pending expiration.' }
    }
    $tokens.Clear()
}
} finally { $lock.Dispose() }
