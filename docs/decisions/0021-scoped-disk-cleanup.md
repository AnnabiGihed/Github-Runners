# 0021: Scoped obsolete disk cleanup while runners remain active

Date: 2026-10-08. Status: Implemented; cache selection tested and approved old-cache deletion verified. Future labeled-image collection not yet exercised against an aged image.

## Decision

The user is concerned about rising disk usage, rather than RAM, and authorized deletion of unused, unshared December 2024 build records. Inventory found 7.103 GB host images, 5.136 GB cache, a roughly 3.84 GB active runner layer and several GB job volumes. Normal single-job cleanup removed completed environments while the pool replenished. No orphan-volume growth was established by these changing snapshots.

Provide `Clean-RunnerDisk.ps1` with preview by default and explicit Apply. Select only reclaimable, immutable, unshared cache records matching the known superseded distribution-gh runner tool layer; additional pre-existing records require exact explicitly approved IDs. Resolve the current builder and use exact ID filters, never global builder/system/volume prune. BuildKit protects records in use. CLI initially reclaimed nothing because boolean filters did not match on this builder; read-only probes confirmed this and exact-ID filtering successfully removed the six approved 2024 records. The obsolete runner layer remained dependency-retained and reclaimed zero bytes; do not report it removed.

Label future runner image builds `runner.project=ephemeral-github-runners`. Apply also removes only this label's dangling, unused image versions older than 168 hours. Preserve current/tagged images, pinned bases, unrelated images and recent rollback versions. Invoke this scoped cleanup after successful image builds and expose Clean obsolete disk cache in desktop maintenance. It does not set persistent stop, restart supervision, stop Docker, remove active containers or globally compact WSL storage. Existing images are not retroactively relabeled; live jobs were not interrupted to rebuild solely for the label.

## Tradeoffs and limits

- Keeping all cache forever wastes disk; arbitrary age-only cleanup of the whole shared builder risks unrelated work. Exact approval and known superseded project provenance narrow the scope.
- A global cache-size policy or dedicated project builder would require a separate resource/retention design; neither is silently configured. Current shared builder GC advertises a 20 GiB reserve. Recent/shared or provenance-unknown cache is retained.
- Per-job Docker images/layers/workspaces are deleted with the job environment; shared reusable host images/cache remain. Active builds can temporarily use GBs that are not safe to delete.
- Virtual-disk allocation and Docker's logical object usage are different measurements. This change makes freed internal storage reusable; it does not promise the Windows VHDX file immediately shrinks. No backend shutdown or offline compaction is permitted by decision 0020.

## Evidence

Six approved records removed about 1.281 GB: host cache changed from 91 records/5.136 GB to 85 records/3.855 GB. Current image count remained 11/7.103 GB. During normal completion, container layers dropped from roughly 3.84 GB to under 1 MB and named/anonymous job volumes to roughly 2.396 GB. Docker 29.8.2 stayed available, task Running, persistent stop false, four slots. These are successive snapshots, not an atomic accounting of every byte or proof of four successful simultaneous jobs.

Sources: [Buildx prune filters](https://docs.docker.com/reference/cli/docker/buildx/prune/), [image prune label/age filters](https://docs.docker.com/reference/cli/docker/image/prune/). Cache selector tests preserve current/shared/in-use/mutable/unapproved records; desktop smoke exercises the new control wiring. Existing acceptance gaps remain.
