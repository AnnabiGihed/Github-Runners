# 0019: Complete stopped-runner cleanup and optional memory release

Date: 2026-10-08. Status: Implemented; live stranded-environment cleanup verified, shutdown guards fixture-tested. Actual memory-release shutdown not performed in this change.

## Context and decision

The user observed stopped/finished runner containers remaining and asked about releasing memory after stop. Inspection showed four exited runner containers (exit 143), four running job-local daemons, four recorded slots, no held runtime locks, no persistent stop, and the scheduled task Ready with last result 3221225786. Supervisor output ended during normal provisioning, without a completed stop. Exact source of the interruption was not established. These observations do not imply that every exited container completed its GitHub job successfully.

Add `Stop-RunnerService.ps1`: persist stop, wait for active runtime locks to clear, then invoke the existing controller in explicit `-CleanupOnly` mode if recorded environments remain. The mode cannot reset stop or replenish, requires no runner image/provisioning capacity, and reuses ownership checks, live busy checks, idle deregistration, diagnostic preservation and complete environment destruction. Busy jobs/API/engine failures preserve state and block reported success. No global Docker prune or new cleanup/authentication implementation is introduced.

Update supervision to keep retrying cleanup while stop is requested and recorded slots remain, even when a job outlasts the controller's first drain timeout. It never replenishes in this state, and exits only after state reaches zero. An unavailable Docker engine during requested stop retains state and waits without automatically relaunching Desktop; restore Docker deliberately to finish teardown. Stop waits remain bounded and can report pending cleanup while the supervisor continues retries.

Add a separate `Release-RunnerMemory.ps1` and desktop Stop & release memory action. It first stops/cleans runners, holds both runtime locks, verifies persistent stop/zero state, and refuses when any other running Docker container exists or engine inspection fails. Then it runs `docker desktop stop`. The UI requests explicit confirmation because this shuts down Docker Desktop for the PC. Docker images/build caches remain on disk; other WSL distributions are untouched. No global WSL shutdown, cache-dropping privileged container or image deletion is used.

Start/resume can request supervision while Docker is stopped; the existing supervisor starts Desktop and the controller validates measured capacity before provisioning. This avoids making Docker preflight a prerequisite for restoring a deliberately stopped backend.

## Alternatives and consequences

- Delete containers manually or global prune: rejected because it can lose job state, leave registrations/volumes, or affect unrelated workloads.
- Kill running jobs at stop: rejected. Busy state must drain; completion cleanup continues afterward.
- Automatically stop Docker whenever runners stop: rejected because other Docker users need the engine. Explicit memory release is separate.
- Global `wsl --shutdown`: rejected because unrelated distributions may be active.
- WSL `autoMemoryReclaim`: supported option for idle cache reclamation, but no global host setting is changed here. The existing eight-CPU/16-GB budget remains unchanged. Docker shutdown is not a promise of exact immediate Windows RAM recovery, especially with other WSL workloads.

The task watchdog may start a cleanup-only supervisor for retained state, but persistent stop prevents new runners. Protected diagnostic tails remain available after cleanup. Previously listed organization/reboot/network/cancellation/full container-action acceptance gaps remain open.

## Evidence and sources

See [cleanup validation](../validation/2026-10-08-stopped-cleanup.md). Official memory behavior: [Docker WSL backend](https://docs.docker.com/desktop/features/wsl/), [Resource Saver limitations on WSL](https://docs.docker.com/desktop/use-desktop/resource-saver/), [WSL memory reclamation settings](https://learn.microsoft.com/en-us/windows/wsl/wsl-config).
