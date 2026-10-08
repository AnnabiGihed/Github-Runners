#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'scripts/desktop/Find-RunnerPowerShell.ps1')
$current=(Get-Process -Id $PID).Path
if ((Find-RunnerPowerShell -PowerShellPath $current) -ne $current) { throw 'Explicit runtime resolution failed.' }
$rejected=$false
try { Find-RunnerPowerShell -PowerShellPath (Join-Path $root '.local/missing-pwsh.exe') | Out-Null } catch { $rejected=$true }
if (-not $rejected) { throw 'Missing explicit runtime should fail with guidance.' }
$legacy=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
& $legacy -NoProfile -File (Join-Path $root 'scripts/desktop/Open-RunnerDesktop.ps1') -SmokeTest
if ($LASTEXITCODE -ne 0) { throw 'Windows PowerShell 5.1 desktop handoff failed.' }
& $legacy -NoProfile -File (Join-Path $root 'scripts/desktop/New-RunnerDesktopShortcut.ps1') -PowerShellPath $current
if ($LASTEXITCODE -ne 0) { throw 'Windows PowerShell 5.1 shortcut handoff failed.' }
'Desktop launcher tests passed: explicit runtime, unavailable runtime, Windows PowerShell 5.1 UI and shortcut handoff.'
