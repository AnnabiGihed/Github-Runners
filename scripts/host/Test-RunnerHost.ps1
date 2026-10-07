<#!
.SYNOPSIS
Read-only local Docker preflight. No containers or settings are changed.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Invoke-DockerCheck {
    param([string[]]$DockerArguments)
    $result = & docker @DockerArguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker check failed: docker $($DockerArguments -join ' '). Ensure Docker Desktop is running and the current user can access its engine."
    }
    return ($result -join "`n")
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker CLI is not available on PATH.'
}

$contextName = Invoke-DockerCheck -DockerArguments @('context', 'show')
$context = (Invoke-DockerCheck -DockerArguments @('context', 'inspect', $contextName) | ConvertFrom-Json)[0]
$endpoint = [string]$context.Endpoints.docker.Host
# Docker environment overrides can supersede the selected context.
if ($env:DOCKER_HOST -and -not $env:DOCKER_CONTEXT) { $endpoint = $env:DOCKER_HOST }
if ($endpoint -notmatch '^(npipe|unix)://') {
    throw 'Current Docker endpoint is not a local socket/named pipe. Remote or TCP endpoints are outside this project baseline.'
}

$version = Invoke-DockerCheck -DockerArguments @('version', '--format', '{{json .}}') | ConvertFrom-Json
$info = Invoke-DockerCheck -DockerArguments @('info', '--format', '{{json .}}') | ConvertFrom-Json
if ($info.OSType -ne 'linux') {
    throw 'Linux container mode is required for the proposed Linux runner baseline.'
}

# Deliberately omit usernames, endpoint addresses, container names, and credentials.
[pscustomobject]@{
    CheckedAtUtc = [DateTime]::UtcNow.ToString('o')
    ClientVersion = $version.Client.Version
    ServerVersion = $version.Server.Version
    EngineOS = $info.OSType
    Architecture = $info.Architecture
    CPUs = $info.NCPU
    EngineMemoryGiB = [Math]::Round($info.MemTotal / 1GB, 2)
    ExistingContainers = $info.Containers
    RunningContainers = $info.ContainersRunning
    LocalEndpoint = $true
    LinuxContainers = $true
} | ConvertTo-Json
