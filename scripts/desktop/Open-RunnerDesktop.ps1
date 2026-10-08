#requires -Version 7.4
$ErrorActionPreference='Stop'
$executable=(Get-Process -Id $PID).Path
$psi=[Diagnostics.ProcessStartInfo]::new($executable)
$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
foreach ($argument in @('-NoLogo','-NoProfile','-STA','-WindowStyle','Hidden','-File',(Join-Path $PSScriptRoot 'Start-RunnerDesktop.ps1'))) { $psi.ArgumentList.Add($argument) }
$null=[Diagnostics.Process]::Start($psi)
