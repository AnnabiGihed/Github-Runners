# 0001: Repository-local skills and organized records

- Date: 2026-10-07
- Status: accepted
- Related requirements: recordkeeping, repository-managed artifacts, skills first

## Context and decision

The repository was empty apart from `.git`. Keep four focused skills under `.agents/skills/`: authentication, lifecycle, Docker isolation, and project records. `AGENTS.md` explicitly routes future work to them. Keep shared requirements and decisions under `docs/` and implementation files in the layout described by the documentation index.

## Alternatives and rationale

Global user skills would affect unrelated projects and would not keep the canonical sources in this repository. One large skill would load unrelated procedures for each task. More granular skills would duplicate constraints without a demonstrated benefit. Four skills cover the distinct responsibilities without adding a plugin or external dependency.

## Consequences and limitations

Skills are project-scoped and versionable. Actual automatic discovery depends on the Codex client; explicit routing remains in `AGENTS.md`. Do not install global copies or claim they are globally installed. Future directories are created only when they have real files. Skill frontmatter is kept minimal; optional UI metadata is omitted because no custom UI was requested.

Ignore `.local/`, environment files, private-key extensions, and Python caches. Public examples may be committed; real secrets may not. Store key-management procedures and redacted evidence instead of secret values. No commit or push is part of this stage.

## Sources and validation

Used the bundled `skill-creator/SKILL.md` instructions for scope, naming, progressive disclosure, and validation. See [foundation validation](../validation/2026-10-07-foundation.md).
