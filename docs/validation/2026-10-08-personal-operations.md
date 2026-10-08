# Personal operations validation: 2026-10-08

Scope: AnnabiGihed/RaidManager only. Organization rollout is explicitly deferred. Evidence is sanitized metadata and executed checks; secrets and raw logs remain ignored.

## Continuous operation

### Queued-workflow recovery after intentional stop

After cleanup, inspection found `StopRequested=True`, zero slots, task Ready and both locks free while Docker 29.8.2 remained available. The user reported queued workflows; executed `Start-RunnerService.ps1 -Resume`. Subsequent service inspection showed Running, both locks held, persistent stop cleared and four production slots. Live pool snapshots verified busy unprivileged ephemeral registrations with matching resources and no host published ports; starting/completing slots were omitted with warnings.

For commit a610669467e2027df8c5dafc996d7f489ecdd524 on feature/551-companion-sync-screens, [CI 37752334390](https://github.com/AnnabiGihed/RaidManager/actions/runs/37752334390) changed to in progress: companion on runner ending 01f40d85f55b, build-test on f1f24647198c; Sonar completed successfully on ecb46f5cd72a. [Addon 37752334602](https://github.com/AnnabiGihed/RaidManager/actions/runs/37752334602) changed to in progress, Lua on 558f13191f06. This proves assignment resumed, not that every queued workflow finished successfully. Added explicit desktop stopped-pool status guidance and runbook troubleshooting. No Docker shutdown, workflow mutation or credential/permission change was needed.

- Installed EphemeralGitHubRunners in Windows Task Scheduler under the owning account, Interactive logon and Limited run level. No account password is stored. Logon trigger, five-minute watchdog, IgnoreNew, unlimited task runtime and restart settings are configured by the saved installer.
- Started it through Start-RunnerService.ps1. Verified Running task, held supervisor/controller locks, no stop request, four recorded production slots and zero validation slots. State age was two seconds at inspection.
- All four production runners were online. Effective checks passed: ephemeral configuration, unprivileged runner, all capabilities dropped, no-new-privileges, no restart policy, volume-only mounts, isolated job daemon with Unix-only API command, no published outer ports and resource limits matching configuration.
- Future slots use one CPU/1536 MiB per runner and one CPU/2048 MiB per daemon. Four slots plus 1536 MiB engine reserve fit the verified eight CPUs/15.62 GiB. Prior .NET build had consumed its full half-core quota and about 887 MiB; its existing limits were preserved until it finished.

## Executed tests

| Check | Evidence/result |
| --- | --- |
| Configuration and App client | Existing tests passed, including oversubscription/path rejection, JWT verification and installation mismatch rejection |
| Resource budget | Four slots accepted; insufficient CPU and memory-plus-reserve rejected |
| Diagnostics | Token/JWT/PEM/sensitive-line redaction, ordinary text preservation, age retention and unrelated-file preservation passed |
| Stopped-container diagnostics | Docker tar streamed in memory; saved fixture logs retained useful text and removed its synthetic secret |
| Job-local Docker | Unprivileged client, local Unix socket, nested container/build, no outer host mounts/ports or daemon TCP API passed; owned resources removed |
| Runner process failure | Killed only a randomly labeled idle probe; runner, daemon, socket/work/runtime volumes and network removed; distinct runner had no prior marker |
| Controller crash | Abruptly killed only the test-owned host controller; restarted from persisted state; old probe environments removed and fresh ones created |
| API outage | Validation-only failure injection stopped API reconciliation; identities/workspaces preserved, then reconciled after removing the injection flag |
| Four-slot workloads | Four simultaneous local processes in four online probe environments completed C compilation, Docker builds, PostgreSQL SQL and localhost service checks, and bundled Node execution in nested containers |
| Four-slot cleanup | Test completed with zero recorded environments; production resumed under the supervisor |
| Docker cold start | After all jobs drained and no other running containers remained, stopped Desktop; scheduled supervisor launched it and restored four online production runners with effective resource/isolation checks |
| PowerShell syntax | All authored PowerShell scripts/modules parsed without errors |
| Final idle cleanup guard | Additional bounded four-probe cycle deregistered idle listeners before destroying their environments; zero slots remained, then scheduled production resumed |

Recovery probes use random labels without defaults, so no normal workflow selected them. Existing busy production work was preserved through drain timeout and test-controller recovery. No unrelated resources were pruned. Cold-start testing did not shut down unrelated WSL distributions or reboot Windows.

During test development, corrected a snapshot race that initially selected a stale probe, a PowerShell empty-property count in the isolation inspector, and a Set-Acl privilege issue by using the filesystem ACL API and checking effective permissions. Relevant tests then passed; initial failures are not treated as acceptance evidence.

## Actual GitHub workflow outcomes

These are executed self-hosted jobs, separate from the synthetic four-slot test:

| Workflow | Run | Result |
| --- | --- | --- |
| CI: build-test, companion, Sonar | [37707200750](https://github.com/AnnabiGihed/RaidManager/actions/runs/37707200750) | All successful, each on a distinct personal runner |
| Addon/Lua | [37707200804](https://github.com/AnnabiGihed/RaidManager/actions/runs/37707200804) | Successful |
| Docs | [37707200877](https://github.com/AnnabiGihed/RaidManager/actions/runs/37707200877) | Successful |
| Project hierarchy | [37706964806](https://github.com/AnnabiGihed/RaidManager/actions/runs/37706964806) | Successful |
| Review | [37707201106](https://github.com/AnnabiGihed/RaidManager/actions/runs/37707201106) | Successful |
| Later review retries | [37709188412](https://github.com/AnnabiGihed/RaidManager/actions/runs/37709188412), [37709302810](https://github.com/AnnabiGihed/RaidManager/actions/runs/37709302810) | Successful after an earlier operator-signoff step failure in run 37709174539 |

CI/addon/docs initial successes reference commit 6253197dbc40dfd152522b410d8f83a58b8b22a2. Project hierarchy main used 5e81bef2fb43e9d006c340a8c1d801b2ade5e163. Earlier failures are retained in the change log; no gate was bypassed in this runner repository.

An initial sample of 20 runs/12 assigned jobs showed three overlapping real job intervals and ten successful jobs. This is not evidence of four simultaneous successful GitHub-dispatched jobs. The separate four-slot local test demonstrates capacity/component execution, not unrestricted future performance.

Public API inspection initially hit the unauthenticated limit. Opt-in status inspection with the existing narrowed App token succeeded without added permissions; the transient token was revoked. No PAT was used.

## Diagnostics and remaining boundaries

Verified current-user-only diagnostic directory permissions. One resumed production inspection showed 41 files/about 3.4 MiB of protected diagnostic/status data. Retention remains seven days/200 MiB, runner-file cap 2 MiB, source-log tails 256 KiB, memory archive bound 64 MiB. Do not publish these files; pattern redaction cannot detect every arbitrary application secret.

Physical Windows reboot/logon, a real network unplug during a job, and an assigned GitHub job cancellation were not deliberately performed. The configured logon trigger, actual task execution, stopped-Desktop recovery, runner/controller failure tests and injected API outage are the available evidence. GitHub's full container-action orchestration was not exercised by the local Node/container fixture; the saved smoke workflow remains available for that acceptance check. No hostile-code or LAN egress isolation guarantee is made for the accepted privileged Docker design.

Keep the owning user signed in and the PC awake. Maintain pinned runner images within GitHub's update deadlines. Organization installation/access remains deferred; do not assume these personal runners can serve it.
