# Controller and smoke workflow

Status: two personal registrations verified; real workflow test pending.

From the repository root with the protected local App key and complete target configuration:

```powershell
# Safe bounded registration test: random label, no default labels, no normal jobs.
./scripts/controller/Start-RunnerController.ps1 -ValidationOnly -RunSeconds 120 -DrainSeconds 0
# In another terminal while it is active:
./scripts/controller/Test-RunnerPool.ps1
```

The controller runs in the foreground, replenishes a small warm pool on a 10-second reconciliation loop, and exits after RunSeconds (default one hour). It takes an exclusive local lock, persists owned resource identities before allocation, uses refreshed App installation tokens, and stops after three failed starts. On startup it cleans recorded stale environments rather than reusing workspaces. Busy resources or API cleanup failures retain state and block unsafe reuse. It does not install an autostart service yet.

To request an orderly stop, create an empty ignored .local/controller/stop file; delete it before restarting. Shutdown stops replenishment and drains busy jobs for DrainSeconds (default five minutes). If busy jobs remain or API/network cleanup fails, their state is retained for manual inspection and later reconciliation; do not delete state or globally prune Docker. Forced job cancellation is not implemented.

For production on a public personal target, trustedPublicWorkflows must be explicitly true in its local config after reviewing trigger policy. This is an operator acknowledgment, not enforcement against malicious pull requests. The user intends RaidManager to become private and all its workloads to run self-hosted. Do not silently add fork-trigger workflows while it is temporarily public.

Production invocation: `./scripts/controller/Start-RunnerController.ps1 -RunSeconds 3600`. Each slot uses a privileged daemon capped at 1.5 CPUs/2 GiB and an unprivileged runner capped at 0.5 CPU/1 GiB; four slots fit the configured 8 CPU/16 GiB engine budget but real build performance is not yet measured. The runner shares its own daemon's network namespace so nested service port mappings are reachable from localhost inside that job environment. No mapping reaches the Windows host. Both see the workspace at /job-work.

Each slot also gets a fresh runtime volume seeded from the pinned runner image, mounted read-only at /home/runner/externals in both runner and daemon. GitHub container jobs can then bind the runner's bundled Node runtimes at matching paths. This prepares compatibility; real container jobs still need testing.

## First real job

The repository-managed template is config/workflows/runner-smoke.yml. Copy it into RaidManager as .github/workflows/runner-smoke.yml on a trusted branch and manually run it once production pc-personal runners are active. It executes two matrix jobs, tests a fresh marker, nested build, Redis connectivity, and a Docker container action. Run it again to verify fresh runner identities/workspaces, then inspect cleanup. The current App has no Contents/Workflows write permission; no such permission has been added merely to publish the test.

Nested service port mappings are permitted within disposable job environments; the host still has no published ports. The smoke Redis/Alpine tags are fixtures, not production dependency pins. Production workflows must manage their own image/action versions.

## Remaining limitations

Controller diagnostics currently include bounded registration-phase stderr with the registration token redacted, rotated Docker logs while containers exist, and lifecycle status. Durable full runner diagnostic export, LAN egress restrictions, cancellation/failure injection, unattended recovery, autostart, real container/service actions, and organization registration remain pending. This is not a completed production rollout. Do not print raw job logs or authentication objects during diagnosis.
