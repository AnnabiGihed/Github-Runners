# Reliability review — 2026-10-08

Scope: controller lifecycle, supervision/start/stop/restart, bootstrap/image, App authentication, desktop transactions/actions, diagnostics, disk maintenance and existing recovery evidence. Source review and non-disruptive checks do not establish 100% uptime.

## Result

At 09:45 UTC: four registered, online, idle, ephemeral personal runners; eight running containers; task Running, both locks held, no stop request, state age three seconds. Effective unprivileged user, capabilities, mounts, published ports, daemon Unix socket, resource limits and writable .NET checks passed. CLI 2.102.0; Docker 29.8.2 Linux, eight CPUs, 15.62 GiB and local endpoint. Docker and production supervision were not stopped or restarted. No jobs were cancelled.

**Review remains open. Reliability and availability cannot be described as 100%.** The PC must remain powered, awake, signed in, connected and able to run Docker. GitHub, valid App credentials and maintained runner images are also dependencies. A watchdog is recovery assistance, not redundancy or a guaranteed recovery deadline.

## Findings

| Priority | Finding | Status |
| --- | --- | --- |
| High | Restart requests persistent stop, then throws when draining exceeds its wait. Cleanup continues until the supervisor exits; automatic resume is absent. Long jobs during Apply/restart can leave later workflows queued. | Open, source-confirmed. Check busy jobs before maintenance. Following timeout, wait for drain then Start / resume; never force-remove busy containers. Durable restart intent with explicit-stop precedence needs recovery tests. |
| High | Diagnostics over 64 MiB throw before teardown; a permanently oversized archive can repeatedly retain a completed environment. | Open, source-confirmed. Implement a bounded redacted fallback with cleanup tests. No oversized production archive was injected. |
| Medium | Attached Docker stdout/stderr use ReadToEndAsync throughout the runner lifetime, allowing controller memory growth. | Open, source-confirmed. Diagnostic retention does not bound these streams. Bounded capture needs process-exit/cancellation tests. |
| Medium | Shared cache ownership was inferred from a package command that unrelated builds can use. | Fixed: only exact reviewed approved IDs, with unused/unshared/immutable guards, are eligible. Default maintenance retains cache. |
| Medium | Desktop Status could claim active with inactive supervision. | Fixed: Running task, both locks and state age at most 120 seconds required. GitHub availability still requires Inspect pool. |
| Low | A second CLI-version exec could race completion and falsely report an old version. | Fixed: compare the already captured version. |
| Medium | Controller API/cleanup errors can exit the normal loop and drain idle capacity before retry. | Open resilience limitation. Busy registrations are preserved; per-slot failure isolation and rate-limit-aware retry remain further work. |

## Security and compatibility

Reviewed controls include scoped host-side App tokens, bootstrap stdin, ignored private state, restricted Docker build context, ephemeral registration, ownership-checked cleanup, deregistration before idle destruction, disposable volumes/networks, and unprivileged runner with accepted privileged job-local Docker. Live mounts and port checks passed. No tracked .local, PEM or key files were found.

Privileged Docker remains the accepted trusted-workflow boundary; it does not guarantee hostile public pull-request or LAN isolation. The user temporarily accepted public workflows. Organization setup is deferred. Labels route jobs; they are not an authorization boundary. Pinned base images still require maintenance; APT versions remain flexible at build time. Disabled runner updates require deliberate image refresh within GitHub's deadlines.

## Evidence and limits

Passed seven regression suites: disk, desktop (including healthy/inactive status fixtures), stopped cleanup/retry, configuration, resource budgets, JWT/install checks, diagnostic redaction/retention. Fixtures/offline substitutes did not alter production. Read-only live commands: Test-RunnerService.ps1, Test-RunnerHost.ps1, Test-RunnerPool.ps1 and docker system df. PowerShell parse and git diff checks are required before commit.

Disk snapshot: images 7.103 GB, fresh job volumes 2.396 GB, shared build cache 3.855 GB, writable container layers about 983 kB. Four warm runner/daemon pairs intentionally remain available. Reclaimable is not proof of disposable data. No cache deletion was performed during this review; Windows disk allocation can differ from logical Docker usage.

Prior recovery evidence: [personal operations](../validation/2026-10-08-personal-operations.md). Physical reboot/login, real network loss, assigned GitHub cancellation, representative container actions and live organization onboarding remain unverified. Production interruption tests were deliberately not repeated. Healthy online status is a snapshot, not a guarantee for future jobs.

Run read-only checks in PowerShell 7.4 or later from this repository:

```powershell
./scripts/host/Test-RunnerService.ps1
./scripts/host/Test-RunnerHost.ps1
./scripts/controller/Test-RunnerPool.ps1
docker system df
```

Decision: [0022](../decisions/0022-nondisruptive-reliability-review.md).

Follow-up in decision 0023: restart now resumes after the controller releases its lock, even when the stopping supervisor still holds its lock and busy slots remain. The busy-preserving handoff regression fixture passed. A controller that never releases its lock can still leave stop requested on timeout; explicit resume is still required in that case.
