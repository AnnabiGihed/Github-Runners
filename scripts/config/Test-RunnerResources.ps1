[CmdletBinding()]
param(
    [string]$Path='config/runner-resources.json',
    [Parameter(Mandatory)][ValidateRange(1,64)][int]$MaxRunners,
    [Parameter(Mandatory)][double]$EngineCPUs,
    [Parameter(Mandatory)][double]$EngineMemoryMiB
)
$ErrorActionPreference='Stop'
$resource=Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
if ($resource.schemaVersion -ne 1 -or $resource.engineReserveMiB -lt 512) { throw 'Invalid resource schema or insufficient engine reserve.' }
foreach ($kind in @('runner','daemon')) {
    $part=$resource.$kind
    if (($part.cpus -isnot [double] -and $part.cpus -isnot [decimal] -and $part.cpus -isnot [int] -and $part.cpus -isnot [long]) -or $part.cpus -le 0 -or $part.cpus -gt $EngineCPUs) { throw 'Invalid CPU allocation.' }
    foreach ($field in @('memoryMiB','pids')) {
        if (($part.$field -isnot [long] -and $part.$field -isnot [int]) -or $part.$field -lt 1) { throw 'Memory and PID limits must be positive integers.' }
    }
}
$cpus=$MaxRunners*($resource.runner.cpus+$resource.daemon.cpus)
$memory=$MaxRunners*($resource.runner.memoryMiB+$resource.daemon.memoryMiB)+$resource.engineReserveMiB
if ($cpus -gt $EngineCPUs -or $memory -gt $EngineMemoryMiB) { throw 'Runner allocations plus engine reserve exceed Docker capacity.' }
[pscustomobject]@{Valid=$true;MaxRunners=$MaxRunners;AllocatedCPUs=$cpus;MemoryIncludingReserveMiB=$memory}
