# Decisions

| ID | Status | Choice |
| --- | --- | --- |
| [0001](0001-project-skills-and-records.md) | Accepted | Repository-local skills and organized records |
| [0002](0002-authentication-and-connectivity.md) | Accepted baseline; controller choice pending | GitHub App authentication and outbound-only connectivity |
| [0003](0003-job-isolation.md) | Accepted constraints; platform details proposed | Single-job disposal and separated job/provisioner trust |
| [0004](0004-standing-git-authorization.md) | Accepted | Standing authorization to commit and push project work |
| [0005](0005-reusable-target-onboarding.md) | Accepted requirement; implementation pending | Configuration-driven target onboarding |
| [0006](0006-initial-preflight-and-configuration.md) | Preflight accepted; schema/capacity proposed | Saved host preflight and JSON target example |
| [0007](0007-workload-scope-and-capacity.md) | Requirements accepted; architecture pending | Shared organization access, one job per target, Linux/Docker and Windows workloads |
| [0008](0008-two-jobs-per-target.md) | Accepted; operational verification pending | Two jobs per target, four total for the initial targets; supersedes earlier capacity |
| [0009](0009-docker-preflight-and-isolation-gate.md) | Preflight verified; resource/isolation choice pending | Host capacity guard and nested Docker isolation selection |
| [0010](0010-trusted-privileged-job-docker.md) | Accepted; implementation pending | Trusted privileged job-local Docker on Desktop; no dedicated VM |
| [0011](0011-pinned-images-and-job-engine.md) | Local tooling implemented; live provisioning pending | Pinned official images and disposable Unix-socket Docker smoke tests |
| [0012](0012-github-app-authentication-client.md) | Offline tested; live validation pending | Host-side App JWT, narrowed tokens, and installation access checks |
| [0013](0013-warm-pool-controller.md) | Two personal registrations verified; workload tests pending | Bounded host warm pool and ownership-checked lifecycle |
| [0014](0014-existing-ci-toolchain-compatibility.md) | Live failures identified; fixes/retest pending | User-writable .NET SDK path; Lua sudo incompatibility; preserve Sonar gate |

| [0015](0015-personal-four-slot-capacity.md) | Accepted; workload validation pending | Four personal slots while organization is inactive; retain four-slot host cap |
| [0016](0016-unattended-personal-operation.md) | Implemented; personal operational checks passed | Login supervisor, continuous operation, retained diagnostics, recovery and resource budgets |

| [0017](0017-official-github-cli-package.md) | Accepted; image verified | Official signed GitHub APT source; CLI minimum 2.101.0 |

Use [the template](template.md) for subsequent material choices. Number records monotonically and link validation. Document supersession explicitly.

Desktop manager: [0018](0018-windows-desktop-manager.md) — implemented; native WPF interface, guarded configuration transactions and existing-script orchestration. Live fresh/organization GUI onboarding remains unverified.

Stopped cleanup: [0019](0019-stopped-runner-cleanup-and-memory.md) — cleanup-only recovery, persistent teardown retries and guarded optional Docker shutdown for memory release.

Keep Docker running: [0020](0020-keep-docker-and-reusable-assets.md) — supersedes optional shutdown; disposable cleanup retains shared images/cache and engine availability.

Disk cleanup: [0021](0021-scoped-disk-cleanup.md) — exact obsolete-cache selection, approved old records and labeled aged image versions; supervision stays active.

Reliability review: [0022](0022-nondisruptive-reliability-review.md) — explicit cache approvals, accurate supervision status and documented open recovery findings.

Demand scaling: [0023](0023-outbound-demand-scaling.md) — optional outbound App-authenticated queue polling, zero idle capacity, retained busy jobs and warm-mode rollback.

Windowless supervision: [0024](0024-windowless-supervision.md) — GUI script-host wrapper prevents recurring console launches while preserving watchdog lifetime tracking.
