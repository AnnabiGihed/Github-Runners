---
name: runner-docker-security
description: Prepare and harden Docker runner images and execution on a Windows PC, with no exposed ports and explicit separation of provisioning from workflow jobs.
---

# Docker runner isolation

Read `docs/requirements.md`, `docs/decisions/0003-job-isolation.md`, and official source links. Use `runner-project-records` alongside this skill.

Start with read-only preflight: Docker client/server versions, current context/endpoint, Linux versus Windows container mode, WSL2/backend status when relevant, architecture, resource availability, and existing workloads. Docker CLI presence is not evidence that the engine works. Save authored diagnostic tooling in `scripts/`; record sanitized results in `docs/validation/`.

Linux runners in Linux containers are a proposed baseline, not Windows runners. Establish required toolchains and whether jobs use Docker builds, service containers, container actions, or Windows binaries before selecting an image or promising support.

No published ports, host networking, inbound tunnels, or TCP Docker API exposure. Outbound-only networking does not isolate jobs from the LAN: assess access to local services and sensitive networks separately. Validate the rendered deployment configuration and actual container port bindings.

Run job containers as an unprivileged user with minimal capabilities, `no-new-privileges`, CPU/memory/PID limits, and only necessary writable paths. Keep seccomp enabled. Evaluate a read-only root filesystem against actual runner/tool requirements instead of promising compatibility. Never mount host drives, App keys, controller state, or the host Docker socket/named pipe into job runners.

A trusted local provisioner may need Docker lifecycle access; document its authority and keep it outside the workflow trust boundary. A mounted read-only Docker socket still exposes the Docker API. Containers share a kernel and are not a sufficient boundary for hostile workflow code on a personal PC. Exclude untrusted fork jobs until an appropriate isolated design is explicitly established.

If jobs require nested Docker features, document compatible isolated options and their tradeoffs before implementation. Do not silently enable privileged mode or host-socket access to make a job pass.

Pin image digests and runner/tool versions, verify official release checksums, and record provenance and maintenance policy. Keep image builds free of secrets and bake no registered runner state into images. Preserve disposable workspaces between no jobs; distinguish intentional dependency caches from job credentials/output.

Validate effective user, capabilities, mounts, networks, resource limits, secret visibility, and cleanup using actual containers when available. Do not alter Docker Desktop settings or install components during preflight without a documented implementation need.
