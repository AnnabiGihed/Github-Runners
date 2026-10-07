# WSL resource allocation

Approved budget: 8 logical CPUs, 16 GB RAM. Applied to the user's .wslconfig on 2026-10-08 using:

```powershell
./scripts/host/Set-RunnerWslResources.ps1
```

The script backs up existing configuration under ignored .local/host-backups, preserves unrelated settings, and does not restart WSL or Docker. The setting applies globally to WSL2 distributions, not exclusively to runner jobs.

Activation requires stopping Docker/WSL safely and restarting them. `wsl --shutdown` stops all WSL distributions; coordinate with other active work before executing it. Then reopen Docker Desktop and rerun `./scripts/host/Test-RunnerHost.ps1` to verify the actual engine CPU/memory allocation. Activation has not been performed in this session.

For rollback, restore the saved .wslconfig backup to the user's profile and repeat the coordinated restart. Do not commit the backup or machine-specific configuration.
