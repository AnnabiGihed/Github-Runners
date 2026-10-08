Set-StrictMode -Version Latest
function Select-ObsoleteRunnerCache {
    param([object[]]$Records,[string[]]$ApprovedCacheIds=@())
    foreach ($record in $Records) {
        if (-not $record.Reclaimable -or $record.Shared -or $record.Mutable) { continue }
        # Build commands do not establish ownership in a shared builder.
        if ($record.ID -in $ApprovedCacheIds) { $record }
    }
}
Export-ModuleMember -Function Select-ObsoleteRunnerCache
