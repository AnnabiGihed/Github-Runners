#requires -Version 7.4
# Live regression for the 2026-10-09 mid-job shutdown: a control event on the
# supervisor's console (window close, Ctrl+C/Break) must not reach an attached runner
# container, and a hard-terminated supervisor/CLI must leave the container running.
# A legacy (pre-fix) inherited-console launch is the negative control proving the
# check detects signal forwarding. Uses only the local runner image; never pulls.
$ErrorActionPreference='Stop'
if (-not $IsWindows) { throw 'Windows console semantics are under test.' }
$root=Split-Path $PSScriptRoot -Parent
$image='local/ephemeral-github-runner:dev'
& docker image inspect $image --format '{{.Id}}' 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Build the local runner image before this test.' }
$runId=[guid]::NewGuid().ToString('N')
$fixture=Join-Path $root ".local/tests/console-$runId"
New-Item $fixture -ItemType Directory -Force | Out-Null
$pwsh=(Get-Process -Id $PID).Path
$containers=@();$processes=@()
@'
param($Module,$Container,$Mode,$Ready)
$ErrorActionPreference='Stop'
if ($Mode -eq 'isolated') {
    Import-Module $Module -Force
    $attachment=Start-RunnerAttachment -Container $Container
} else {
    # Pre-fix controller launch: CLI inherits this (supervisor) console.
    $psi=[Diagnostics.ProcessStartInfo]::new('docker')
    foreach ($arg in @('start','-ai',$Container)) { $psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute=$false;$psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::Start($psi)
    $attachment=@{process=$process;stdout=$process.StandardOutput.ReadToEndAsync();stderr=$process.StandardError.ReadToEndAsync()}
}
$attachment.process.StandardInput.WriteLine('{"fixture":true}');$attachment.process.StandardInput.Close()
Set-Content -LiteralPath $Ready -Value $attachment.process.Id
Start-Sleep -Seconds 300
'@ | Set-Content (Join-Path $fixture 'supervisor.ps1') -Encoding utf8
@'
param([uint32]$ConsoleOwner)
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ConsoleSignal {
    delegate bool Handler(uint type);
    [DllImport("kernel32.dll")] static extern bool FreeConsole();
    [DllImport("kernel32.dll")] static extern bool AttachConsole(uint pid);
    [DllImport("kernel32.dll")] static extern bool SetConsoleCtrlHandler(Handler h, bool add);
    [DllImport("kernel32.dll")] static extern bool GenerateConsoleCtrlEvent(uint ev, uint group);
    static readonly Handler Ignore = t => true;
    public static int Break(uint pid) {
        FreeConsole();
        if (!AttachConsole(pid)) return 10;
        SetConsoleCtrlHandler(Ignore, true);
        // CTRL_BREAK to every process on the target console, as a window close would.
        if (!GenerateConsoleCtrlEvent(1, 0)) return 11;
        System.Threading.Thread.Sleep(2000);
        return 0;
    }
}
"@
exit [ConsoleSignal]::Break($ConsoleOwner)
'@ | Set-Content (Join-Path $fixture 'signal.ps1') -Encoding utf8
function Start-Hidden([string[]]$Arguments) {
    # Own windowless console, like the scheduled wscript-hidden supervisor.
    $psi=[Diagnostics.ProcessStartInfo]::new($pwsh)
    foreach ($arg in @('-NoLogo','-NoProfile','-NonInteractive','-File')+$Arguments) { $psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    return [Diagnostics.Process]::Start($psi)
}
function Get-Fixture([string]$Container) {
    $state=(& docker inspect $Container --format '{{.State.Running}}').Trim()
    $logs=(& docker logs $Container 2>&1) -join "`n"
    return @{running=($state -eq 'true');signalled=($logs -match 'signalled');bootstrap=($logs -match 'bootstrap:\d+')}
}
function Invoke-Scenario([string]$Mode) {
    $name="runner-console-$runId-$Mode"
    $script:containers+=$name
    $null=& docker create -i --name $name --label "runner.test=$runId" --network none --restart no --entrypoint bash $image -c 'IFS= read -r line; echo "bootstrap:${#line}"; trap "echo signalled; exit 143" TERM INT; while :; do sleep 1 & wait $!; done'
    if ($LASTEXITCODE -ne 0) { throw 'Fixture container creation failed.' }
    $ready=Join-Path $fixture "$Mode.ready"
    $supervisor=Start-Hidden @((Join-Path $fixture 'supervisor.ps1'),(Join-Path $root 'scripts/controller/RunnerAttachment.psm1'),$name,$Mode,$ready)
    $script:processes+=$supervisor.Id
    for ($i=0;$i -lt 60 -and -not (Test-Path $ready);$i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Test-Path $ready)) { throw "$Mode stand-in supervisor did not attach." }
    $cli=[int](Get-Content $ready -Raw);$script:processes+=$cli
    for ($i=0;$i -lt 30 -and -not (Get-Fixture $name).bootstrap;$i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Get-Fixture $name).bootstrap) { throw "$Mode bootstrap was not delivered over stdin." }
    $sender=Start-Hidden @((Join-Path $fixture 'signal.ps1'),[string]$supervisor.Id)
    if (-not $sender.WaitForExit(30000) -or $sender.ExitCode -ne 0) { throw "Console control event could not be generated ($Mode)." }
    Start-Sleep -Seconds 5
    $afterEvent=Get-Fixture $name
    # Model a supervisor crash/task termination: hard-kill stand-in and CLI.
    foreach ($id in @($supervisor.Id,$cli)) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 3
    return @{event=$afterEvent;crash=(Get-Fixture $name)}
}
try {
    $legacy=Invoke-Scenario 'legacy'
    if ($legacy.event.running -or -not $legacy.event.signalled) { throw 'Negative control did not reproduce forwarding; the check cannot detect the defect here.' }
    $isolated=Invoke-Scenario 'isolated'
    if ($isolated.event.signalled -or -not $isolated.event.running) { throw 'Supervisor console event reached the runner container.' }
    if ($isolated.crash.signalled -or -not $isolated.crash.running) { throw 'Hard-terminated supervisor/attachment stopped the runner container.' }
    'Console isolation passed: legacy inherited-console attach forwarded the event and stopped its container (control); isolated attach kept the container running through a supervisor console event and a hard supervisor/CLI kill.'
} finally {
    foreach ($id in $processes) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
    foreach ($name in $containers) {
        $label=(& docker inspect $name --format '{{index .Config.Labels "runner.test"}}' 2>$null)
        if ($LASTEXITCODE -eq 0 -and $label -eq $runId) { & docker rm -f $name 2>$null | Out-Null }
    }
    $resolved=[IO.Path]::GetFullPath($fixture)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup outside workspace refused.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
