#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$fixture=Join-Path $root ('.local/tests/hidden-launcher-'+[guid]::NewGuid().ToString('N'))
$process=$null
try {
    $supervisor=Join-Path $fixture 'scripts/controller/fixture supervisor.ps1'
    New-Item (Split-Path $supervisor -Parent) -ItemType Directory -Force | Out-Null
    @'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
[IO.File]::WriteAllText((Join-Path $root 'started'),[string]$PID)
Start-Sleep -Seconds 3
exit 17
'@ | Set-Content -LiteralPath $supervisor
    $runtime=(Get-Process -Id $PID).Path
    $psi=[Diagnostics.ProcessStartInfo]::new((Join-Path $env:SystemRoot 'System32/wscript.exe'))
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    foreach ($arg in @('//B','//NoLogo','//E:JScript',(Join-Path $root 'scripts/host/Start-RunnerSupervisorHidden.js'),$runtime,$supervisor)) { $psi.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::Start($psi)
    $deadline=[DateTimeOffset]::UtcNow.AddSeconds(15)
    while (-not (Test-Path (Join-Path $fixture 'started'))) {
        if ($process.HasExited -or [DateTimeOffset]::UtcNow -gt $deadline) { throw 'Windowless fixture did not start its child.' }
        Start-Sleep -Milliseconds 100
    }
    if ($process.HasExited) { throw 'Launcher exited before the supervised child.' }
    if (-not $process.WaitForExit(15000) -or $process.ExitCode -ne 17) { throw 'Child exit code/lifetime not propagated.' }
    $probe=Join-Path $fixture 'resolver.ps1'
    @'
param($Root,$Runtime)
$ErrorActionPreference='Stop'
$env:ProgramFiles=$PSScriptRoot;$env:LOCALAPPDATA=$PSScriptRoot
function Get-Command { return $null }
function Get-ScheduledTask {
    [pscustomobject]@{Actions=@([pscustomobject]@{Execute=(Join-Path $env:SystemRoot 'System32/wscript.exe');Arguments=('//B //NoLogo //E:JScript "fixture launcher.js" "'+$Runtime+'" "fixture supervisor.ps1"')})}
}
. (Join-Path $Root 'scripts/desktop/Find-RunnerPowerShell.ps1')
if ((Find-RunnerPowerShell) -ine $Runtime) { throw 'Wrapped task runtime discovery failed.' }
'Windows PowerShell 5.1 resolved the runtime from the windowless task.'
'@ | Set-Content -LiteralPath $probe
    & (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') -NoProfile -File $probe -Root $root -Runtime $runtime
    if ($LASTEXITCODE -ne 0) { throw 'Windowless task resolver fixture failed.' }
    'Windowless launcher passed: spaced paths, child launch, synchronous tracking and exit-code propagation. No production processes changed.'
} finally {
    if ($process) { $process.Dispose() }
    $resolved=[IO.Path]::GetFullPath($fixture)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup outside workspace refused.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
