# Desktop app validation — 2026-10-08

## Executed

- `tests/Test-RunnerDesktop.ps1` passed in a disposable `.local/tests/desktop-*` checkout copy: API rejection rollback, removal of failed imported keys, current-user-only key ACLs, over-capacity rejection, fixed-identity enforcement, existing-key retention, public trust acknowledgement, organization addition preserving personal target, persistent-stop requirement, retained-environment removal rejection, drained removal and final-target preservation. API responses were fixture substitutes, not live organization evidence. Disposable fixture files/keys were removed afterward.
- `pwsh -STA -File scripts/desktop/Start-RunnerDesktop.ps1 -SmokeTest -ScreenshotPath .local/desktop-smoke.png` loaded and rendered the real WPF window, exercised the actual service-status button/async child worker, and closed successfully. The screenshot was visually inspected and remains ignored. Corrected a module import-scope error during development; only the subsequent passing run is acceptance evidence.
- `Invoke-DesktopAction.ps1 -Action Pool` read actual registrations through the existing narrowed App client, showing busy production runners with CLI 2.102.0 and passing effective ephemeral/isolation/resource checks. Starting/completing slots were omitted with warnings. No active job was stopped or changed.
- Created the repository-local Windows shortcut with `New-RunnerDesktopShortcut.ps1`.
- Executed the actual setup worker in a disposable fixture with substituted API/Docker/service effects; confirmed first setup takes start/resume rather than restart when no controller state exists. Final desktop PowerShell parsing and Git whitespace checks passed; local keys, launcher and screenshots remained ignored.

## Remaining acceptance

Launcher regression: reproduced the user's 5.1 `#requires` failure, then verified automatic 5.1-to-7 desktop launch with the actual read-only smoke test. Added dedicated explicit/missing-runtime and 5.1 launcher/shortcut tests. The app runtime remains PowerShell 7.4+.

Full fresh live GUI setup, live target edits/removal and live organization onboarding were not performed against production. Backend transactions were fixture-tested; existing underlying setup/build/service scripts have their separately recorded live evidence. The desktop app adds no claim of completing physical reboot, real network interruption, GitHub job cancellation, full container-action acceptance or four simultaneous GitHub-dispatched jobs. Organization rollout remains deferred.

GitHub App creation/authorization, workflow label changes, Docker installation and resource reconfiguration remain manual guided prerequisites. The manager is source-launched via PowerShell/shortcut, without an executable installer or code signing.
