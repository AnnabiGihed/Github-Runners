# 0016: Unattended personal operation and retained diagnostics

- Date: 2026-10-08
- Status: implemented and validated for personal operation; unperformed checks listed in validation
- Updates: bounded operation in decision 0013

## Operation and recovery

The user deferred the organization and authorized completing the personal deployment. Use an interactive-user Windows scheduled task at login, with a five-minute watchdog, single-instance execution, no time limit and no stored Windows password. Run the host supervisor under the same non-elevated identity that owns the App key and Docker Desktop. Launch Docker Desktop hidden when its engine is unavailable at initial startup; wait 30 seconds for readiness. A failed controller is retried after 60 seconds. Local exclusive supervisor/controller locks prevent overlapping provisioning. A persistent stop request prevents watchdog restarts.

Docker launch attempts are bounded to once per five minutes during an outage and reset after the engine is healthy, allowing later outages to recover too. The controller lock is released even if initialization fails before the reconciliation loop, so a transient startup error cannot permanently block retries.

Use a continuous controller rather than hourly drain/replacement of otherwise healthy jobs. After interruption, retain recorded busy jobs and wait for completion; destroy every idle/stopped prior environment before provisioning fresh workspaces. On API/Docker errors, preserve state, stop replenishment, attempt graceful drain and retry. Never use global pruning or restart used containers. Only probe runners with random labels and no defaults are eligible for intentional recovery failure injection.

For idle cleanup, request remote deregistration before local destruction. If assignment races the initial busy check and GitHub rejects deletion, retain the local environment. After successful deregistration, capture diagnostics and destroy container/workspace; deregistration alone never counts as cleanup. If later cleanup fails, persisted state remains for reconciliation and is never reused.

Alternatives: a SYSTEM service would use a different Docker/key identity; a password-backed task adds credential storage; startup before user login is unsuitable for this Docker Desktop arrangement; hourly sessions disrupt capacity. The chosen deployment runs while the user is signed in and the PC is awake. Sleep/logout/reboot interrupt availability, and a physical reboot test cannot be claimed from task registration. The task uses the current PowerShell executable path; re-register it after moving/upgrading that installation. PowerShell 7.4+ is required for .NET tar streaming.

## Diagnostics and limits

Live Docker stats showed the ongoing .NET build using its full 0.5-CPU quota and roughly 887 MiB of its 1-GiB limit, while its daemon was nearly idle. Balance future slots at one CPU/1536 MiB for the runner and one CPU/2048 MiB for its daemon, in config/runner-resources.json. Four slots allocate eight CPUs/14 GiB; reserve another 1536 MiB for Docker, and validate this aggregate against the live engine before provisioning. Alternatives are retaining throttled builds or increasing the approved engine budget; the balanced split uses existing resources. Tests reject CPU/memory oversubscription. Existing busy jobs are not hot-updated; new limits take effect on replacements. This is a measured bottleneck correction, not a general workload performance guarantee.

Checkpoint runner/worker diagnostics every minute and before owned-container deletion, including stopped containers. Stream only `_diag` through Docker's tar output into memory, never credentials or job workspace files. Cap archives at 64 MiB, each saved runner file at 2 MiB, and each source log at its last 256 KiB. Known token/JWT/PEM patterns and sensitive lines are redacted. No raw host staging is used. Keep files in ignored `.local/diagnostics/`, restricted to the current Windows user, with seven-day/200-MiB retention. Rotate supervisor status logs at 5 MiB with one previous file. Missing final diagnostics blocks deletion until collection can be retried; abrupt power loss can still lose the last checkpoint interval.

Redaction is defense in depth, not proof that arbitrary application secrets are detectable. Treat local diagnostic files as sensitive, do not commit or upload them. Capped tails intentionally sacrifice old verbose detail to bound local storage. Diagnostics use no job-writable host mount. Prefer protected local storage over third-party log upload to preserve outbound-only and credential boundaries.

## Verification and references

Saved tests check redaction, retention/ownership, stopped-container tar collection, runner failure and controller crash recovery. Record executed results in the personal operations validation report. Representative four-job and GitHub container/service execution require independent live evidence.

Sources checked 2026-10-08: [GitHub ephemeral runner logs and update requirements](https://docs.github.com/en/actions/reference/runners/self-hosted-runners), [runner diagnostics](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/monitor-and-troubleshoot), [Microsoft interactive task principals](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal).
