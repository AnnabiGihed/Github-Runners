#requires -Version 7.4
[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners')
$ErrorActionPreference='Stop'
if (-not $IsWindows) { throw 'Windows Task Scheduler is required.' }
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $repoRoot 'scripts/controller/RunnerDiagnostics.psm1') -Force
Initialize-RunnerDiagnosticDirectory -Path (Join-Path $repoRoot '.local/diagnostics')
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$executable=(Get-Process -Id $PID).Path
$script=Join-Path $repoRoot 'scripts/controller/Start-RunnerSupervisor.ps1'
$launcher=Join-Path $repoRoot 'scripts/host/Start-RunnerSupervisorHidden.js'
$scriptHost=Join-Path $env:SystemRoot 'System32/wscript.exe'
if (-not (Test-Path -LiteralPath $scriptHost -PathType Leaf)) { throw 'Windows Script Host is required for windowless supervision.' }
if (($executable+$script+$launcher) -match '["%\r\n]') { throw 'Launcher paths must not contain quote, percent or newline characters.' }
$action=New-ScheduledTaskAction -Execute $scriptHost -Argument "//B //NoLogo //E:JScript `"$launcher`" `"$executable`" `"$script`"" -WorkingDirectory $repoRoot
$principal=New-ScheduledTaskPrincipal -UserId $identity.Name -LogonType Interactive -RunLevel Limited
$logon=New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
$watchdog=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$null=Register-ScheduledTask -TaskName $TaskName -Action $action -Principal $principal -Trigger @($logon,$watchdog) -Settings $settings -Description 'Outbound-only ephemeral Docker GitHub runners; interactive-user startup, persistent stop respected.' -Force
Write-Output 'Installed interactive-user logon task and five-minute watchdog. No password stored; use Start-RunnerService.ps1 to resume/start.'
