# Personal runner operations

Organization setup is deferred. Personal configuration has four slots within the four-slot host cap. All commands run from this repository in PowerShell 7.4+ under the Windows account owning Docker Desktop and the App key.

## Install, start and stop

```powershell
./scripts/host/Install-RunnerScheduledTask.ps1
./scripts/host/Start-RunnerService.ps1 -Resume
Get-ScheduledTask -TaskName EphemeralGitHubRunners
./scripts/controller/Test-RunnerPool.ps1
./scripts/host/Test-RunnerService.ps1
```

The task starts at login and retries through a five-minute watchdog. It runs the continuous supervisor hidden, without a stored password or elevated runtime. Sign in and keep the PC awake for availability. Normal jobs can queue while it is offline. The supervisor waits for Docker, starts Desktop if needed, and retries a failed controller after 60 seconds. Do not launch a second controller manually while this task is active.

To stop replenishment and drain jobs:

```powershell
./scripts/controller/Request-RunnerControllerStop.ps1
```

Stop is persistent: watchdog invocations respect it. The controller drains for five minutes and preserves busy state if that expires. Resume only after the controller lock is released. It will preserve any still-busy previous job and reconcile it after completion. `Start-RunnerService.ps1 -Resume` refuses to clear a stop request during an active drain.

To remove automatic startup, request graceful stop first, wait for idle cleanup, then run `Unregister-ScheduledTask -TaskName EphemeralGitHubRunners -Confirm:$false`. Do not force-stop the task as routine maintenance.

## Image updates

GitHub requires timely runner updates when auto-update is disabled. Check official runner releases at least weekly and rebuild within 30 days of each release; critical updates can require earlier action. Keep provenance/digest changes reviewed and recorded.

```powershell
./scripts/images/Resolve-DockerImages.ps1
./scripts/images/Build-RunnerImage.ps1
./scripts/controller/Request-RunnerControllerStop.ps1
# Wait until the supervisor/controller have stopped and jobs have drained.
./scripts/host/Start-RunnerService.ps1 -Resume
```

The resolver updates dependency inputs, so review the lock diff before committing. Existing sessions pin their runner image ID. Re-register the scheduled task if its PowerShell path changes. A Windows restart automatically resumes after login, unless a persistent stop request exists.

After reviewed controller/script changes, `./scripts/host/Restart-RunnerService.ps1` performs stop, waits for both locks to be released, then resumes the supervisor. It does not forcibly kill jobs. If drain times out, busy state is preserved and the next controller waits for those jobs; if the locks remain held after the helper's wait bound, it leaves stop requested and reports the limitation.

## Diagnostics and validation

For a complete stop including retained environments, use `./scripts/host/Stop-RunnerService.ps1`. Unlike merely stopping the scheduled task, it persists stop and reuses cleanup-only reconciliation after locks clear. Supervision keeps retrying busy-environment cleanup after drain expiry without replenishment. A bounded stop can still report pending jobs or API/engine recovery; no busy job is forcibly removed.

Current policy (decision 0020): Docker stays running. `Release-RunnerMemory.ps1` is now a compatibility alias for Stop & clean. Disposable job containers, volumes and networks are destroyed; shared host images/build cache and unrelated workloads are retained. Global cache dropping, image pruning and Docker/WSL shutdown are prohibited. Process memory is released by teardown; cached RAM reclamation remains platform-managed. The backend restart helper and Docker cold-start test are disabled; prior cold-start evidence below is historical.

The runner Dockerfile installs `gh` from GitHub's official signed APT repository, with a verified keyring checksum and minimum version 2.101.0 (decision 0017). Build with `./scripts/images/Build-RunnerImage.ps1`, gracefully restart with `./scripts/host/Restart-RunnerService.ps1`, then run `./scripts/controller/Test-RunnerPool.ps1` to inspect live CLI versions. Use an uncached Docker build when deliberately refreshing otherwise unchanged package layers, supplying the same digest build arguments from `config/docker-images.lock.json`. Reverify the official published checksum if key rotation causes a build failure.

Ignored `.local/diagnostics/` contains redacted runner/worker tails and supervisor status logs, protected by current-user-only access. Retention is seven days/200 MiB; each runner output is at most 2 MiB. Never commit or share raw diagnostic files. Redaction cannot identify every arbitrary application secret. Logs are checkpointed every minute and before deletion; power loss can lose recent entries.

```powershell
./tests/Test-RunnerDiagnostics.ps1 -Docker
./tests/Test-RunnerConfiguration.ps1
./tests/Test-RunnerResources.ps1
./tests/Test-RunnerGitHub.ps1
./tests/Test-JobDocker.ps1
./scripts/github/Get-PublicWorkflowStatus.ps1 -Count 10 -AppAuthentication
```

The status command uses a transient existing App token and revokes it after reading public workflow status; no PAT or expanded permission is used. Private Actions access may require a separately approved permission change.

Recovery tests intentionally kill only randomly labeled probe runners and a test-owned controller. First stop the supervisor and wait for the controller lock to be released:

```powershell
./tests/Test-RunnerRecovery.ps1
# After all existing jobs/environments have drained:
./tests/Test-RunnerFourSlot.ps1
./scripts/host/Start-RunnerService.ps1 -Resume
```

Do not run recovery tests alongside production provisioning. Tests preserve existing busy production jobs and leave a persistent stop request for an explicit controlled resume. Four online registrations are separate from successful simultaneous workload performance. Do not restart Docker/WSL or inject real network outages while unrelated jobs are active.

The four-slot test requires zero existing environments and exercises four concurrent C/Docker builds, PostgreSQL SQL/localhost connectivity and bundled Node access inside nested containers, then deletes all probe resources. Fixture image tags are test-only (`postgres:17-alpine`, `node:24-bookworm-slim`); production image pins remain in the lock file. This is not a GitHub-dispatched four-job matrix.

For a guarded Desktop cold-start test, first request graceful stop. `./tests/Test-RunnerDockerRestart.ps1` waits for all controller/supervisor locks and slots to clear, refuses to interrupt other running containers, stops Docker Desktop, then resumes the scheduled supervisor and verifies automatic engine/four-runner restoration. It leaves production running. A physical Windows reboot/logon and real GitHub job cancellation were not performed by this test.

Current personal scaling trial (decision 0023): demand mode keeps zero runner slots when idle and creates up to four for matching queued jobs. Docker and the supervisor remain running. Zero slots is expected only with valid demand polling and active supervision; see runbook 10 for activation, live evidence and warm rollback.

## Recurring blank terminal — 2026-10-09 correction

The five-minute watchdog is intentional; a visible console is not. Closing the console interrupts supervision and can cause the next watchdog launch. The task now uses the repository's windowless JScript launcher through wscript.exe, waiting for PowerShell so the task remains Running. Never disable the watchdog merely to suppress a window. Stop & clean remains the deliberate way to pause provisioning, keeping Docker running.

Update an existing installation from PowerShell 7.4+:

```powershell
./scripts/host/Install-RunnerScheduledTask.ps1
./scripts/host/Start-RunnerService.ps1
./scripts/host/Test-RunnerService.ps1
```

Installing updates future task launches; it does not kill a running supervisor. If an old instance remains, transition gracefully when idle. Windows Script Host/JScript must be enabled; the wrapper fixture detects unavailable execution. The runtime is still discovered by the desktop launcher from the wrapped task arguments. No passwords, PATs, ports or Docker settings are changed. See decision 0024 for evidence and validation limits.
