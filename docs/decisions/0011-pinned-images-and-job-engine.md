# 0011: Pinned official images and job-engine smoke tests

- Date: 2026-10-08
- Status: image/tooling implemented; GitHub provisioning pending

## Decision

Resolve official Docker 29 daemon/client and GitHub actions-runner images to immutable registry digests in config/docker-images.lock.json. Resolution uses moving release tags only during explicit updates; builds and daemon tests consume saved digests. Extend GitHub's official runner image with the pinned Docker CLI/plugins and a single-job entrypoint rather than downloading an unsigned third-party runner. Use a narrow .dockerignore so credentials and repository contents do not enter the build context. Enforce LF shell scripts with .gitattributes.

The entrypoint receives registration bootstrap JSON on stdin; no installation access token or App key is passed. It uses --ephemeral and --disableupdate, does not replace existing registrations, waits for its job-local Docker socket, and runs as the image's runner user. Runner image updates must be rebuilt within GitHub's documented update deadlines, including critical updates. No automatic restart of used job containers is permitted.

Use a separate privileged daemon container with only a Unix socket listener, fresh job volumes, private job network, and explicit resource limits. Provisioning must mount the workspace at the same path in runner and daemon and align service network semantics before real workflows. Host paths/socket and credentials are excluded. Nested Docker control remains powerful within the shared Linux kernel and is accepted for trusted jobs only.

## Alternatives and consequences

Third-party all-in-one images obscure provenance and often assume PATs. The default dind entrypoint adds a TCP listener, so the test explicitly invokes dockerd. The runner base is lean, not a full GitHub-hosted toolchain; real repository toolchains still need inspection and image extension. No persistent build cache is selected; job-local daemon image state is deleted with its container and anonymous data volume.

## Evidence and limits

tests/Test-JobDocker.ps1 passed a nested Alpine container and a BuildKit scratch-image build from an unprivileged Docker client. Checked no daemon TCP listener (Docker internal DNS is permitted), no host mounts, no host published ports. After all attempts, no runner-lab containers, labeled volumes, or networks remained. Initial failures exposed internal DNS in the listener check and a writable Docker CLI config requirement; both were corrected and tested.

The smoke fixture Alpine 3.22 tag is test-only and was resolved during execution to sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8. Production image inputs are locked. Runner image build/smoke results are recorded in the change log. GitHub bootstrap, actual container actions/services, concurrency, cancellation, and controller crash recovery are not yet tested.

Sources: [official runner images](https://github.com/actions/runner/pkgs/container/actions-runner), [Docker image source](https://github.com/docker-library/docker), and [GitHub runner reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners).
