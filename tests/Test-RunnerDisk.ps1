$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/images/RunnerDisk.psm1') -Force
$legacy='build-essential ca-certificates curl gh git gzip jq openssh-client unzip'
$records=@(
    [pscustomobject]@{ID='obsolete';Description=$legacy;Reclaimable=$true;Shared=$false;Mutable=$false},
    [pscustomobject]@{ID='current';Description='official GitHub CLI keyring layer';Reclaimable=$true;Shared=$false;Mutable=$false},
    [pscustomobject]@{ID='shared';Description=$legacy;Reclaimable=$true;Shared=$true;Mutable=$false},
    [pscustomobject]@{ID='busy';Description=$legacy;Reclaimable=$false;Shared=$false;Mutable=$false},
    [pscustomobject]@{ID='mutable';Description=$legacy;Reclaimable=$true;Shared=$false;Mutable=$true},
    [pscustomobject]@{ID='unrelated';Description='older unrelated build';Reclaimable=$true;Shared=$false;Mutable=$false}
)
$selected=@(Select-ObsoleteRunnerCache -Records $records)
if ($selected.Count -ne 0) { throw 'Unapproved cache must be preserved, even when its command resembles a runner build.' }
$approved=@(Select-ObsoleteRunnerCache -Records $records -ApprovedCacheIds @('unrelated','busy','shared'))
if ($approved.Count -ne 1 -or $approved[0].ID -ne 'unrelated') { throw 'Explicit approval must still respect sharing/use guards.' }
'Disk cache selection tests passed.'
