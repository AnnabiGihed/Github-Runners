# Host preflight

Status: saved tooling; execution pending.

From the repository root, run:

```powershell
./scripts/host/Test-RunnerHost.ps1
```

The script reads the Docker context, verifies a local socket/named-pipe endpoint, connects to the engine, checks Linux container mode, and reports versions, architecture, engine resources, and existing container counts. It creates no containers and changes no Docker settings. It suppresses raw Docker diagnostics to avoid storing sensitive host details.

Copy sanitized results into a dated document under `docs/validation/`. Failure requires diagnosis; do not bypass the endpoint check by enabling a Docker TCP listener. Do not stop existing workloads to satisfy the preflight.

This check does not establish WSL2 configuration, available resource headroom, outbound GitHub access, LAN isolation, firewall state, image compatibility, or job execution. Those need separate checks during implementation.
