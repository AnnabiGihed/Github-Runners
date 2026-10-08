#requires -Version 5.1
[CmdletBinding()]
param([string]$PowerShellPath,[switch]$SmokeTest)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Find-RunnerPowerShell.ps1')
$executable=Find-RunnerPowerShell -PowerShellPath $PowerShellPath
$psi=[Diagnostics.ProcessStartInfo]::new($executable)
$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
# Arguments is supported by Windows PowerShell's .NET Framework; file paths cannot contain quotes.
$scriptPath=Join-Path $PSScriptRoot 'Start-RunnerDesktop.ps1'
$psi.Arguments='-NoLogo -NoProfile -STA -WindowStyle Hidden -File "'+$scriptPath+'"'
if ($SmokeTest) { $psi.Arguments+=' -SmokeTest' }
$process=[Diagnostics.Process]::Start($psi)
if ($SmokeTest) {
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw 'Desktop launcher smoke test failed.' }
    $process.Dispose()
    Write-Output 'Desktop launcher smoke passed.'
} else { Write-Output 'Opened Ephemeral Runner Manager.';$process.Dispose() }
