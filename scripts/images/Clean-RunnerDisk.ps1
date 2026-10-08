#requires -Version 7.4
[CmdletBinding()]
param([switch]$Apply,[string[]]$ApprovedCacheIds=@())
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RunnerDisk.psm1') -Force
foreach ($id in $ApprovedCacheIds) { if ($id -notmatch '^[a-z0-9]{12,64}$') { throw 'Invalid explicitly approved cache ID.' } }
$inspection=& docker buildx inspect 2>$null
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the current builder.' }
$match=@($inspection | Select-String '^Name:\s+(\S+)\s*$' | Select-Object -First 1)
if ($match.Count -ne 1) { throw 'Cannot safely identify the current builder.' }
$builder=$match[0].Matches[0].Groups[1].Value
$raw=& docker buildx du --builder $builder --format json
if ($LASTEXITCODE -ne 0) { throw 'Build cache inspection failed.' }
$records=@($raw | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
$candidates=@(Select-ObsoleteRunnerCache -Records $records -ApprovedCacheIds $ApprovedCacheIds | Sort-Object CreatedAt -Descending)
foreach ($candidate in $candidates) {
    [pscustomobject]@{Builder=$builder;CacheId=$candidate.ID;Size=$candidate.Size;Action=if ($Apply) { 'Remove obsolete unused cache' } else { 'Preview only' }}
    if ($Apply) {
        # This builder supports ID selectors; its boolean filters do not match du records.
        # BuildKit protects records in use; no image/container/volume removal is requested.
        & docker buildx prune --builder $builder --force --filter "id=$($candidate.ID)"
        if ($LASTEXITCODE -ne 0) { throw 'Scoped cache removal failed; no broader prune attempted.' }
    }
}
if (-not $candidates.Count) { 'No verified obsolete cache candidates. Current/recent or unproven reusable data retained.' }
if ($Apply) {
    # Only this project's dangling image versions older than a week; tagged/in-use images stay.
    & docker image prune --force --filter 'label=runner.project=ephemeral-github-runners' --filter 'until=168h'
    if ($LASTEXITCODE -ne 0) { throw 'Project-scoped obsolete image cleanup failed.' }
}
& docker system df
if ($LASTEXITCODE -ne 0) { throw 'Final disk inventory failed.' }
'Docker and supervision stay available. Active job data is deleted by normal single-job cleanup; no global prune or backend shutdown is used.'
