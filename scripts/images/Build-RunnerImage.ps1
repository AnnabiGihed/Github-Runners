$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$images = Get-Content (Join-Path $repoRoot 'config/docker-images.lock.json') -Raw | ConvertFrom-Json
foreach ($image in @($images.runner,$images.client)) { if ($image -notmatch '@sha256:[a-f0-9]{64}$') { throw 'Immutable image references required.' } }
& docker build --file (Join-Path $repoRoot 'infra/runner/Dockerfile') --build-arg "RUNNER_IMAGE=$($images.runner)" --build-arg "CLIENT_IMAGE=$($images.client)" --tag local/ephemeral-github-runner:dev $repoRoot
if ($LASTEXITCODE -ne 0) { throw 'Runner image build failed.' }
& docker run --rm --network none --entrypoint bash local/ephemeral-github-runner:dev -c 'test -x ./config.sh && test -x ./run.sh && command -v jq && docker --version && docker buildx version && test "$(id -u)" -ne 0'
if ($LASTEXITCODE -ne 0) { throw 'Runner image smoke check failed.' }
