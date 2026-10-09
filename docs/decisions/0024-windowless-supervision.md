# 0024 — Windowless scheduled supervision

Date: 2026-10-09. Status: accepted and applied locally.

## Context and decision

The user reported a recurring blank terminal. The installed five-minute watchdog launched pwsh.exe directly with WindowStyle Hidden; the supervisor process matched that task. Closing its console interrupts supervision and the watchdog launches it again. Direct console launch did not meet the intended invisible operation on this Windows terminal configuration.

Use the built-in GUI Windows Script Host (wscript.exe), explicit JScript engine, batch/no-banner options and a repository-owned wrapper. The wrapper launches the selected PowerShell runtime with hidden window style and waits for its full lifetime, propagating the exit code. Task Scheduler therefore still tracks a running supervisor; IgnoreNew, logon trigger, watchdog and existing restart settings remain effective. Runtime/script paths are quoted and reject quote/percent/newline characters to prevent command rewriting or environment expansion. No cmd.exe shell is involved.

Keep interactive limited-user identity, credentials, controller locks, persistent stop, demand scaling and job lifecycle unchanged. Windows Script Host/JScript must be enabled. The PowerShell resolver recognizes both legacy direct tasks and wrapped task arguments, without mistakenly executing wscript.exe as a PowerShell candidate.

## Alternatives and consequences

Disabling the watchdog hides the symptom but loses recovery; rejected. A different non-interactive task identity could change Docker/key/session access; rejected. A compiled GUI host adds build/deployment dependencies; deferred. JScript uses an existing tested Windows component and avoids adding VBScript as a dependency. Existing directly launched processes are not automatically killed; update the task for future launches and resume when the old instance is absent, or perform a graceful idle transition. Never stop Docker/WSL.

## Validation

The actual wrapper passed isolated child launch, spaced paths, synchronous lifetime and exit-code 17 propagation. Windows PowerShell 5.1 resolved the runtime from a wrapped task when other candidates were unavailable. Desktop launcher regression and read-only UI smoke passed. Live task now executes wscript.exe; the supervisor's parent is wscript.exe. Both locks held, stop false, fresh successful zero-demand snapshot and zero slots verified after installation/start. Docker and job resources were not forcibly stopped. Visual recurrence across a future logon is not separately tested.

Source: [Microsoft wscript command documentation](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wscript), checked 2026-10-09. Launch/lifetime behavior was validated locally, not inferred solely from documentation.
