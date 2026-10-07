[CmdletBinding()]
param(
    [string]$ConfigPath='.local/targets.json',
    [Parameter(Mandatory)][string]$TargetId,
    [Parameter(Mandatory)][bool]$TrustedPublicWorkflows
)
$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$targets=@($config.targets | Where-Object id -eq $TargetId)
if ($targets.Count -ne 1) { throw 'Expected exactly one matching target.' }
$targets[0] | Add-Member -NotePropertyName trustedPublicWorkflows -NotePropertyValue $TrustedPublicWorkflows -Force
$config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding utf8
Write-Output 'Saved explicit public workflow trust acknowledgement; this flag is not GitHub access enforcement.'
