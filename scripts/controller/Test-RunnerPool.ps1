[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $repoRoot 'scripts/github/RunnerGitHub.psm1') -Force
$state=Get-Content (Join-Path $repoRoot '.local/controller/state.json') -Raw | ConvertFrom-Json
$config=Get-Content $ConfigPath -Raw | ConvertFrom-Json
$resources=Get-Content (Join-Path $repoRoot 'config/runner-resources.json') -Raw | ConvertFrom-Json
foreach ($target in $config.targets) {
    $credential=Get-RunnerInstallationToken -Target $target -RepositoryRoot $repoRoot
    try {
        $base=if ($target.scope -eq 'repository') { "/repos/$($target.owner)/$($target.repository)/actions/runners" } else { "/orgs/$($target.owner)/actions/runners" }
        $runners=Invoke-RunnerGitHubApi -Method GET -Path "${base}?per_page=100" -Token $credential.token
        foreach ($slot in @($state.slots | Where-Object targetId -eq $target.id)) {
            $remote=@($runners.runners | Where-Object name -ceq $slot.name)
            $inspection=& docker inspect $slot.name 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Pool changed during inspection; rerun while controller is active.'; continue }
            $container=($inspection | ConvertFrom-Json)[0]
            if (-not $container.State.Running -or $remote.Count -ne 1) { Write-Warning 'Runner starting or completing; snapshot omitted.'; continue }
            $daemonRaw=& docker inspect $slot.daemon 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Daemon changed during inspection; snapshot omitted.';continue }
            $daemon=($daemonRaw | ConvertFrom-Json)[0]
            $daemonIsolated=($daemon.Config.Labels.'runner.controller' -eq $state.owner -and $daemon.HostConfig.Privileged -and @($daemon.Mounts | Where-Object Type -ne 'volume').Count -eq 0 -and @($daemon.HostConfig.PortBindings.PSObject.Properties).Count -eq 0 -and '--host=unix:///job-socket/docker.sock' -in $daemon.Config.Cmd -and @($daemon.Config.Cmd | Where-Object { $_ -match '^--host=tcp:' }).Count -eq 0)
            if (-not $daemonIsolated) { throw 'Job daemon isolation invariant failed.' }
            if ($container.HostConfig.Privileged -or $container.Config.User -in @('root','0','')) { throw 'Runner must be unprivileged.' }
            if (@($container.Mounts | Where-Object Type -ne 'volume').Count) { throw 'Host mount detected.' }
            if ($container.HostConfig.PortBindings.PSObject.Properties.Count) { throw 'Published host ports detected.' }
            $resourceMatch=($container.HostConfig.NanoCpus -eq $resources.runner.cpus*1e9 -and $container.HostConfig.Memory -eq $resources.runner.memoryMiB*1MB -and $daemon.HostConfig.NanoCpus -eq $resources.daemon.cpus*1e9 -and $daemon.HostConfig.Memory -eq $resources.daemon.memoryMiB*1MB)
            $hardened=('ALL' -in $container.HostConfig.CapDrop -and @($container.HostConfig.SecurityOpt | Where-Object { $_ -like 'no-new-privileges*' }).Count -eq 1 -and $container.HostConfig.RestartPolicy.Name -eq 'no')
            if (-not $hardened) { throw 'Runner capability/security/restart invariant failed.' }
            $configText=(& docker exec $slot.name cat /home/runner/.runner 2>$null | Out-String).TrimStart([char]0xFEFF)
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Runner changed before configuration inspection; snapshot omitted.'; continue }
            $runnerConfig=$configText | ConvertFrom-Json
            & docker exec $slot.name bash -c 'test "$DOTNET_INSTALL_DIR" = /job-work/.dotnet && mkdir -p "$DOTNET_INSTALL_DIR" && test -w "$DOTNET_INSTALL_DIR"' | Out-Null
            $dotnetWritable=($LASTEXITCODE -eq 0)
            $cliVersion=(& docker exec $slot.name gh --version 2>$null | Select-Object -First 1)
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Runner changed before CLI inspection; snapshot omitted.'; continue }
            Write-Information "$($slot.name): $cliVersion" -InformationAction Continue
            if ($cliVersion -notmatch '^gh version (\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'2.101.0') { Write-Warning "$($slot.name) has an unsupported GitHub CLI version; graceful image rollout may still be draining." }
            [pscustomobject]@{Target=$target.id;Name=$slot.name;Registered=($remote.Count -eq 1);Online=($remote.Count -eq 1 -and $remote[0].status -eq 'online');Busy=($remote.Count -eq 1 -and $remote[0].busy);ConfiguredEphemeral=$runnerConfig.ephemeral;UnprivilegedRunner=$true;OnlyJobVolumes=$true;NoPublishedPorts=$true;DaemonIsolated=$daemonIsolated;HardenedRunner=$hardened;ResourceLimitsMatch=$resourceMatch;DotnetInstallPathWritable=$dotnetWritable;Labels=($remote.labels.name -join ',')}
        }
    } finally {
        $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token
        $credential=$null
    }
}
