#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$fixture=Join-Path $root ('.local/tests/restart-'+[guid]::NewGuid().ToString('N'))
try {
    foreach ($directory in @('scripts/host','scripts/controller','.local/controller')) { New-Item (Join-Path $fixture $directory) -ItemType Directory -Force | Out-Null }
    Copy-Item (Join-Path $root 'scripts/host/Restart-RunnerService.ps1') (Join-Path $fixture 'scripts/host/Restart-RunnerService.ps1')
    Copy-Item (Join-Path $root 'scripts/controller/Request-RunnerControllerStop.ps1') (Join-Path $fixture 'scripts/controller/Request-RunnerControllerStop.ps1')
    # Supervisor still owns its lock, but the controller completed bounded drain.
    '[pscustomobject]@{SupervisorLockHeld=$true;ControllerLockHeld=$false;RecordedSlots=1}' | Set-Content (Join-Path $fixture 'scripts/host/Test-RunnerService.ps1')
    @'
param($TaskName,[switch]$Resume)
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $Resume) { throw 'Expected resume.' }
Remove-Item (Join-Path $root '.local/controller/stop')
New-Item (Join-Path $root '.local/resumed') -ItemType File | Out-Null
'@ | Set-Content (Join-Path $fixture 'scripts/host/Start-RunnerService.ps1')
    '{"slots":[{"name":"busy-fixture"}]}' | Set-Content (Join-Path $fixture '.local/controller/state.json')
    & (Join-Path $fixture 'scripts/host/Restart-RunnerService.ps1') | Out-Null
    if (-not (Test-Path (Join-Path $fixture '.local/resumed'))) { throw 'Live stopping supervisor prevented resume.' }
    if (Test-Path (Join-Path $fixture '.local/controller/stop')) { throw 'Restart left provisioning stopped.' }
    if (@((Get-Content (Join-Path $fixture '.local/controller/state.json') -Raw | ConvertFrom-Json).slots).Count -ne 1) { throw 'Restart changed busy state.' }
    'Restart fixture passed: bounded-drain handoff resumes with supervisor alive and busy state intact. Scheduler effects mocked.'
} finally {
    $resolved=[IO.Path]::GetFullPath($fixture)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup outside workspace refused.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
