#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^pc-[a-z0-9-]+-[a-f0-9]{12}$')][string]$RunnerName)
$ErrorActionPreference='Stop'
$checks=@(
    @{type='container';name=$RunnerName},@{type='container';name="$RunnerName-docker"},
    @{type='volume';name="$RunnerName-socket"},@{type='volume';name="$RunnerName-work"},
    @{type='volume';name="$RunnerName-externals"},@{type='network';name="$RunnerName-net"}
)
foreach ($check in $checks) {
    & docker $check.type inspect $check.name *> $null
    if ($LASTEXITCODE -eq 0) { throw "Environment resource still exists: $($check.type) $($check.name)." }
    & docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Docker unavailable; absence cannot be verified.' }
}
[pscustomobject]@{Runner=$RunnerName;ContainerRemoved=$true;DaemonRemoved=$true;WorkspaceRemoved=$true;ExternalsRemoved=$true;SocketRemoved=$true;NetworkRemoved=$true;DockerAvailable=$true}
