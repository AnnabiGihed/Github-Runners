# Personal GitHub App access: 2026-10-08

Target: AnnabiGihed/RaidManager. App ID: 5230141. Installation ID: 169036597.

## Executed checks

- Found the expected ignored .local/secrets/personal-app.pem file.
- Ran saved Protect-RunnerAppKey.ps1: ACL inheritance disabled and access restricted to the current Windows provisioning user. Key contents were not displayed.
- Ran saved Test-RunnerGitHubAccess.ps1. The sandbox attempt failed with a sanitized transport error; the approved outbound HTTPS retry outside the sandbox succeeded.
- Verified installation App/installation IDs, owner, non-suspended status, and Administration write permission.
- Created a repository-narrowed installation token in memory and successfully read RaidManager's runner API.
- Validation token revocation completed without a warning. No key or token was printed or persisted by validation tooling.

## Limits

Runner registration remains untested. No runner was created and no workflow job was executed. Controller lifecycle, ephemeral cleanup, service/container-action compatibility, two-job concurrency, and organization access are still pending.
