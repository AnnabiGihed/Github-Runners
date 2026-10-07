[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$AllowIncomplete
)
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
if ($config.schemaVersion -ne 1) { throw 'Unsupported schemaVersion.' }
if ($config.hostMaxRunners -isnot [long] -and $config.hostMaxRunners -isnot [int]) { throw 'hostMaxRunners must be an integer.' }
if ($config.hostMaxRunners -lt 1) { throw 'hostMaxRunners must be positive.' }
if (@($config.targets).Count -eq 0) { throw 'At least one target is required.' }
$ids = @{}
$identities = @{}
$total = 0
foreach ($target in $config.targets) {
    if ($target.id -notmatch '^[a-z0-9][a-z0-9-]{0,47}$') { throw 'Invalid target id.' }
    if ($ids.ContainsKey($target.id)) { throw 'Duplicate target id.' }
    $ids[$target.id] = $true
    if ($target.scope -cnotin @('repository', 'organization')) { throw 'Invalid target scope.' }
    if ($target.owner -notmatch '^[A-Za-z0-9][A-Za-z0-9-]{0,38}$') { throw 'Invalid owner.' }
    if ($target.scope -eq 'repository' -and $target.repository -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Repository scope requires a repository name.' }
    if ($target.scope -eq 'organization' -and $null -ne $target.repository) { throw 'Organization scope must not specify a repository.' }
    $identity = "$($target.scope)/$($target.owner)/$($target.repository)"
    if ($identities.ContainsKey($identity)) { throw 'Duplicate registration target.' }
    $identities[$identity] = $true
    if ($target.maxRunners -isnot [long] -and $target.maxRunners -isnot [int]) { throw 'maxRunners must be an integer.' }
    if ($target.maxRunners -lt 1 -or $target.maxRunners -gt $config.hostMaxRunners) { throw 'Target runner count exceeds the host cap or is not positive.' }
    $total += $target.maxRunners
    if (@($target.labels).Count -eq 0) { throw 'At least one routing label is required.' }
    foreach ($label in $target.labels) {
        if ($label -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$') { throw 'Invalid routing label.' }
    }
    if ($target.privateKeyFile -notmatch '^\.local/secrets/[a-zA-Z0-9_-]+\.pem$') { throw 'Key reference must be a simple file under .local/secrets/.' }
    foreach ($field in @('appId', 'installationId')) {
        $value = $target.$field
        if ($AllowIncomplete -and $null -eq $value) { continue }
        if (($value -isnot [long] -and $value -isnot [int]) -or $value -lt 1) { throw "$field must be a positive integer; incomplete examples are not deployable." }
    }
}
if ($total -gt $config.hostMaxRunners) { throw 'Sum of target capacities exceeds hostMaxRunners.' }
[pscustomobject]@{
    Valid = $true
    TargetCount = @($config.targets).Count
    MaximumJobs = $total
    IncompleteAllowed = [bool]$AllowIncomplete
    Note = 'Structural validation only; installation ownership, permissions, key access, and Docker readiness require live checks.'
}
