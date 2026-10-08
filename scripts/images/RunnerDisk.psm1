Set-StrictMode -Version Latest
function Select-ObsoleteRunnerCache {
    param([object[]]$Records,[string[]]$ApprovedCacheIds=@())
    foreach ($record in $Records) {
        if (-not $record.Reclaimable -or $record.Shared -or $record.Mutable) { continue }
        # Exact legacy runner tool layer replaced by the official gh package source.
        $obsoleteRunnerLayer=$record.Description -like '*build-essential ca-certificates curl gh git gzip jq openssh-client unzip*'
        if ($obsoleteRunnerLayer -or $record.ID -in $ApprovedCacheIds) { $record }
    }
}
Export-ModuleMember -Function Select-ObsoleteRunnerCache
