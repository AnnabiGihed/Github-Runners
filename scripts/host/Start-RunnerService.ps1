[CmdletBinding()]
param([string]$TaskName='EphemeralGitHubRunners',[switch]$Resume)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$stop=Join-Path $repoRoot '.local/controller/stop'
if ($Resume -and (Test-Path -LiteralPath $stop)) {
    # Resuming a still-draining foreground controller would undo its stop request.
    $probe=[IO.File]::Open((Join-Path $repoRoot '.local/controller/controller.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try { Remove-Item -LiteralPath $stop } finally { $probe.Dispose() }
}
if (Test-Path -LiteralPath $stop) { throw 'Persistent stop request exists; use -Resume after drain completes.' }
Start-ScheduledTask -TaskName $TaskName
Write-Output 'Requested scheduled supervisor start.'
