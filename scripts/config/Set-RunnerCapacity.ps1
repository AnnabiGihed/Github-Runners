[CmdletBinding()]
param(
    [string]$ConfigPath='.local/targets.json',
    [Parameter(Mandatory)][string]$TargetId,
    [Parameter(Mandatory)][ValidateRange(1,64)][int]$MaxRunners
)
$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$target=@($config.targets | Where-Object id -eq $TargetId)
if ($target.Count -ne 1) { throw 'Expected exactly one configured target.' }
$target[0].maxRunners=$MaxRunners
$candidate="$ConfigPath.capacity.tmp"
try {
    $config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $candidate -Encoding utf8
    $null=& (Join-Path $PSScriptRoot 'Test-RunnerConfiguration.ps1') -Path $candidate
    Move-Item -LiteralPath $candidate -Destination $ConfigPath -Force
} finally {
    if (Test-Path -LiteralPath $candidate) { Remove-Item -LiteralPath $candidate }
}
Write-Output 'Capacity saved within the existing host cap. Apply through graceful controller drain/restart.'
