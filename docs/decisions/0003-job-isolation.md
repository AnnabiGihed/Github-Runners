# 0003: Disposable jobs and separated provisioning

- Date: 2026-10-07
- Status: accepted isolation constraints; Linux container baseline proposed
- Related requirements: Docker, ephemeral runners, no port exposure

## Context and decision

Use a new job container/workspace for every job, with GitHub ephemeral registration or JIT configuration. Destroy writable job state after exit; reconcile failed/abandoned registration. Preserve sanitized diagnostics outside disposable job state. A trusted provisioning component may manage Docker locally, but workflow containers receive no host Docker socket, named pipe, host drives, or App key.

Use unprivileged job execution and explicit resource limits. Propose Linux runners in Linux containers on Docker Desktop for this Windows PC, subject to backend readiness and workload requirements.

## Alternatives and rationale

Persistent registered runners or reused workspaces conflict with ephemeral isolation. `--once` alone does not establish GitHub ephemeral registration. Host-socket mounts simplify Docker jobs but give workflow code host/container management authority. Privileged nested Docker is not a safe default. Native Windows runners would not satisfy the proposed Linux-container workload and need a separate compatibility decision if Windows jobs are required.

## Consequences and limitations

Docker-in-Docker jobs, container actions, and service containers need an explicit compatibility design. Containers share a kernel, so single-job disposal does not make hostile workflows safe on a personal PC. Do not route untrusted forks to this machine without an appropriate isolation design. No published ports does not block outbound LAN access. Versions, limits, log retention, networking, and replenishment remain undecided.

## Sources and validation

See [official sources](../references/official-sources.md): runner reference and Docker security. No images or containers have been built or launched. Isolation and cleanup acceptance checks remain pending.
