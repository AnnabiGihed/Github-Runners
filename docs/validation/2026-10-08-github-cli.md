# Official GitHub CLI rollout — 2026-10-08

`./scripts/images/Build-RunnerImage.ps1` completed successfully. APT fetched `gh` 2.102.0 from `https://cli.github.com/packages`. The downloaded keyring matched the published SHA-256. Build-time and offline executable version checks passed against minimum 2.101.0.

The image reports `gh version 2.102.0 (2026-09-30)`. Its build smoke checks also passed for make, GCC/C++, Git, jq, curl, SSH, gzip, unzip, Docker/buildx, unprivileged execution and the user-local .NET install path. Image config ID: `sha256:415ffd45d011bd152afa34ae85332e4b171503d46819952cf1d3285e734e3d2c`.

Executed `./scripts/host/Restart-RunnerService.ps1`, then `./scripts/host/Test-RunnerService.ps1` and `./scripts/controller/Test-RunnerPool.ps1`. The scheduled service was Running with both locks held, no pending stop and four production slots. All four replacement runners were registered, online and idle, reporting CLI 2.102.0; their identities ended in `1ca665756def`, `587f056aa604`, `bb8287139744`, and `92856c914503`. Ephemeral registration, unprivileged runner, volume-only mounts, no published ports, isolated daemon, hardening, configured resources and writable .NET path checks all passed. This package change does not itself validate new GitHub CLI API operations or rerun application workflows.
