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

Use [the template](template.md) for subsequent material choices. Number records monotonically and link validation. Document supersession explicitly.
