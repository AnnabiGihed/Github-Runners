# 0009: Docker preflight, capacity guard, and isolation selection

- Date: 2026-10-08
- Status: host observations verified; isolation/resource choices pending

## Context and decision

Docker Desktop is reachable through its local named pipe outside the sandbox and provides a Linux x86_64 engine, but currently allocates only 2 CPUs and 3.83 GiB memory. Four requested job slots must not be interpreted as verified workload capacity. Record the proposed 8 CPU/16 GiB allocation separately from accepted settings; user choice is pending.

Add `hostMaxRunners: 4` to the target example and a PowerShell validator that rejects duplicate targets, malformed scopes/IDs, unsafe key-reference paths, incomplete deployment credentials, and summed target capacity above the host limit. Allow incomplete App IDs only with an explicit example-validation switch. The guard prevents adding targets from silently increasing the total job budget. Installation ownership and permissions require later live API checks.

## Alternatives and rationale

Docker builds, container actions, and service containers require a usable job-local container engine. Mounting the host Docker socket remains excluded. Docker's documented rootless Docker-in-Docker example still uses a privileged outer container to disable security restrictions; calling it rootless would not preserve the original minimal-capability baseline. A dedicated Linux VM versus an explicitly accepted privileged job-local engine are under discussion; neither has been deployed. Do not issue deployment YAML that silently selects either.

## Consequences

The user approved 8 CPUs and 16 GiB RAM and requested an explanation of the VM approach rather than selecting it. The resource budget is accepted; applying it and selecting the isolation architecture remain pending. If a dedicated VM is selected, allocate that budget to the VM instead of independently reserving another 16 GiB for Docker Desktop/WSL.

A VM adds setup and management. Privileged nested Docker gives workflow code broader shared-kernel authority and should be considered only for trusted workflows, with documented boundaries. No PAT or exposed-port requirement changes. Warm-pool/controller and image decisions remain pending until isolation selection. CPU/memory limits and logs must encompass nested services and builds.

## Sources and validation

- [Docker rootless tips](https://docs.docker.com/engine/security/rootless/tips/): documented privileged rootless Docker-in-Docker requirement, verified 2026-10-08.
- [GitHub ARC deployment](https://docs.github.com/en/actions/how-tos/manage-runners/use-actions-runner-controller/deploy-runner-scale-sets): analogous nested Docker privilege requirement; ARC is not selected.
- [Host evidence](../validation/2026-10-08-host-preflight.md).

Configuration negative tests cover incomplete App IDs, duplicate target identity, host oversubscription, and key-path traversal. Test execution results are recorded in the change log; no runner job has executed.
