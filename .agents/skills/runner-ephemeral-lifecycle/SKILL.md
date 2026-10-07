---
name: runner-ephemeral-lifecycle
description: Implement and verify single-job Docker runner provisioning, outbound-only replenishment, bounded concurrency, cleanup, and crash recovery.
---

# Ephemeral runner lifecycle

Read `docs/requirements.md` and the current decisions. Use `runner-project-records` alongside this skill; use `runner-github-app` for bootstrap credentials and `runner-docker-security` for job isolation.

Choose between GitHub's documented `--ephemeral` registration and JIT configuration based on the selected controller. Do not equate `--once` alone with ephemeral deregistration. Validate compatibility against the pinned official runner release.

Design a bounded lifecycle: provision fresh workspace, obtain scoped bootstrap credentials, register a unique runner, run at most one job, preserve sanitized diagnostics, destroy job container/workspace, reconcile remote registration, then replenish. Explicitly handle failed registration, idle expiry, job cancellation, process failure, Docker/PC restart, network loss, and cleanup failure. Never resume a used job container with a restart policy.

No inbound webhooks or listeners. Compare a small warm pool, outbound job polling, and an officially supported outbound scale-set client if appropriate. Do not add Kubernetes merely to use ARC. Record the selected replenishment method, latency, resource cost, rate-limit behavior, idle timeout, and concurrency caps before implementing it.

Keep separate personal-repository and organization targets, names, labels, state, and limits. Labels route jobs; they do not provide authorization. Verify repository access using features available on the actual plan. Identify owned resources explicitly; cleanup must never remove unrelated containers, volumes, or runners. Never use global Docker pruning as routine cleanup.

Use graceful shutdown with a documented drain timeout and forced-cleanup policy. Preserve logs outside disposable containers without sharing writable log mounts with jobs where avoidable. Redact credentials and limit retention. If updates are disabled, maintain the image within GitHub's documented update deadlines and critical-update requirements.

Acceptance evidence must demonstrate two jobs use different runner identities and fresh workspaces, one runner cannot accept a second job, resources are removed after completion/cancellation, and recovery is bounded. Cover both scopes and loss of connectivity. Do not claim these checks from configuration inspection alone.
