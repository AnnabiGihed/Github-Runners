#requires -Version 7.4
[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $repoRoot
$statePath=Join-Path $repoRoot '.local/controller/state.json'
$controller=Join-Path $repoRoot 'scripts/controller/Start-RunnerController.ps1'
$process=$null
$faultPath=Join-Path $repoRoot '.local/tests/api-unavailable'
New-Item -ItemType Directory -Path (Split-Path $faultPath -Parent) -Force | Out-Null
function Start-ProbeController {
    $psi=[Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($arg in @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-File',$controller,'-ConfigPath',$ConfigPath,'-ValidationOnly','-Continuous','-ResetStopRequest','-DrainSeconds','30','-ValidationApiFailureFile',$faultPath)) { $psi.ArgumentList.Add($arg) }
    $psi.WorkingDirectory=$repoRoot;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $child=[Diagnostics.Process]::Start($psi)
    $script:probeOut=$child.StandardOutput.ReadToEndAsync();$script:probeErr=$child.StandardError.ReadToEndAsync()
    return $child
}
function Wait-Probe([string[]]$Exclude=@()) {
    $deadline=[DateTimeOffset]::UtcNow.AddMinutes(4)
    do {
        if ($process.HasExited) { throw 'Probe controller exited; inspect protected diagnostics.' }
        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        foreach ($slot in @($state.slots | Where-Object { $_.PSObject.Properties['validation'] -and $_.validation -and $_.name -notin $Exclude })) {
            $running=& docker inspect $slot.name --format '{{.State.Running}}' 2>$null
            if ($LASTEXITCODE -ne 0 -or $running -ne 'true') { continue }
            $config=& docker exec $slot.name cat /home/runner/.runner 2>$null
            if ($LASTEXITCODE -eq 0 -and (($config -join '').TrimStart([char]0xFEFF) | ConvertFrom-Json).ephemeral) { return $slot }
        }
        Start-Sleep -Seconds 5
    } while ([DateTimeOffset]::UtcNow -lt $deadline)
    throw 'Timed out waiting for an ephemeral validation probe.'
}
function Assert-Removed($slot) {
    & docker inspect $slot.name 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { throw 'Old runner still exists.' }
    & docker inspect $slot.daemon 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { throw 'Old daemon still exists.' }
    foreach ($volume in @($slot.work,$slot.socket,$slot.externals)) {
        & docker volume inspect $volume 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { throw 'Old volume still exists.' }
    }
    & docker network inspect $slot.network 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { throw 'Old network still exists.' }
}
try {
    # Acquire/release the production lock before resetting its stop request.
    $guard=[IO.File]::Open((Join-Path $repoRoot '.local/controller/controller.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $guard.Dispose()
    $process=Start-ProbeController
    $first=Wait-Probe
    & docker exec $first.name bash -c 'printf recovery-fixture > /job-work/recovery-marker'
    if ($LASTEXITCODE -ne 0) { throw 'Marker creation failed.' }
    # Random probe labels and no default labels prevent normal workflow selection.
    & docker kill $first.name | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Probe failure injection failed.' }
    $deadline=[DateTimeOffset]::UtcNow.AddMinutes(3)
    do {
        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if (-not @($state.slots | Where-Object name -eq $first.name).Count) { break }
        Start-Sleep -Seconds 5
    } while ([DateTimeOffset]::UtcNow -lt $deadline)
    Assert-Removed $first
    $second=Wait-Probe -Exclude $first.name
    & docker exec $second.name test ! -e /job-work/recovery-marker
    if ($LASTEXITCODE -ne 0) { throw 'Workspace reused after runner failure.' }
    Write-Output 'Passed: killed probe runner, daemon/volumes/network removed, distinct runner and fresh workspace.'
    $before=@((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).slots | Where-Object { $_.PSObject.Properties['validation'] -and $_.validation })
    $process.Kill();$process.WaitForExit();$process.Dispose()
    $process=Start-ProbeController
    $null=Wait-Probe -Exclude @($before.name)
    foreach ($slot in $before) { Assert-Removed $slot }
    Write-Output 'Passed: abrupt controller exit recovered persisted probe state without workspace reuse.'
    $preserved=@((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).slots)
    New-Item -ItemType File -Path $faultPath -Force | Out-Null
    if (-not $process.WaitForExit(60000)) { throw 'API outage did not stop controller within its validation drain bound.' }
    $after=@((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).slots)
    foreach ($slot in $preserved) { if ($slot.name -notin $after.name) { throw 'API outage lost recorded resource identities.' } }
    foreach ($slot in $preserved) {
        & docker volume inspect $slot.work 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'API outage destroyed a workspace without remote reconciliation.' }
    }
    Remove-Item -LiteralPath $faultPath
    $process.Dispose();$process=Start-ProbeController
    $null=Wait-Probe -Exclude @($preserved.name)
    Write-Output 'Passed: injected API outage preserved state/workspaces; restart after restored API reconciled probes.'
    $pool=@(& (Join-Path $repoRoot 'scripts/controller/Test-RunnerPool.ps1') -ConfigPath $ConfigPath)
    if (@($pool | Where-Object { -not $_.ConfiguredEphemeral -or -not $_.UnprivilegedRunner -or -not $_.OnlyJobVolumes -or -not $_.NoPublishedPorts }).Count) { throw 'Recovered pool invariant failed.' }
    Write-Output "Inspected $($pool.Count) recovered runners; pool invariants passed."
} finally {
    if (Test-Path -LiteralPath $faultPath) { Remove-Item -LiteralPath $faultPath }
    if ($process -and -not $process.HasExited) {
        & (Join-Path $repoRoot 'scripts/controller/Request-RunnerControllerStop.ps1') | Out-Null
        if (-not $process.WaitForExit(60000)) { throw 'Probe controller still draining; do not start a competing controller.' }
    }
    if ($process) { $process.Dispose() }
}
