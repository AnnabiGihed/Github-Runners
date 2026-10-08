$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$images = Get-Content (Join-Path $repoRoot 'config/docker-images.lock.json') -Raw | ConvertFrom-Json
foreach ($image in @($images.runner,$images.client)) { if ($image -notmatch '@sha256:[a-f0-9]{64}$') { throw 'Immutable image references required.' } }
& docker build --file (Join-Path $repoRoot 'infra/runner/Dockerfile') --build-arg "RUNNER_IMAGE=$($images.runner)" --build-arg "CLIENT_IMAGE=$($images.client)" --tag local/ephemeral-github-runner:dev $repoRoot
if ($LASTEXITCODE -ne 0) { throw 'Runner image build failed.' }
& docker run --rm --network none --entrypoint bash local/ephemeral-github-runner:dev -c 'test -x ./config.sh && test -x ./run.sh && command -v jq && docker --version && docker buildx version && test "$(id -u)" -ne 0'
if ($LASTEXITCODE -ne 0) { throw 'Runner image smoke check failed.' }
& docker run --rm --network none --entrypoint bash local/ephemeral-github-runner:dev -c 'set -eu; for tool in make gcc g++ gh git jq curl ssh gzip unzip docker; do command -v "$tool"; done; printf "int main(void){return 0;}\n" > /tmp/runner-check.c; gcc /tmp/runner-check.c -o /tmp/runner-check; /tmp/runner-check; gh --version; test "$(id -u)" -ne 0'
if ($LASTEXITCODE -ne 0) { throw 'Workflow toolchain smoke check failed.' }
& docker run --rm --network none --entrypoint bash local/ephemeral-github-runner:dev -c 'set -eu; version=$(gh --version | head -n 1 | cut -d " " -f 3); dpkg --compare-versions "$version" ge 2.101.0; test "$(command -v gh)" = /usr/bin/gh; test -r /etc/apt/keyrings/githubcli-archive-keyring.gpg; grep -Fq "https://cli.github.com/packages stable main" /etc/apt/sources.list.d/github-cli.list; printf "Official GitHub CLI: %s\n" "$version"'
if ($LASTEXITCODE -ne 0) { throw 'Official GitHub CLI minimum-version check failed.' }
& docker run --rm --network none --entrypoint bash local/ephemeral-github-runner:dev -c 'test "$DOTNET_INSTALL_DIR" = /job-work/.dotnet'
if ($LASTEXITCODE -ne 0) { throw 'User-local .NET install path check failed.' }
