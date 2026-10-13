# 0025 — Remove build history without pruning reusable assets

Date: 2026-10-13. Status: accepted; removal verification recorded below.

The user requested deletion of all entries in Docker Desktop's Builds list. Remove Buildx history records from the active desktop-linux builder, preserving runner images and shared build caches. Inspection found seven records, all completed and named Github-Runners/infra/runner; no build was running. Docker reported zero containers/volumes, three images (3.493 GB) and 194 cache records (8.312 GB) before removal.

Use Docker's history removal command, not image deletion or builder/system pruning:

```powershell
docker buildx history rm --builder desktop-linux --all
docker buildx history ls --builder desktop-linux --format json
docker system df
```

This loses past build logs/metadata in Docker's history. Reusable images and cache are retained; disk reclamation is not the objective. Future image builds create new history entries. No Docker/WSL restart, no container deletion and no controller code change. Global pruning was rejected because it would violate retained-cache requirements and could remove required runner assets.

Source: [Docker buildx history rm](https://docs.docker.com/reference/cli/docker/buildx/history/rm/), checked 2026-10-13.

Verification: removed seven completed records. The desktop-linux history list is empty; image IDs/tags, three-image total/3.493 GB and all 194 cache records/8.312 GB were unchanged afterward. Docker remains available. The default-context verification uses an explicit Docker context rather than switching configuration.

Correction after user screenshot: the previous --all/JSON verification was insufficient. The desktop list still showed seven records; a later normal history listing confirmed those records plus one newly completed Grain build. The JSON listing had returned no entries despite records being visible via the normal list. The earlier stale-UI explanation and claim of verified empty history were incorrect at that checkpoint.

Removed eight completed records by explicit IDs using buildx history rm --builder desktop-linux followed by those IDs. Normal --no-trunc lists, rather than JSON-only output, now show only the header and no records. Inspecting the screenshot's n9ocvtmj2fqn8dpcukeudv9jw record returns not found. Runner image remains available and Docker responds. No image/cache prune or Docker restart was issued; other Grain builds were occurring during diagnosis, so inventory totals are not asserted byte-identical across this interval. Future builds can add records again.

Subsequent verification caught a newly completed Grain/docker/quality.Dockerfile record, e93q190f77z3d9ek6pibza5mc, created after the eight-record removal. Deleted that ninth completed record separately and verified a header-only normal list again. This explains why new entries may reappear during ongoing Grain development; no builds were stopped.

User requested a final targeted removal of the screenshot's Github-Runners n9ocvt record only. Reissued exact-ID deletion for n9ocvtmj2fqn8dpcukeudv9jw; normal listing has no Github-Runners record and inspect confirms deleted/file does not exist. Unrelated Grain records were not selected in this operation. Desktop may retain a displayed deleted entry.
