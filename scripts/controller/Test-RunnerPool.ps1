[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $repoRoot 'scripts/github/RunnerGitHub.psm1') -Force
$state=Get-Content (Join-Path $repoRoot '.local/controller/state.json') -Raw | ConvertFrom-Json
$config=Get-Content $ConfigPath -Raw | ConvertFrom-Json
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
            if ($container.HostConfig.Privileged -or $container.Config.User -in @('root','0','')) { throw 'Runner must be unprivileged.' }
            if (@($container.Mounts | Where-Object Type -ne 'volume').Count) { throw 'Host mount detected.' }
            if ($container.HostConfig.PortBindings.PSObject.Properties.Count) { throw 'Published host ports detected.' }
            $configText=(& docker exec $slot.name cat /home/runner/.runner | Out-String).TrimStart([char]0xFEFF)
            $runnerConfig=$configText | ConvertFrom-Json
            if ($LASTEXITCODE -ne 0) { throw 'Runner configuration inspection failed.' }
            & docker exec $slot.name bash -c 'test "$DOTNET_INSTALL_DIR" = /job-work/.dotnet && mkdir -p "$DOTNET_INSTALL_DIR" && test -w "$DOTNET_INSTALL_DIR"' | Out-Null
            $dotnetWritable=($LASTEXITCODE -eq 0)
            [pscustomobject]@{Target=$target.id;Registered=($remote.Count -eq 1);Online=($remote.Count -eq 1 -and $remote[0].status -eq 'online');ConfiguredEphemeral=$runnerConfig.ephemeral;UnprivilegedRunner=$true;OnlyJobVolumes=$true;NoPublishedPorts=$true;DotnetInstallPathWritable=$dotnetWritable;Labels=($remote.labels.name -join ',')}
        }
    } finally {
        $null=Invoke-RunnerGitHubApi -Method DELETE -Path '/installation/token' -Token $credential.token
        $credential=$null
    }
}
