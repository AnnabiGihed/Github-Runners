# Demand scaling trial and reusable setup

Use PowerShell 7.4 or later from this repository. Keep Docker running. The controller stays online even at zero runner containers. Maximum job capacity remains four; minimum idle capacity becomes zero.

1. In the target GitHub App settings, enable repository **Actions: Read-only**. Approve installation permission changes. Retain the runner-management permission; do not add Actions write, a PAT, webhooks or inbound listeners.
2. Ensure jobs request a configured custom label, for example `runs-on: [self-hosted, linux, pc-personal]`. Every requested label must exist on the runner. Generic self-hosted-only jobs do not trigger this autoscaler.
3. Verify queue access and save the mode:

```powershell
./scripts/github/Test-RunnerDemand.ps1 -TargetId personal-raidmanager
./scripts/config/Set-RunnerScaling.ps1 -TargetId personal-raidmanager -Mode demand -PollSeconds 60
```

4. Inspect the pool for busy jobs before maintenance. Apply through `Restart-RunnerService.ps1` or the desktop Apply action. The tested handoff resumes once the controller releases its lock after bounded drain, even with busy jobs retained and the supervisor alive. If the controller never releases its lock within the wait, allow recovery and explicitly Start / resume. Never force-stop busy containers. Changing configuration alone does not change the running controller.
5. With no queued jobs, verify zero slots, active supervisor/controller locks, no stop request and Docker still responding. Trigger a normal repository workflow. Observe queue snapshot, fresh provisioning, GitHub assignment and final removal. Allow the polling interval, provisioning time and two-minute startup grace. Cold pickup is slower than a warm pool.

```powershell
./scripts/host/Test-RunnerService.ps1
./scripts/controller/Test-RunnerPool.ps1
docker system df
```

Zero slots with active supervision and a successful demand snapshot is a healthy idle demand pool; zero slots with stop requested or inactive supervision cannot pick up jobs. On an API failure, the controller does not infer zero demand. Review sanitized supervisor diagnostics under ignored `.local/diagnostics` for polling failures. Shared images/cache remain reusable; fresh job volumes are removed with completed environments.

## Rollback

```powershell
./scripts/config/Set-RunnerScaling.ps1 -TargetId personal-raidmanager -Mode warm
./scripts/host/Restart-RunnerService.ps1
```

This restores fixed ready capacity. Apply only through graceful drain; Docker remains online. The setter validates before atomic replacement and retains a protected prior configuration snapshot. Other repository targets use their own ID and App installation. Organization mode is implemented against installation-accessible repositories but remains live-unverified; approve Actions read on its installation, validate actual runner repository access and redistribute the four-slot host budget before enabling it.

## Evidence

2026-10-08: user approved Actions read; live App permission and queue inspection passed (zero matching jobs). Offline demand policy and actual-controller integration tests passed; production activation and real job acceptance are recorded below when executed. This is a trial, not a 100% availability claim. Review 0022's unrelated teardown/output risks remain open.

Test-RunnerService.ps1 exposes sanitized DemandSnapshots: validity, last successful poll, matching queued count and next poll time. Healthy supervision alone does not prove queue API access.

### Live trial results — 2026-10-08

- Actions read permission verified before change; initial queue was empty. New user-triggered workloads arrived before activation; first transition attempt detected busy jobs and made no change.
- Applied demand mode using Set-RunnerScaling and graceful restart. Existing jobs completed without forced cancellation; old owned environments were removed. At 10:21:55 UTC the old pool reached zero; supervision restarted, stop was cleared, and a 10:22:02 queue snapshot found four matching jobs. Fresh demand-created runners picked them up.
- [Addon run 37762200774](https://github.com/AnnabiGihed/RaidManager/actions/runs/37762200774) succeeded on pc-personal-raidmanager-043127075241. Test-RunnerEnvironmentRemoved verified both containers, all three volumes and network absent, with Docker responding.
- [Docs run 37762226690](https://github.com/AnnabiGihed/RaidManager/actions/runs/37762226690) succeeded on pc-personal-raidmanager-9330901f9a3e. These runs validate cold pickup and distinct single-job environments.
- At 10:26 UTC demand was valid with zero queued jobs; only the active [CI run 37762200747](https://github.com/AnnabiGihed/RaidManager/actions/runs/37762200747), build-test, remained on pc-personal-raidmanager-fb61587f0c7f. That busy runner was correctly preserved and all inspected isolation/resource checks passed. Final idle-zero after this remaining CI job is pending at this checkpoint, not claimed complete.
- Ten relevant fixture suites passed across this change; PowerShell sources parsed. Desktop status smoke passed with scheduler access, and the updated UI rendered successfully. The sandbox-only status smoke initially lacked CIM access; the authorized local check passed without changing jobs.
- Reopen the desktop manager to load the new demand checkbox. Select a target, check “Create runners only when matching jobs are queued,” Validate & save, then Apply. Uncheck to return to warm mode. Advanced polling intervals remain configurable through the saved CLI command.

Demand polling/API loss, cap/label/pagination behavior and busy handoff have fixture coverage; live organization, physical reboot/network loss and never-releasing controller timeout remain unverified. This trial does not close every finding from review 0022.
