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
