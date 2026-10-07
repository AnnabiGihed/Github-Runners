# 0010: Trusted privileged job-local Docker on Docker Desktop

- Date: 2026-10-08
- Status: accepted by explicit user choice; implementation and runtime validation pending
- Supersedes: pending isolation selection in decision 0009 and proposed dedicated VM

## Decision and authorization

The user declined a dedicated VM and explicitly accepted disposable privileged job-local Docker for trusted workflows. Continue directly on Docker Desktop's Linux backend. Keep runner processes unprivileged where compatible; the job-local daemon container is the explicit privilege exception to the earlier minimal-capability baseline.

Use a Unix socket for the job-local daemon, never a Docker TCP listener, including inside the container. Do not mount the host Docker socket/named pipe, host directories, App keys, or controller state into the job environment. Job-local workspace/socket volumes are permitted and must be uniquely owned and destroyed with the job. The trusted host provisioner retains lifecycle authority; jobs do not receive that authority.

## Rationale and alternatives

A dedicated VM was declined. Host-socket sharing violates project constraints. Privileged nested Docker permits conventional Docker builds, container actions, and service containers, at the cost of weaker isolation in Docker Desktop's shared Linux kernel. Do not label this a sandbox for hostile code; exclude untrusted forks and attacker-controlled workflow inputs.

## Consequences and implementation checks

The default Docker-in-Docker image entrypoint enables a TCP listener even when TLS is disabled; implementation must explicitly start the daemon with only a Unix socket and verify no TCP listener exists. Service ports may be used inside the job's disposable environment, but may not be published on the PC. No runner image or controller is implemented yet.

Approved WSL budget is 8 CPUs and 16 GB RAM. The existing .wslconfig has memory=4GB and processors=2. Save a reusable narrow-update script, preserve unrelated settings, and back up the old file under ignored .local/host-backups. Do not silently restart all WSL distributions; activation and verification remain separate from writing configuration.

## Sources and validation

- [Official Docker-in-Docker image documentation](https://github.com/docker-library/docs/blob/master/docker/README.md): default TCP listener behavior, checked 2026-10-08.
- [Microsoft WSL configuration](https://learn.microsoft.com/windows/wsl/wsl-config): global resource settings and restart behavior, checked 2026-10-08.
- Resource-script syntax and application results are recorded in the change log. Container/workload compatibility remains unverified.
