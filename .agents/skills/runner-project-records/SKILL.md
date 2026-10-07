---
name: runner-project-records
description: Maintain this runner repository's organized documentation, decision records, reproducible tooling, and sanitized verification evidence during every project change.
---

# Project records

Use this skill for every phase of the runner project. Read `AGENTS.md` and `docs/README.md` first.

- Store human documentation under `docs/`: requirements, numbered decisions, architecture, runbooks, and validation. Keep `docs/README.md` current. Create architecture/runbook files when there is substantive content, not empty scaffolding.
- Store project skills under `.agents/skills/`, deployments under `infra/`, operational tooling under `scripts/`, non-secret examples under `config/`, and meaningful automated checks under `tests/`. These are project conventions; record justified deviations.
- For every material choice record context, decision, alternatives, consequences, status (accepted/proposed/superseded), date, sources, and evidence. Use `docs/decisions/template.md`. Link superseded decisions instead of rewriting history to hide changes.
- Append a dated entry to `docs/change-log.md` describing completed work, related decisions, verification, and remaining work. Record manual host/GitHub actions with reproducible instructions in a relevant runbook.
- Save any authored operational script or YAML in the repository before using it. Disposable file-inspection commands are not deployment scripts; document material diagnostic commands and results. Distinguish reviewed configuration from executed tests and live end-to-end evidence.
- Document secret types, locations, ownership, permissions, rotation, and recovery, never their values. Keep raw logs, credentials, installation responses, and job output out of Git. Ignore rules are a convenience, not a secret-control boundary.
- Before handoff review `git diff --check`, changes, links, skill frontmatter, and relevant validation. Report checks that were not run and why. Do not imply that a script, design, or runner was executed merely because its source exists.

Skill creation follows the bundled skill-creator guidance where available. Validate skills with its `quick_validate.py`; report structural validation separately from behavioral validation.
