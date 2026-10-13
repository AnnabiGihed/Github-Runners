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
