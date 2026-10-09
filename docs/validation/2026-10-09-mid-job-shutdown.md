# Mid-job runner shutdown investigation — 2026-10-09

Times in UTC (local Europe/Brussels = UTC+2). These are sanitized observations; raw diagnostics stay in ignored `.local/diagnostics/` and are not committed.

## Incident

RaidManager workflow run 37905220473, job `build-test` (PR 611). Both attempts failed with the runner's shutdown-signal error during `dotnet format ... --verify-no-changes`:

| Attempt | Runner | Job start | Stopped |
| --- | --- | --- | --- |
| 1 | `pc-personal-raidmanager-c3a3ea5f6cf8` | 08:31:05 | 08:33:52 |
| 2 | `pc-personal-raidmanager-f215be1d1646` | 08:37:29 | 08:40:35 |

The same step passed earlier that day (07:12–07:20) on another runner, so the workload is not the cause.

## Observations

- Docker Desktop host log: `POST /containers/<id>/kill?signal=TERM` from a Docker CLI user agent at 08:33:52.10 and 08:40:35.43, for the two runner containers. This was a deliberate TERM forwarded by a local CLI, not an OOM kill.
- Runner diagnostics for attempt 1: `Exiting...` at 08:33:52, then the job process ended with exit code 102.
- Supervisor log: last entries 08:33:43 and 08:40:13, then `Supervisor started` at 08:36:52 and 08:41:47. These were fresh starts at the five-minute watchdog cadence, not the controller-error retry path.
- Application and System event logs, 08:28–08:46: no crash or application-error entries for pwsh, wscript or Docker; nothing related to the runner. The Task Scheduler operational log is disabled on this host, so it has no history.
- At 08:37:29 the owner told a concurrent Codex session that a terminal kept reappearing every time they closed it. That session's tool calls between 08:37 and 08:40:50 were reads, web lookups and a source patch. At 08:41:01 it observed both locks free (supervisor already gone), then installed the windowless task (decision 0024). The current supervisor (wscript → pwsh) started at 08:41:47.
- Controller source: the bootstrap is delivered with `docker start -ai`, a child process on the supervisor's console. `docker start --help` says `-a` attaches and forwards signals, with no opt-out.

## Conclusion

The visible supervisor console was closed twice. Each close delivered a console control event to the attached Docker CLI, which forwarded TERM to the busy runner. The watchdog then started a new supervisor, which reopened the window. The supervisor's console lifetime was coupled to jobs. The fix is [decision 0025](../decisions/0025-console-isolated-runner-attachment.md).

## Validation

| Check | Result |
| --- | --- |
| `tests/Test-RunnerConsoleIsolation.ps1` (live Docker, local image, `--network none`, labeled fixtures) | Passed: legacy control was signalled and stopped; isolated attach survived both the console event and a hard kill of the supervisor and CLI |
| `tests/Test-RunnerDemandController.ps1`, `Test-RunnerStop.ps1`, `Test-RunnerRestart.ps1`, `Test-RunnerDiagnostics.ps1`, `Test-RunnerHiddenLauncher.ps1`, `Test-RunnerDemand.ps1` | Passed |
| `tests/Test-RunnerRecovery.ps1` | Not run: live GitHub probe that needs the production controller lock |
| Real GitHub job across a live supervisor restart | Not yet observed |
