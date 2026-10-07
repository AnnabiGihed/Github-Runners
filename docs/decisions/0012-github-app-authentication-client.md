# 0012: Host-side GitHub App authentication client

- Date: 2026-10-08
- Status: implemented and tested offline; live validation pending local App credentials

## Decision and rationale

Use PowerShell 7.2+ with built-in .NET RSA signing rather than installing a JWT library. Create RS256 JWTs with iat 60 seconds in the past and exp 540 seconds ahead. The existing App ID is a supported issuer; adopting GitHub's preferred client ID later would require a schema update. No PAT or user OAuth flow is introduced.

Before issuing an installation token, check App/installation IDs, owner, suspension, and required write permission. Repository tokens are narrowed to the configured repository and Administration write; organization tokens request organization runner write. Token results remain in the trusted caller's memory. The access-check script reads runner metadata and revokes its validation token afterward; it creates no runner registrations.

Requests go only to api.github.com with redirects disabled, 30-second timeout, fixed REST API version 2026-03-10, and sanitized status-only errors. Do not automatically retry mutations. Fail and surface authorization/rate-limit errors instead of treating a failed request as success. Managed strings cannot be reliably zeroized; clearing references and disposing RSA reduces retention but is not a secure-memory guarantee. Do not run under transcript/debug capture or print credential-returning module calls.

## Alternatives and consequences

An SDK would add dependencies for a small installation-authentication surface. PATs violate user constraints. Tokens are not yet cached for a long-running controller; the controller will need expiry-aware renewal, bounded backoff, and crash cleanup. Private-key ACL verification remains an operational responsibility documented in onboarding. No key is copied into an image, job container, or committed file.

## Validation and sources

tests/Test-RunnerGitHub.ps1 passed with an ephemeral generated RSA key: signed JWT verification, claim duration, altered-message signature rejection, and installation owner/permission/suspension/App mismatch rejection. No real private key or network was used. Configuration tests and whitespace checks also passed. Live HTTP errors, real installations, permissions, runner bootstrap, and token revocation remain untested.

Verified [GitHub JWT guidance](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app) and [App REST endpoints](https://docs.github.com/en/rest/apps/apps) on 2026-10-08.
