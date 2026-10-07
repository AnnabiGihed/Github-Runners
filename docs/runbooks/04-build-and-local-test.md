# Build and local Docker test

From the repository root, with Docker Desktop running:

```powershell
# Explicit dependency update; review/commit changed digests afterward.
./scripts/images/Resolve-DockerImages.ps1
# Ordinary builds use existing locked inputs.
./scripts/images/Build-RunnerImage.ps1
# Requires accepted privileged job-local Docker; uses no GitHub credentials.
./tests/Test-JobDocker.ps1
```

The local test creates only uniquely named runner-lab resources and removes them in finally cleanup. It does not prune unrelated Docker resources. If cleanup reports a warning, inspect the named test resources and remove only those verified to belong to that test.

The runner image smoke checks an unprivileged user, config/run scripts, jq, Docker CLI, and Buildx without network access. No registration happens. The job-engine test separately verifies a nested container and image build, no host bind mounts, no host published ports, and no Docker TCP API. Passing these tests is not evidence that GitHub workflows or service/container actions work yet.
