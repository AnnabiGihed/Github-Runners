# Documentation index

## Start here

- [Requirements and open inputs](requirements.md)
- [Decisions](decisions/README.md)
- [Change log](change-log.md)
- [Official sources](references/official-sources.md)
- [Initial validation](validation/2026-10-07-foundation.md)
- [Host preflight](runbooks/01-host-preflight.md)
- [Reusable target onboarding](runbooks/02-target-onboarding.md)
- [Host preflight results](validation/2026-10-08-host-preflight.md)
- [Dedicated Linux VM option](architecture/linux-vm-option.md)
- [WSL resources and activation](runbooks/03-wsl-resources.md)
- [Build and local test](runbooks/04-build-and-local-test.md)
- [GitHub App setup](runbooks/05-github-app-setup.md)
- [Personal account walkthrough](runbooks/06-personal-app-walkthrough.md)
- [Personal App access results](validation/2026-10-08-personal-app-access.md)
- [Controller and real-job smoke procedure](runbooks/07-controller-and-smoke.md)
- [Unattended personal operations](runbooks/08-personal-operations.md)
- [Personal operations validation](validation/2026-10-08-personal-operations.md)

## Repository layout

| Location | Purpose |
| --- | --- |
| `.agents/skills/<name>/SKILL.md` | Versioned project skills |
| `AGENTS.md` | Project-wide instructions and skill routing |
| `docs/decisions/` | Numbered decisions and their rationale |
| `docs/references/` | Dated authoritative source links |
| `docs/validation/` | Sanitized checks and their limits |
| `docs/change-log.md` | Work performed and remaining work |
| `infra/` | Dockerfiles and deployment YAML when implemented |
| `scripts/` | Saved operational and validation tooling when needed |
| `config/` | Non-secret configuration schemas/examples when needed |
| `tests/` | Meaningful automated checks when implemented |
| `.local/` | Ignored secrets/runtime state; never versioned |

Personal runner images, GitHub App authentication, continuous supervised operation, bounded diagnostics, and disposable environment replacement are implemented. See the change log and personal operations validation for executed checks and workflow outcomes. Organization rollout is deferred.
