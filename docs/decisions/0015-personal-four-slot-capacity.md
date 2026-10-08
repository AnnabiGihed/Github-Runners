# 0015: Four personal jobs within the existing host cap

- Date: 2026-10-08
- Status: accepted interpretation of the user's request; representative load validation pending
- Updates: decision 0008 for the currently active personal target

The user requested four concurrent jobs. The organization is not configured, so allocate four slots to the personal target while retaining hostMaxRunners=4. This does not authorize eight total jobs. When activating the organization, redistribute the four slots or agree a revised host budget. The two-plus-two example remains the onboarding example for both scopes.

Each slot currently limits its runner to 0.5 CPU/1 GiB and its daemon to 1.5 CPU/2 GiB, including nested Docker workloads. Four slots therefore budget eight logical CPUs and 12 GiB of container memory against Docker's approved eight CPUs/16 GiB. This is an upper bound, not proof of acceptable throughput for simultaneous heavy builds. Alternatives are retaining two personal slots or raising the host-wide cap; the former does not implement the request and the latter is not assumed.

Save capacity changes through scripts/config/Set-RunnerCapacity.ps1, which validates the candidate before replacing ignored local configuration. Controller sessions read configuration at startup; apply after graceful drain and cleanup, preserving active jobs. Runner image rollout can occur in the same restart. Single-job destruction and outbound-only registration remain required.

Command from the repository root:

```powershell
./scripts/config/Set-RunnerCapacity.ps1 -TargetId personal-raidmanager -MaxRunners 4
./scripts/controller/Start-RunnerController.ps1 -ResetStopRequest -RunSeconds 3600 -DrainSeconds 300
```

Run the second command only after the prior controller has released its lock and busy jobs have completed. Online pool inspection is recorded separately from successful four-job concurrency.
