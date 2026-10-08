[CmdletBinding()]
param()
throw 'Backend shutdown/restart is disabled by the current keep-Docker-running policy (decision 0020).'
$ErrorActionPreference = 'Stop'
$running = (& wsl --list --running --quiet | Out-String).Replace([string][char]0, '').Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect running WSL distributions.' }
if (@($running | Where-Object { $_ -notin @('docker-desktop','docker-desktop-data') }).Count) {
    throw 'Other WSL distributions are running. Coordinate their shutdown before restarting the backend.'
}
$containers = & docker ps --quiet
if ($LASTEXITCODE -ne 0) { throw 'Cannot verify active containers; stopping without restart.' }
if ($containers) { throw 'Running containers detected; drain workloads before restarting Docker.' }
& docker desktop stop
if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop stop failed.' }
& wsl --shutdown
if ($LASTEXITCODE -ne 0) { throw 'WSL shutdown failed; Docker may be stopped.' }
& docker desktop start
if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop start failed; start it manually.' }
Write-Output 'Backend restart requested. Run Test-RunnerHost.ps1 once Docker is ready to verify actual resource allocation.'
