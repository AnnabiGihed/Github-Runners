---
name: runner-github-app
description: Design and implement PAT-free GitHub App authentication for repository and organization Docker runners, including installation boundaries and plan eligibility.
---

# GitHub App authentication

Read `docs/requirements.md`, `docs/decisions/0002-authentication-and-connectivity.md`, and `docs/references/official-sources.md` from the repository root. Use `runner-project-records` alongside this skill.

- Verify current official GitHub documentation for each endpoint, API version, permission, and plan-dependent feature used. Do not assume paid runner-group or workflow restriction features exist on GitHub Free.
- Personal accounts require repository registration; organization registration is a separate scope. An organization runner cannot serve an unrelated personal repository. Use separate installations and configuration for those scopes.
- Use an App JWT only to obtain an installation access token, then use that token for the authorized runner API. JWTs, installation access tokens, registration tokens, and JIT configuration are distinct credentials. Never substitute a PAT or rely on an undocumented runner-registration use of workflow `GITHUB_TOKEN`.
- Repository runner bootstrap requires repository Administration write; organization bootstrap requires organization Self-hosted runners write. Add Actions read only if the selected controller polls job APIs. Request no Contents write permission merely to register runners. Install on selected repositories wherever supported.
- Scope installation tokens to the required resources/permissions; refresh based on expiration. Treat 401, 403, 404, rate limits, and revoked installations distinctly. Use bounded retries and never print response bodies that may contain credentials.
- The trusted provisioning component holds the App key. A job runner receives only its own short-lived bootstrap material. Never mount App keys or controller state into job containers; never pass secrets through image layers, committed files, or logged command arguments.
- Disable incoming webhooks for the baseline. Document key provisioning, restricted file access, rotation, revocation, and installation IDs without recording secret values. Account installation authorization is distinct from token creation.

Before declaring success, validate both actual scopes separately: App installation access, bootstrap API permissions, runner registration, and a job. Sanitize evidence. Until owner/repository names and installations are supplied, mark live checks pending rather than guessing targets.
