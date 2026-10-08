$ErrorActionPreference='Stop'
$script=Join-Path $PSScriptRoot '../scripts/config/Test-RunnerResources.ps1'
$path=Join-Path $PSScriptRoot '../config/runner-resources.json'
$valid=& $script -Path $path -MaxRunners 4 -EngineCPUs 8 -EngineMemoryMiB 15994
if (-not $valid.Valid -or $valid.AllocatedCPUs -ne 8) { throw 'Expected four-slot allocation.' }
foreach ($case in @(@{CPU=7;Memory=15994},@{CPU=8;Memory=15000})) {
    $rejected=$false
    try { $null=& $script -Path $path -MaxRunners 4 -EngineCPUs $case.CPU -EngineMemoryMiB $case.Memory } catch { $rejected=$true }
    if (-not $rejected) { throw 'Resource oversubscription was accepted.' }
}
Write-Output 'Passed: four-slot allocation; CPU and memory-plus-reserve oversubscription rejected.'
