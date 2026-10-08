#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
$directory=Join-Path $root '.local/desktop'
Initialize-RunnerDiagnosticDirectory -Path $directory
$shell=New-Object -ComObject WScript.Shell
$path=Join-Path $directory 'Ephemeral Runner Manager.lnk'
$shortcut=$shell.CreateShortcut($path)
$shortcut.TargetPath=(Get-Process -Id $PID).Path
$shortcut.Arguments="-NoLogo -NoProfile -STA -WindowStyle Hidden -File `"$(Join-Path $PSScriptRoot 'Start-RunnerDesktop.ps1')`""
$shortcut.WorkingDirectory=$root
$shortcut.Description='Manage outbound-only ephemeral Docker GitHub runners'
$shortcut.Save()
Write-Output $path
