# 0013: Bounded host warm-pool controller

- Date: 2026-10-08
- Status: implemented; two personal registrations verified; workload/recovery validation pending

## Choice and rationale

Use a trusted host PowerShell controller and two ephemeral slots per configured target. A small warm pool avoids webhook listeners, extra job-polling permissions, Kubernetes, and scale-set-client dependencies. Reconcile every 10 seconds; default lifetime one hour, idle replacement 60 minutes, shutdown drain five minutes, three-start-failure stop. Configuration enforces a four-job aggregate cap. Limits are explicit initial operational defaults, adjustable through saved parameters.

Installation tokens are cached until five minutes before expiry and revoked on normal shutdown. Unique slot names and owner labels plus an exclusive state lock prevent unintended resource sharing. State contains only resource IDs, target IDs, timestamps, and registration status; no tokens. Record resources before mutations, clean only matching labels, preserve busy/failing state, and never reuse job workspaces. Pin the built runner image by local content ID for each controller session and the daemon by registry digest.

Runner bootstrap JSON travels through redirected stdin to docker start -ai, not environment metadata. Outer runner remains unprivileged with all capabilities dropped; only the disposable daemon is privileged. Runner and daemon share only their workspace/socket volumes and the daemon's network namespace to support localhost service semantics. Per slot limits total two CPUs/three GiB, leaving engine memory headroom. These caps may need revision for real toolchains.

## User routing clarification

RaidManager is currently public. The user clarified that this is temporary during configuration and all eventual workloads should use the hosted runners. Record that routing intent; public workflow trust acknowledgment and trigger review remain separate from label matching. Registration probes use a unique label and no defaults, so no normal workflow is routed by the tests. The organization is not configured yet.

## Evidence and limitations

Two validation runners were online, configured ephemeral, unprivileged, volume-only, with no published host ports. Listing API did not expose ephemeral status, so the verification reads only the boolean from local .runner metadata (handling its UTF-8 BOM). Initial tests found a PowerShell helper/native command-name collision and single-label JSON serialization; both were fixed before successful registration. No real job has executed; default-loop failure/backoff behavior, durable diagnostics, service/container actions, concurrency, and crash recovery require more validation.

Sources: [GitHub runner REST API](https://docs.github.com/en/rest/actions/self-hosted-runners) and [runner reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners), checked 2026-10-08. Registration/delete require runner-management permissions already granted; no PAT or broader workflow-editing permissions were added.

Additional implementation choice: a per-slot read-only bundled-runtime volume is seeded from the pinned runner image and exposed at /home/runner/externals in runner and daemon, permitting consistent bind paths for container jobs. A further bounded registration/cleanup run completed with those mounts; the pool inspector raced its shutdown and was corrected to tolerate removed resources. GitHub CLI OAuth authentication is unavailable, so the smoke workflow has not been published to RaidManager. No PAT fallback was used.
