[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$configPath = Join-Path $env:USERPROFILE '.wslconfig'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$backupDir = Join-Path $repoRoot '.local/host-backups'
$lines = if (Test-Path -LiteralPath $configPath) { @(Get-Content -LiteralPath $configPath) } else { @() }
$sectionIndexes = @(for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[wsl2\]\s*$') { $i } })
if ($sectionIndexes.Count -gt 1) { throw 'Duplicate wsl2 sections; resolve manually before applying resources.' }
if ($sectionIndexes.Count -eq 0) { $lines += @('[wsl2]'); $start = $lines.Count - 1 } else { $start = $sectionIndexes[0] }
$end = $lines.Count
for ($i = $start + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[') { $end = $i; break } }
$seen = @{}
$newLines = [Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq $end) {
        foreach ($key in @('memory','processors')) { if (-not $seen[$key]) { $newLines.Add($(if ($key -eq 'memory') { 'memory=16GB' } else { 'processors=8' })) } }
    }
    if ($i -gt $start -and $i -lt $end -and $lines[$i] -match '^\s*(memory|processors)\s*=') {
        $key = $Matches[1].ToLowerInvariant()
        if ($seen[$key]) { throw 'Duplicate resource keys; resolve manually before applying resources.' }
        $seen[$key] = $true
        $newLines.Add($(if ($key -eq 'memory') { 'memory=16GB' } else { 'processors=8' }))
    } else { $newLines.Add($lines[$i]) }
}
if ($end -eq $lines.Count) {
    foreach ($key in @('memory','processors')) { if (-not $seen[$key]) { $newLines.Add($(if ($key -eq 'memory') { 'memory=16GB' } else { 'processors=8' })) } }
}
$newContent = ($newLines -join "`r`n") + "`r`n"
if ((Test-Path -LiteralPath $configPath) -and (Get-Content -LiteralPath $configPath -Raw) -eq $newContent) {
    Write-Output 'Approved resource values already configured; no change.'
    return
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
if (Test-Path -LiteralPath $configPath) {
    Copy-Item -LiteralPath $configPath -Destination (Join-Path $backupDir ('wslconfig-' + [guid]::NewGuid().ToString('N') + '.bak'))
}
[IO.File]::WriteAllText($configPath, $newContent, [Text.UTF8Encoding]::new($false))
Write-Output 'Configured WSL for 8 CPUs and 16 GB RAM. No restart performed; running allocation may still use previous limits.'
