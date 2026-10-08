#requires -Version 5.1
[CmdletBinding()]
param([string]$PowerShellPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Find-RunnerPowerShell.ps1')
$executable=Find-RunnerPowerShell -PowerShellPath $PowerShellPath
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [version]'7.4') {
    & $executable -NoLogo -NoProfile -NonInteractive -File $PSCommandPath -PowerShellPath $executable
    if ($LASTEXITCODE -ne 0) { throw 'Shortcut creation failed in PowerShell 7.' }
    return
}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
$directory=Join-Path $root '.local/desktop'
Initialize-RunnerDiagnosticDirectory -Path $directory
$shell=New-Object -ComObject WScript.Shell
$path=Join-Path $directory 'Ephemeral Runner Manager.lnk'
$shortcut=$shell.CreateShortcut($path)
$shortcut.TargetPath=$executable
$shortcut.Arguments="-NoLogo -NoProfile -STA -WindowStyle Hidden -File `"$(Join-Path $PSScriptRoot 'Start-RunnerDesktop.ps1')`""
$shortcut.WorkingDirectory=$root
$shortcut.Description='Manage outbound-only ephemeral Docker GitHub runners'
$shortcut.Save()
Write-Output $path
