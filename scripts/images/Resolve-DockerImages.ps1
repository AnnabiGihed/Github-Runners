[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$images = @{}
foreach ($entry in @(@{Name='daemon';Tag='docker:29-dind'}, @{Name='client';Tag='docker:29-cli'}, @{Name='runner';Tag='ghcr.io/actions/actions-runner:latest'})) {
    & docker pull $entry.Tag
    if ($LASTEXITCODE -ne 0) { throw 'Official Docker image pull failed.' }
    $details = & docker image inspect $entry.Tag | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $details[0].RepoDigests) { throw 'Image digest resolution failed.' }
    $images[$entry.Name] = $details[0].RepoDigests[0]
}
$images | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $repoRoot 'config/docker-images.lock.json') -Encoding utf8
Write-Output 'Saved immutable official Docker image references.'
