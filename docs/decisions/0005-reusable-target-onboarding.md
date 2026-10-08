# 0005: Configuration-driven target onboarding

- Date: 2026-10-08
- Status: accepted requirement; configuration schema and tooling pending
- Related requirements: personal and organization support, easy reuse, repository-managed artifacts

## Context and decision

The user supplied personal repository `AnnabiGihed/RaidManager` and organization `Pivot-Softwares`, and requires an easy way to repeat setup for other personal repositories or organizations.

Use common runner images and lifecycle tooling with explicit target configuration. Each target will declare a unique identifier, repository or organization scope, owner/repository as applicable, App installation reference, labels, and resource/concurrency settings. Reference secrets by protected location; never put private keys or tokens in target configuration. Exact schema and defaults will be selected during implementation.

Keep personal repository registration separate from organization registration. Resolve an installation for each intended owner and permission scope; do not reuse an installation ID across unrelated owners. Whether to reuse one App or separate Apps depends on installation availability and permission isolation and remains undecided.

## Alternatives and rationale

Hardcoded target names, separate copied scripts, and target-specific image builds would make changes error-prone and undermine repeatability. Configuration-driven onboarding keeps maintenance in one place while preserving target isolation.

## Consequences and limitations

Provide a single onboarding runbook with clear repository and organization branches: verify prerequisites and authority, create or select an appropriately permissioned App, install it for the intended target, provision its key securely, add target configuration, validate configuration/access, start runners, and execute a smoke job. Save executable setup and validation tooling in the repository when implemented.

Adding a target may require owner authorization and a new App installation; configuration alone cannot grant GitHub access. Organization repository access must use controls available on the actual plan. Do not promise identical setup steps for permissions that GitHub distinguishes by scope.

Acceptance criteria: onboard another target without editing code or rebuilding the common image solely to change owner names; reject malformed/duplicate targets and scope/installation mismatches; keep labels, credentials, state, cleanup, and concurrency isolated per target. Verify repeat execution does not create unintended duplicate resources.

## Sources and validation

### Implementation update — 2026-10-08

The common schema, validator, scope-aware App access client and multi-target controller are implemented; personal deployment is operational. The updated runbook uses these without target-specific code edits or image rebuilds. Duplicate/capacity rejection and App mismatch checks passed existing tests. Additional-target and organization live acceptance remain unverified. Planning statements below are historical. Retain manual GitHub authorization/configuration rather than add a wizard during this documentation correction, keeping the schema as the single configuration source.

Target identities and reuse requirements came directly from the user. See [authentication decision](0002-authentication-and-connectivity.md) and [requirements](../requirements.md). No access, visibility, installations, or organization repository list has been verified. No onboarding script or configuration schema exists yet.
