[CmdletBinding()]
param(
    [Parameter(Mandatory)][long]$AppId,
    [Parameter(Mandatory)][long]$InstallationId
)
$ErrorActionPreference='Stop'
if ($AppId -lt 1 -or $InstallationId -lt 1) { throw 'Positive App and installation IDs required.' }
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$localDir=Join-Path $repoRoot '.local'
$configPath=Join-Path $localDir 'targets.json'
if (Test-Path -LiteralPath $configPath) { throw 'Local configuration already exists; refusing to overwrite.' }
$example=Get-Content (Join-Path $repoRoot 'config/targets.example.json') -Raw | ConvertFrom-Json
$target=@($example.targets | Where-Object scope -eq 'repository')[0]
$target.appId=$AppId
$target.installationId=$InstallationId
$example.targets=@($target)
New-Item -ItemType Directory -Path (Join-Path $localDir 'secrets') -Force | Out-Null
$example | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding utf8
& (Join-Path $repoRoot 'scripts/config/Test-RunnerConfiguration.ps1') -Path $configPath
