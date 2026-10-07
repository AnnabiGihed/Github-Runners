# Host preflight: 2026-10-08

Executed the saved `scripts/host/Test-RunnerHost.ps1` after read-only access to the Docker named pipe was allowed outside the sandbox. The sandbox attempt returned access denied; it was not a Docker engine outage.

| Check | Result |
| --- | --- |
| Docker client/server | 27.4.0 / 27.4.0 |
| Engine OS/architecture | Linux / x86_64 |
| Engine CPU allocation | 2 |
| Engine memory | 3.83 GiB |
| Existing/running containers | 0 / 0 |
| Endpoint | Local named pipe |
| WSL default distribution/version | docker-desktop / 2 |
| Host visible memory | Approximately 47.7 GiB |
| Host free memory at check | Approximately 21.5 GiB |

The engine budget is insufficient to assume four simultaneous Docker build jobs and service containers. The user approved an 8 CPU/16 GiB budget; no setting or restart has been performed. A subsequent explicit disk query measured D: free space at 414.7 GiB and used space at 539.17 GiB. No job containers were started.

The configuration validator tests passed: incomplete deployment credentials, duplicate targets, host oversubscription, and key-path traversal are rejected; the example validates with incomplete mode. `git diff --check` passed. Structural validation is not GitHub installation or workload verification.

## Resource activation after restart

The user's Docker app restart initially left the old allocation active. Verified that .wslconfig contained the accepted values, only Docker's WSL distribution was running, and no containers were active. Executed the saved guarded Restart-RunnerDockerBackend.ps1: stop Docker Desktop, shut down WSL, start Docker Desktop. The guard rejects unrelated active WSL distributions or running containers.

The subsequent saved preflight passed: Linux x86_64, 8 CPUs, 15.62 GiB engine memory (the reported usable allocation for the 16 GB setting), local named-pipe endpoint, zero containers. Resource activation is now verified. Four real concurrent Docker build jobs are still untested.
