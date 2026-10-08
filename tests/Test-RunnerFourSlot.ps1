#requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $repoRoot
$statePath=Join-Path $repoRoot '.local/controller/state.json'
$controller=$null;$clients=@()
try {
    $guard=[IO.File]::Open((Join-Path $repoRoot '.local/controller/controller.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $guard.Dispose()
    $current=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if (@($current.slots).Count) { throw 'Drain all existing jobs before four-slot validation.' }
    $psi=[Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($arg in @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-File',(Join-Path $repoRoot 'scripts/controller/Start-RunnerController.ps1'),'-ValidationOnly','-Continuous','-ResetStopRequest','-DrainSeconds','30')) { $psi.ArgumentList.Add($arg) }
    $psi.WorkingDirectory=$repoRoot;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $controller=[Diagnostics.Process]::Start($psi)
    $out=$controller.StandardOutput.ReadToEndAsync();$err=$controller.StandardError.ReadToEndAsync()
    $deadline=[DateTimeOffset]::UtcNow.AddMinutes(4)
    do {
        if ($controller.HasExited) { throw 'Four-slot probe controller exited.' }
        $pool=@(& (Join-Path $repoRoot 'scripts/controller/Test-RunnerPool.ps1'))
        if ($pool.Count -eq 4 -and @($pool | Where-Object { -not $_.Online -or $_.Busy -or $_.Labels -match 'self-hosted|pc-personal' }).Count -eq 0) { break }
        Start-Sleep -Seconds 5
    } while ([DateTimeOffset]::UtcNow -lt $deadline)
    if ($pool.Count -ne 4 -or @($pool | Where-Object { -not $_.Online -or $_.Busy -or $_.Labels -match 'self-hosted|pc-personal' }).Count) { throw 'Need four online probes with only random labels.' }
    $slots=@((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).slots)
    if (@($slots | Where-Object { -not $_.validation }).Count) { throw 'Only validation slots may run local workloads.' }
    $payload=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/four-slot-workload.sh') -Raw
    foreach ($slot in $slots) {
        $psi=[Diagnostics.ProcessStartInfo]::new('docker')
        foreach ($arg in @('exec','-i',$slot.name,'bash','-s')) { $psi.ArgumentList.Add($arg) }
        $psi.UseShellExecute=$false;$psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
        $client=[Diagnostics.Process]::Start($psi)
        $stdout=$client.StandardOutput.ReadToEndAsync();$stderr=$client.StandardError.ReadToEndAsync()
        $client.StandardInput.Write($payload);$client.StandardInput.Close()
        $clients+=@{process=$client;stdout=$stdout;stderr=$stderr;name=$slot.name}
    }
    if (@($clients | Where-Object { -not $_.process.HasExited }).Count -ne 4) { throw 'Four local workload processes did not overlap.' }
    Write-Output 'Verified: four simultaneous local workload processes in four online ephemeral probe environments.'
    foreach ($client in $clients) {
        if (-not $client.process.WaitForExit(240000)) { throw 'Four-slot workload timed out.' }
        $stdout=$client.stdout.GetAwaiter().GetResult()
        if ($client.process.ExitCode -ne 0 -or $stdout -notmatch 'four-slot-workload-passed') { throw 'A four-slot workload failed; inspect protected diagnostics.' }
    }
    $pool=@(& (Join-Path $repoRoot 'scripts/controller/Test-RunnerPool.ps1'))
    if ($pool.Count -ne 4 -or @($pool | Where-Object { -not $_.NoPublishedPorts -or -not $_.UnprivilegedRunner -or -not $_.OnlyJobVolumes -or -not $_.DaemonIsolated -or -not $_.HardenedRunner -or -not $_.ResourceLimitsMatch }).Count) { throw 'Four-slot workload isolation check failed.' }
    Write-Output 'Passed: four concurrent C builds, nested Docker builds, PostgreSQL SQL/service localhost checks; outer isolation retained.'
} finally {
    foreach ($client in $clients) {
        if (-not $client.process.HasExited) { $client.process.Kill() }
        $client.process.Dispose()
    }
    if ($controller -and -not $controller.HasExited) {
        & (Join-Path $repoRoot 'scripts/controller/Request-RunnerControllerStop.ps1') | Out-Null
        if (-not $controller.WaitForExit(60000)) { throw 'Four-slot probe cleanup still draining.' }
    }
    if ($controller) { $controller.Dispose() }
    $remaining=@((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).slots)
    if ($remaining.Count) { throw 'Four-slot test resources retained; inspect before resuming.' }
}
