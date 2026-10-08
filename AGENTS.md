# Project instructions

Build ephemeral GitHub Actions runners in Docker on this Windows PC for personal GitHub Pro repositories and a GitHub Free organization.

## Mandatory constraints

- Keep Docker Desktop running. Cleanup must never stop/restart Docker or WSL or drop global caches. Retain shared images/build caches while destroying disposable per-job containers, volumes and networks. Legacy shutdown tooling is disabled by decision 0020.

- Never use personal access tokens (PATs).
- Never publish container ports, open inbound firewall/router rules, create tunnels, or expose the Docker API over TCP. Outbound HTTPS is permitted.
- Each runner processes at most one job. Destroy its container and job workspace before replacement; deregistration alone is insufficient.
- Keep GitHub App private keys and installation tokens out of job containers and version control. Short-lived runner bootstrap credentials are secrets too.
- Save all authored scripts, Dockerfiles, YAML, configuration examples, and operational tooling in this repository. Document manual actions and commands in `docs/`; redact secrets rather than documenting their values.
- Record every material design, dependency, security, configuration, and operational choice with rationale, alternatives, consequences, status, and validation. Group routine related choices into one entry when appropriate.

## Skills

Project skill sources live in `.agents/skills/`. Read the relevant `SKILL.md` before work:

- `runner-github-app`: authentication, installation scopes, permissions, and plan eligibility.
- `runner-ephemeral-lifecycle`: provisioning, replacement, cleanup, and recovery.
- `runner-docker-security`: Windows/Docker preflight, images, isolation, and trust boundaries.
- `runner-project-records`: documentation, decisions, changes, and evidence; use alongside every implementation skill.

## Working conventions

Accepted isolation choice (2026-10-08): Docker Desktop directly, no dedicated VM. Privileged disposable job-local Docker is explicitly authorized for trusted workflows only; this is a narrow exception for the job-local daemon, not permission to mount the host socket or expose TCP ports. See decision 0010. Approved WSL budget: 8 CPUs and 16 GB RAM, with two jobs per target and four initial jobs total.

Initial targets are personal repository `AnnabiGihed/RaidManager` and organization `Pivot-Softwares`. Keep them in configuration; never hardcode them into reusable scripts or images. The user requires easy, documented onboarding for additional personal repositories and organizations using the same tooling. See `docs/decisions/0005-reusable-target-onboarding.md`.

Read `docs/README.md` and accepted decisions before implementation. Preserve the user's constraints. Mark proposals and unverified assumptions explicitly. Do not report deployment or checks as successful without evidence. Do not invent owner names, installation IDs, resource budgets, or supported workflow capabilities.

Use `infra/` for deployment assets, `scripts/` for tooling, `config/` for non-secret schemas/examples, and `tests/` for meaningful validation when those files are needed. Create directories when they have actual contents. Keep secrets and runtime state in ignored `.local/` paths with restrictive host permissions.

The user granted standing authorization on 2026-10-08 to commit and push project work. Proceed without asking again after reviewing changes for secrets and running available relevant checks. Use the configured project remote; do not force-push or rewrite shared history based on this authorization. Report execution or verification limitations accurately.
