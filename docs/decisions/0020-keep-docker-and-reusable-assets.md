# 0020: Keep Docker running and retain reusable assets

Date: 2026-10-08. Status: Accepted and implemented. Supersedes the optional Docker shutdown/memory-release action in decision 0019.

## Decision and rationale

The user requires cleanup of disposable resources while retaining reusable assets and never shutting down Docker. Docker availability is shared across targets; stopping its backend would prevent other runners starting. Remove the shutdown button. Existing `ReleaseMemory` worker requests and `Release-RunnerMemory.ps1` callers become cleanup-only compatibility aliases so already-open older app windows cannot shut down the engine. The existing backend restart helper and cold-start test now fail immediately before any mutation, preserving their historical source/evidence without allowing shutdown under current policy.

Keep existing ownership-checked single-job cleanup: deregister idle/completed owned runners, preserve diagnostics, remove runner/job daemon containers including anonymous job-engine storage, work/socket/runtime volumes and per-job networks. Preserve busy jobs and unrelated containers. Retain shared host images, image layers and build cache, target configuration, keys and bounded diagnostic evidence. Job-local Docker layers/cache are part of disposable job state and are destroyed; they are not promoted into a shared trusted cache.

Removing processes releases their working memory. Docker/WSL cached RAM is managed by the platform; no exact immediate Windows memory reduction is promised. Do not globally drop caches, prune images, install privileged cache-clearing containers or shut down Docker/WSL to force memory recovery. No WSL setting changes are made here. This does not implement a new persistent job cache or alter the host resource budget.

## Alternatives and consequences

- Backend shutdown: rejected explicitly by the user; unavailable even through legacy maintenance/test entry points.
- Global cache dropping/pruning: rejected because it affects reusable assets and other workloads and conflates RAM with disk storage.
- Shared job-engine volumes: rejected because they retain workflow output/credentials and violate fresh-environment requirements.

Stop & clean remains the single desktop stop/cleanup action. Closing/reopening loads the updated UI; old-window ReleaseMemory calls are also safe. The already stopped personal pool stays stopped until explicit resume, with Docker available throughout. Additional targets still need live onboarding/acceptance.

## Validation

Updated stop fixture tests verify retained busy state, cleanup with unrelated containers present, zero Docker shutdown requests and teardown retries after a job finishes. Desktop smoke verifies the window without the shutdown control. Live read-only Docker/resource inventory confirms availability and retained shared image IDs before/after cleanup. Historical Docker cold-start success remains historical and is not rerun.
