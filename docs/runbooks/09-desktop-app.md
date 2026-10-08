# Desktop runner manager

## Launch

Prerequisites: Windows, PowerShell 7.4+, Docker Desktop in Linux mode, the cloned repository, and the approved Docker resource budget. Run from the repository:

```powershell
./scripts/desktop/Open-RunnerDesktop.ps1
# Optional: create a double-click launcher inside this checkout:
./scripts/desktop/New-RunnerDesktopShortcut.ps1
```

The launcher and shortcut generator also work from Windows PowerShell 5.1: they locate and verify PowerShell 7.4+ before handing off. Discovery checks the current compatible runtime, `pwsh.exe` on PATH, standard installation paths, then the installed runner task's runtime. To select a custom installation, pass `-PowerShellPath 'C:\path\to\pwsh.exe'`. Missing/incompatible runtimes fail with guidance; no software is automatically downloaded.

The generated shortcut is `.local/desktop/Ephemeral Runner Manager.lnk`. You may pin/copy it where convenient. It refers to this checkout and the resolved PowerShell 7 executable; regenerate after moving the checkout or runtime. Direct launch: `pwsh -STA -File scripts/desktop/Start-RunnerDesktop.ps1`.

The app runs as your signed-in account without automatic elevation. It is a native window, not a web service. No installation outside this repository is performed. Closing it leaves the scheduled runner service running.

## New target

1. Create/install the App using [GitHub App setup](05-github-app-setup.md). Personal repository scope needs repository Administration write; organization scope needs organization Self-hosted runners write. Disable webhooks and install under the correct owner. Supply its App ID, installation ID and downloaded private-key PEM file; IDs alone are insufficient.
2. Open Setup & targets, select New, and enter a unique lowercase target ID, scope, GitHub owner, repository for personal scope, IDs, routing label and desired concurrent jobs. Browse to the PEM. For public personal repositories, review trusted workflow triggers before explicitly checking the trust acknowledgement.
3. Ensure total capacity fits the host limit. Current RaidManager occupies four of four slots: edit its count first to make room. Save updates configuration without changing an already running controller's allocation.
4. Select Validate & save to check all configured installations and save. Set up & start additionally checks Docker/resources, builds the image if absent, installs login supervision, and starts/gracefully restarts the pool. Initial setup starts without requiring prior controller state. Later-step failures retain the verified configuration for retry; check the result message.
5. Select Status → Refresh service, then Refresh live runners & jobs. The latter shows registrations, online/busy status, CLI version and isolation checks. It does not show GitHub job names or full logs. Starting/completing runners can be omitted from a changing snapshot; refresh again.
6. Copy workflow labels and apply the copied `runs-on` value to intended workflow jobs. Configure organization repository access in GitHub as applicable. Run trusted smoke jobs and verify a fresh runner/workspace for each job. Workflow edits and GitHub access authorization are manual; the app does not request broader permissions to change repository contents.

An existing target can change capacity, labels and App references, but its ID/scope/owner/repository are fixed. Use New for a distinct identity. Leaving the key field blank retains the protected key; choosing another imports a new protected file without overwriting the old one. The original selected PEM remains where you downloaded it—secure or delete that original deliberately after validating setup.

## Maintenance and removal

- Check Docker & resources performs read-only host preflight. Start/apply/setup also check aggregate resource allocations. Docker installation and WSL resource changes remain in the existing runbooks.
- Rebuild image uses the shared image build/smoke script; cached layers and digest pins still apply. Review/update dependencies using runbook 08, then rebuild and Graceful restart. Rebuilding alone does not change a running controller's image ID.
- Install login supervision installs/updates the limited interactive-user scheduled task. Start / resume clears a drained persistent stop and starts it. Stop & drain requests shutdown without killing busy jobs. Graceful restart waits for locks before resume.
- Remove requires Stop & drain, released runtime locks and zero recorded environments. Busy/draining state blocks removal. At least one configured target must remain. Keys are retained; separately revoke/delete obsolete keys after all jobs drain.
- Errors and results appear below the tabs. Operations are serialized and displayed at completion; long builds/drains can take several minutes. Do not terminate the app or child process during a transaction. No arbitrary commands or raw logs are accepted/displayed.

Stop & clean now waits for graceful shutdown and reconciles retained environments even after an interrupted supervisor. If busy jobs exceed the wait, cleanup remains pending and supervision retries without replenishment; refresh status and retry rather than force-delete containers. Docker remains running throughout cleanup. Shared host images/build caches and unrelated containers are retained. The former ReleaseMemory action is a cleanup-only compatibility alias; its button has been removed. Close and reopen the manager to load updated scripts/UI.

Docker/WSL may retain cache memory after containers are deleted. Removing disposable processes releases their working memory; cached RAM reclamation remains controlled by Windows/WSL. Cleanup never stops Docker/WSL, drops global caches or prunes shared images. See decision 0020, which supersedes the shutdown option in 0019.

Protected `.local/desktop/targets.previous.json` holds the previous configuration after a successful edit/removal. For rollback, stop/drain, restore that file as `.local/targets.json`, validate structure/access, then start/resume. Never commit local requests, keys, runtime state, logs or screenshots. There is no automatic configuration sync to GitHub.

## Checks

If workflows stay queued, refresh service status first. `StopRequested=True` means intentional shutdown: the task watchdog respects it and creates no runners, even with Docker running. Use Maintenance → Start / resume, then refresh live runners. Normal job completion already removes and replaces its disposable environment while supervision stays active; Stop & clean disables the entire pool until explicit resume. If runners are online and idle but jobs remain queued, check workflow routing labels and target access rather than repeatedly stopping the pool.

```powershell
./tests/Test-RunnerDesktop.ps1
./tests/Test-RunnerDesktopLauncher.ps1
./tests/Test-RunnerStop.ps1
pwsh -STA -File scripts/desktop/Start-RunnerDesktop.ps1 -SmokeTest
```

Transaction tests use a disposable repository copy and mock GitHub API access. The smoke test opens the actual WPF window, clicks the service-status button, waits for its read-only worker and closes. Neither onboards an organization nor changes production targets. See [evidence and remaining acceptance](../validation/2026-10-08-desktop-app.md).
