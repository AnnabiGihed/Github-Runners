[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$images = Get-Content (Join-Path $repoRoot 'config/docker-images.lock.json') -Raw | ConvertFrom-Json
foreach ($image in @($images.daemon,$images.client)) { if ($image -notmatch '@sha256:[a-f0-9]{64}$') { throw 'Immutable image reference required.' } }
$prefix = 'runner-lab-' + [guid]::NewGuid().ToString('N')
$daemon = "$prefix-daemon"
$socket = "$prefix-socket"
$work = "$prefix-work"
$network = "$prefix-network"
function Invoke-CheckedDocker {
    param([string[]]$Arguments)
    $output = & docker @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker operation failed: $($Arguments[0])" }
    return $output
}
try {
    Invoke-CheckedDocker @('volume','create','--label',"runner.lab=$prefix",$socket) | Out-Null
    Invoke-CheckedDocker @('volume','create','--label',"runner.lab=$prefix",$work) | Out-Null
    Invoke-CheckedDocker @('network','create','--label',"runner.lab=$prefix",$network) | Out-Null
    # Bypass the image entrypoint's automatic TCP listener; use only a job-local socket.
    Invoke-CheckedDocker @('run','-d','--name',$daemon,'--label',"runner.lab=$prefix",'--privileged','--network',$network,'--memory','2g','--cpus','2','--pids-limit','1024','--mount',"type=volume,src=$socket,dst=/job-socket",'--mount',"type=volume,src=$work,dst=/job-work",'--entrypoint','dockerd',$images.daemon,'--host=unix:///job-socket/docker.sock','--group=1000','--data-root=/var/lib/docker') | Out-Null
    $ready = $false
    for ($i=0; $i -lt 30; $i++) {
        & docker exec $daemon docker --host unix:///job-socket/docker.sock info --format '{{.ServerVersion}}' 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready=$true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'Job-local Docker startup timed out.' }
    $inspection = (Invoke-CheckedDocker @('inspect',$daemon) | ConvertFrom-Json)[0]
    if ($inspection.HostConfig.PortBindings.PSObject.Properties.Count -gt 0) { throw 'Unexpected published ports.' }
    if (@($inspection.Mounts | Where-Object Type -ne 'volume').Count) { throw 'Unexpected host mount.' }
    $tcpListeners = Invoke-CheckedDocker @('exec',$daemon,'sh','-c','netstat -lnt')
    # Docker's embedded DNS may listen on 127.0.0.11 at an ephemeral TCP port.
    $unexpected = @($tcpListeners | Where-Object { $_ -match '^tcp' -and $_ -notmatch '\s127\.0\.0\.11:\d+\s' })
    if ($unexpected.Count) { throw "Unexpected TCP listener in job daemon: $($unexpected -join '; ')" }
    $clientArgs = @('run','--rm','--network',$network,'--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--memory','512m','--pids-limit','128','--mount',"type=volume,src=$socket,dst=/job-socket",'--mount',"type=volume,src=$work,dst=/job-work",'-e','DOCKER_HOST=unix:///job-socket/docker.sock','-e','HOME=/tmp','-e','DOCKER_CONFIG=/tmp/.docker',$images.client)
    # Nested containers and a Docker build, without GitHub credentials.
    Invoke-CheckedDocker ($clientArgs + @('sh','-c','docker run --rm alpine:3.22 echo nested-container-ok; test $? -eq 0 || exit 1; printf "FROM scratch\nLABEL runner.lab=smoke\n" | docker build -t runner-lab-smoke -')) | Out-Null
    Write-Output 'PASS: unprivileged client, job-local Unix socket, no daemon TCP API/host mounts/published ports, nested container and Docker build.'
} finally {
    & docker rm -f -v $daemon 2>$null | Out-Null
    $containerRemoval = $LASTEXITCODE
    if ($containerRemoval -eq 0) {
        & docker volume rm $socket $work 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Job test volume cleanup failed; inspect owned resources.' }
    }
    & docker network rm $network 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Job test network cleanup failed; inspect owned resources.' }
}
