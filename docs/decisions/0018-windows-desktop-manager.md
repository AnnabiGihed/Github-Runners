# 0018: Windows desktop runner manager

Date: 2026-10-08. Status: Implemented; isolated transaction tests and read-only desktop/live status checks passed. Fresh live onboarding through the GUI is unverified.

## Context and decision

The user requested a small desktop app to automate setup after supplying GitHub App information. Use a native WPF window hosted by PowerShell 7.4+ in STA mode. Keep XAML in `infra/desktop/`, application scripts in `scripts/desktop/`, and protected local launcher/state under `.local/desktop/`. This uses the existing runtime without adding an SDK, browser server, listening port or framework package. The app is source-launched with a Windows shortcut; it is not a packaged/signed executable installer.

Setup/targets, status and maintenance screens invoke the existing scripts through a fixed action allowlist. Child processes use `ProcessStartInfo.ArgumentList`, JSON stdin, redirected pipes and no visible console. Only one operation runs per window; the dispatcher remains responsive while polling completion. Outputs are redacted in the worker and UI, retained only in memory. Closing during an operation is blocked to avoid orphaning an in-progress transaction; closing normally leaves scheduled supervision running.

Saving validates structure, scope-aware live App access and explicit public-repository trust before atomically replacing configuration. GUI writers share a file lock; comparison detects external edits during validation. Imported RSA keys get unique filenames under a protected secret directory and current-user-only file ACLs. Failed validation removes the newly copied key and draft while retaining prior configuration/key. A protected previous-configuration snapshot supports manual rollback; old keys are deliberately retained because existing controllers may still need them.

Editing retains target identity and permits capacity, labels, App references and key changes. Removing targets requires a persistent stop, released supervisor/controller locks and zero recorded environments; removal holds both runtime locks during the configuration write. Final-target deletion is refused; stopping the service disables all runners without discarding recovery configuration. These restrictions prevent lost cleanup credentials/state. The host cap remains configured outside the GUI; adding targets requires redistributing its capacity. Start/apply/setup verify measured Docker capacity against existing resource tooling.

Set up & start checks Docker, saves verified configuration, builds the image if missing, installs user-login supervision and starts or gracefully restarts it. Failed later steps leave the verified configuration available for retry and report failure; the operation is not an all-or-nothing deployment transaction. The app does not install Docker or alter WSL allocations. Status exposes service health and per-runner busy state; job names/log streaming would require further work and possibly Actions permissions.

## Alternatives, consequences and boundaries

- Browser/Electron UI: rejected for this small Windows-only tool because it adds dependencies and possibly a local listener.
- Compiled WPF/WinUI executable: viable for later distribution/signing, but adds packaging/build maintenance. Current scope prioritizes reuse of tested PowerShell tooling.
- Reimplementing the controller or GitHub authentication in the UI: rejected to avoid two lifecycle/security implementations.
- Automatic workflow mutation/App creation: deferred. GitHub authorization remains interactive, IDs alone do not authenticate, and the existing App has no requested Contents write permission. Copy workflow labels is provided instead.

No PAT, inbound port, App key job mount, automatic key deletion or workflow gate bypass is introduced. UI redaction has the same arbitrary-secret limitations as existing diagnostics. Repository/organization plan eligibility and onboarding acceptance still need target-specific live evidence; this app does not turn fixture tests into such evidence.

## Validation and sources

See [desktop validation](../validation/2026-10-08-desktop-app.md), [desktop runbook](../runbooks/09-desktop-app.md), [Microsoft WPF overview](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/overview/) and [WPF threading model](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/advanced/threading-model). Existing GitHub authentication endpoints/permissions are unchanged; their existing reviewed sources apply.
