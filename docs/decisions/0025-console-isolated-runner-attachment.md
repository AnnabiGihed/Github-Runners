# 0025: Console-isolated runner attachment

- Date: 2026-10-09
- Status: accepted
- Related requirements: one job per runner; busy jobs are never forcibly removed; bounded supervisor recovery (decisions 0013, 0016, 0019, 0024)

## Context

On 2026-10-09 two attempts of a RaidManager `build-test` job were stopped mid-step with the runner's "received a shutdown signal" error at 08:33:52Z and 08:40:35Z. Docker Desktop recorded a `kill?signal=TERM` from the local Docker CLI for the runner container at both instants. The supervisor log ended moments before each, and a fresh supervisor appeared at the next five-minute watchdog tick. No crash or out-of-memory events were recorded. Evidence and how the cause was confirmed: [validation 2026-10-09](../validation/2026-10-09-mid-job-shutdown.md).

Root cause: the pre-0024 task launched the supervisor as a directly visible console. The controller delivers the bootstrap with an attached `docker start -ai` child that inherited that console. `docker start -a` always forwards the signals it receives to the container; it has no `--sig-proxy=false` option. On Windows, a console window close (or Ctrl+C/Break) reaches every process on that console, and the Docker CLI turns it into a forwarded signal. Closing the "blank terminal" therefore ended the supervisor and also signalled each attached busy runner, which exited and failed its job. Decision 0024 hid the window, but the job's lifetime was still coupled to the supervisor's console.

## Decision

Start the bootstrap attachment through `Start-RunnerAttachment` (`scripts/controller/RunnerAttachment.psm1`) with `CreateNoWindow`. This gives the Docker CLI its own windowless console that no user can close, and supervisor console events no longer reach it. Bootstrap still goes over stdin, so it never appears in container metadata, arguments, environment or a file.

If the supervisor or CLI is terminated outright (crash, task end, `Stop-Process`), nothing can forward a signal. The container keeps running with no restart policy. The next supervisor reconciles it through the existing logic: busy runners are retained; idle, exited or unregistered ones are cleaned with ownership checks.

## Alternatives and rationale

- `--sig-proxy=false`: not supported by `docker start`, only by `docker run`/`attach`. Moving bootstrap to `docker run -i --sig-proxy=false` would recombine create/start ordering and resource checks; rejected as a wider change for the same effect.
- Fully detached start with bootstrap via `docker cp` or an environment variable: either writes the registration token into the container layer or metadata; rejected.
- Killing the attach CLI after bootstrap: needs a reliable "stdin consumed" signal and loses stderr capture for diagnostics; rejected.
- A Windows job object or `DETACHED_PROCESS`: not available through `ProcessStartInfo` without native interop. A hidden private console already isolates the CLI from window close and Ctrl events.

## Consequences and limitations

- A supervisor restart, crash or window close no longer stops busy jobs. An orphaned attach CLI exits on its own when its container ends or is removed.
- Windows logoff/shutdown still delivers session-wide events to every console process. Docker Desktop also stops with the user session, so jobs cannot survive logoff in this interactive-account design.
- Runners already attached by the previous controller code keep the old behaviour until they finish. Activation is the graceful `Restart-RunnerService.ps1` handoff.
- Explicit Docker stops of runner containers (out of policy) still end jobs.

## Sources and validation

- `docker start --help` (local Docker CLI, checked 2026-10-09): `-a, --attach  Attach STDOUT/STDERR and forward signals`; no signal-proxy opt-out.
- `tests/Test-RunnerConsoleIsolation.ps1` passed on 2026-10-09 against the local runner image. The legacy inherited-console attach, used as a negative control, forwarded the console control event and the container exited. The isolated attach kept the container running through the same event and a hard kill of the stand-in supervisor and CLI. Window close (CTRL_CLOSE) is modelled by CTRL_BREAK, which `GenerateConsoleCtrlEvent` can produce and which is delivered to the same console members.
- Related fixture suites (demand controller, stop, restart, diagnostics, hidden launcher, demand) passed.
- Pending: a real GitHub job surviving a live supervisor restart. The live recovery probe needs exclusive use of the controller lock.
