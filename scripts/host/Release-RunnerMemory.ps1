#requires -Version 7.4
[CmdletBinding()]
param([ValidateRange(30,900)][int]$WaitSeconds=420,[ValidateRange(0,3600)][int]$DrainSeconds=300)
$ErrorActionPreference='Stop'
# Compatibility for old desktop windows and callers: cleanup only, keep Docker available.
& (Join-Path $PSScriptRoot 'Stop-RunnerService.ps1') -WaitSeconds $WaitSeconds -DrainSeconds $DrainSeconds
Write-Output 'Disposable runner resources cleaned. Docker stays running; shared images and build caches are retained. Windows/WSL controls cached RAM reclamation.'
