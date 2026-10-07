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

Initial preflight and onboarding runbooks are available. Docker deployment assets do not exist yet; target configuration is an example pending implementation and validation.
