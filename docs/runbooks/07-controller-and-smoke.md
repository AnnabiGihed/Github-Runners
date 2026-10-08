# Controller and smoke workflow

Status: personal workflows have executed. Unattended operation is described in [runbook 08](08-personal-operations.md); this page retains bounded/manual testing instructions.

From the repository root with the protected local App key and complete target configuration:

```powershell
# Safe bounded registration test: random label, no default labels, no normal jobs.
./scripts/controller/Start-RunnerController.ps1 -ValidationOnly -RunSeconds 120 -DrainSeconds 0
# In another terminal while it is active:
./scripts/controller/Test-RunnerPool.ps1
```

The controller runs in the foreground, replenishes a small warm pool on a 10-second reconciliation loop, and exits after RunSeconds (default one hour) unless -Continuous is supplied. It takes an exclusive local lock, persists owned resource identities before allocation, uses refreshed App installation tokens, and stops after three failed starts. On startup it retains busy jobs and cleans idle/stopped recorded environments rather than reusing workspaces. The installed scheduled supervisor provides logon startup and retries; see runbook 08.

To request an orderly stop, create an empty ignored .local/controller/stop file; delete it before restarting. Shutdown stops replenishment and drains busy jobs for DrainSeconds (default five minutes). If busy jobs remain or API/network cleanup fails, their state is retained for manual inspection and later reconciliation; do not delete state or globally prune Docker. Forced job cancellation is not implemented.

Saved stop tooling: `./scripts/controller/Request-RunnerControllerStop.ps1`. After the old session exits, start the new image with `./scripts/controller/Start-RunnerController.ps1 -ResetStopRequest -RunSeconds 3600`. The reset happens only after acquiring the exclusive controller lock.

For production on a public personal target, trustedPublicWorkflows must be explicitly true in its local config after reviewing trigger policy. This is an operator acknowledgment, not enforcement against malicious pull requests. The user intends RaidManager to become private and all its workloads to run self-hosted. Do not silently add fork-trigger workflows while it is temporarily public.

Manual bounded invocation: `./scripts/controller/Start-RunnerController.ps1 -RunSeconds 3600`. Resource limits now come from config/runner-resources.json: one CPU/2 GiB per privileged daemon and one CPU/1.5 GiB per unprivileged runner. Four slots allocate eight CPUs/14 GiB plus a 1.5-GiB engine reserve, validated against the live engine. The runner shares its own daemon's network namespace so nested service port mappings are reachable from localhost inside that job environment. No mapping reaches the Windows host. Both see the workspace at /job-work.

Each slot also gets a fresh runtime volume seeded from the pinned runner image, mounted read-only at /home/runner/externals in both runner and daemon. GitHub container jobs can then bind the runner's bundled Node runtimes at matching paths. This prepares compatibility; real container jobs still need testing.

## First real job

The repository-managed template is config/workflows/runner-smoke.yml. Copy it into RaidManager as .github/workflows/runner-smoke.yml on a trusted branch and manually run it once production pc-personal runners are active. It executes two matrix jobs, tests a fresh marker, nested build, Redis connectivity, and a Docker container action. Run it again to verify fresh runner identities/workspaces, then inspect cleanup. The current App has no Contents/Workflows write permission; no such permission has been added merely to publish the test.

Nested service port mappings are permitted within disposable job environments; the host still has no published ports. The smoke Redis/Alpine tags are fixtures, not production dependency pins. Production workflows must manage their own image/action versions.

## Remaining limitations

To audit project automation routing without credentials:

```powershell
./scripts/github/Get-PublicWorkflowRouting.ps1 -TargetId personal-raidmanager -Ref main -WorkflowNames project-hierarchy.yml,dependency-task.yml,review.yml
```

These workflows were verified on public RaidManager main with self-hosted/Linux/pc-personal labels on 2026-10-08. Routing configuration is separate from execution success. Omitting WorkflowNames discovers files through the public contents API, subject to its unauthenticated rate limit. Private repositories need an independently authorized inspection method; this tool does not substitute a PAT or expose the provisioning App credentials.

Runner/worker diagnostic tails are checkpointed and retained outside containers with redaction, restrictive permissions and storage/age bounds. Failure/crash/API-outage probe tests and scheduled supervision are documented in runbook 08 and the operations validation report. LAN egress restrictions, physical reboot/unplug tests, and real GitHub container-action/cancellation evidence must be distinguished from tested local Docker behavior. Organization registration is deferred. Do not print raw job logs or authentication objects during diagnosis.
