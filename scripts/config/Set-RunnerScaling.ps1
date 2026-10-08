#requires -Version 7.4
[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json',[Parameter(Mandatory)][string]$TargetId,
    [Parameter(Mandatory)][ValidateSet('warm','demand')][string]$Mode,
    [ValidateRange(60,300)][int]$PollSeconds=60)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
$directory=Join-Path $root '.local/desktop'
Initialize-RunnerDiagnosticDirectory -Path $directory
$lock=[IO.File]::Open((Join-Path $directory 'config.lock'),'OpenOrCreate','ReadWrite','None')
$candidate=Join-Path $directory ('scaling-'+[guid]::NewGuid().ToString('N')+'.json')
try {
    $path=[IO.Path]::GetFullPath($ConfigPath)
    $original=[IO.File]::ReadAllText($path)
    $config=$original | ConvertFrom-Json
    $targets=@($config.targets | Where-Object id -ceq $TargetId)
    if ($targets.Count -ne 1) { throw 'Expected one configured target.' }
    $targets[0] | Add-Member -NotePropertyName scalingMode -NotePropertyValue $Mode -Force
    $targets[0] | Add-Member -NotePropertyName pollSeconds -NotePropertyValue $PollSeconds -Force
    $config | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $candidate
    $null=& (Join-Path $PSScriptRoot 'Test-RunnerConfiguration.ps1') -Path $candidate
    if ($Mode -eq 'demand') { $null=& (Join-Path $root 'scripts/github/Test-RunnerDemand.ps1') -ConfigPath $candidate -TargetId $TargetId }
    if ([IO.File]::ReadAllText($path) -cne $original) { throw 'Configuration changed during validation; retry.' }
    [IO.File]::WriteAllText((Join-Path $directory 'targets.previous.json'),$original)
    [IO.File]::Move($candidate,$path,$true)
    "Saved $Mode scaling for $TargetId. Apply with a graceful service restart; running controller configuration is unchanged until then."
} finally {
    if (Test-Path -LiteralPath $candidate) { Remove-Item -LiteralPath $candidate }
    $lock.Dispose()
}
