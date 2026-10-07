$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$stateDir=Join-Path $repoRoot '.local/controller'
if (-not (Test-Path -LiteralPath $stateDir)) { throw 'No controller state directory found.' }
New-Item -ItemType File -Path (Join-Path $stateDir 'stop') -Force | Out-Null
Write-Output 'Requested graceful stop: no replenishment, idle cleanup, busy jobs drain under the controller timeout.'
