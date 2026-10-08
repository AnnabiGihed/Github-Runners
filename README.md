# Ephemeral GitHub runners

Docker-hosted, single-job GitHub Actions runners on this Windows PC, supporting personal GitHub Pro repositories and a GitHub Free organization.

Constraints: **no PATs**, **no exposed ports**, fresh job environments, and repository-managed documentation and tooling.

Start with [the documentation index](docs/README.md). Project skills are in [.agents/skills/](.agents/skills/); [AGENTS.md](AGENTS.md) makes their use and recordkeeping explicit.

Personal deployment is operational with four ephemeral runner slots, a PAT-free GitHub App, automatic user-logon startup, continuous supervision, disposable job-local Docker and retained diagnostics. See [personal operations](docs/runbooks/08-personal-operations.md) and [validation](docs/validation/2026-10-08-personal-operations.md). Organization rollout is deferred.

Launch the Windows desktop manager with `./scripts/desktop/Open-RunnerDesktop.ps1` from PowerShell 7.4+. It guides target configuration and offers live status and graceful maintenance. See [desktop setup](docs/runbooks/09-desktop-app.md) for the double-click shortcut and required GitHub App information.
