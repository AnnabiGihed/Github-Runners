# Personal account App walkthrough

Date: 2026-10-08. Status: instructions prepared; user creation/installation not yet confirmed.

## Create the App

Sign into AnnabiGihed and open https://github.com/settings/apps/new.

| Form field | Value |
| --- | --- |
| GitHub App name | Suggested: AnnabiGihed Personal Runners; choose another unique name if unavailable |
| Description | Ephemeral Docker runners for personal repositories |
| Homepage URL | https://github.com/AnnabiGihed/Github-Runners |
| Callback URL | Blank |
| Request user authorization during installation | Unchecked |
| Enable Device Flow | Unchecked |
| Setup URL | Blank |
| Webhook Active | Unchecked |
| Webhook URL and secret | Blank |
| Repository permissions → Administration | Read and write |
| Repository permissions → Metadata | Required read-only default |
| Other repository, organization, and account permissions | No access |
| Where can this GitHub App be installed? | Only on this account |

Leave user-token expiration at its default. No client secret is needed for this installation-authentication flow. Click Create GitHub App and record the App ID from its settings page; the current tooling uses App ID, not Client ID.

## Install on the repository

From the new App's left sidebar, choose Install App, then Install beside AnnabiGihed. Choose Only select repositories and RaidManager, then Install. On installed-App configuration, record the numeric installation ID from the URL ending in /installations/NUMBER. App ID and installation ID are different identifiers.

To later support another personal repository, add it to this installation's selected repositories and add a repository target to configuration. Choose its capacity without exceeding the host-wide four-job budget, or explicitly revise that budget after resource checks.

## Save the key locally

Return to the App settings, scroll to Private keys, and select Generate a private key. GitHub downloads a PEM file. Store it at the repository-relative ignored path .local/secrets/personal-app.pem with access restricted to the provisioning user. Never paste its content in chat or commit it. Do not generate an OAuth client secret for this setup.

Provide the non-secret App ID and installation ID to finish local configuration, or enter them yourself. The organization target must be excluded from a personal-only configuration until its credentials are ready; the validator otherwise rejects its null IDs. Never use AllowIncomplete for a live access check.

Saved initialization tooling: `./scripts/config/Initialize-PersonalTarget.ps1 -AppId YOUR_APP_ID -InstallationId YOUR_INSTALLATION_ID`. It creates an ignored personal-only configuration from the repository example, creates the secrets directory, validates structure, and refuses to overwrite existing configuration.

Session progress on 2026-10-08: the user reported App ID 5230141 and installation ID 169036597. Initialized personal-only local configuration with those identifiers; structural validation passed and Git ignore coverage was verified. Real installation ownership/permissions remain unverified until a local private key is available.

## Validate

Once a personal-only .local/targets.json and protected PEM are in place, run PowerShell 7.2+ from the repository root:

```powershell
./scripts/github/Test-RunnerGitHubAccess.ps1 -ConfigPath .local/targets.json
```

The script validates installation identity and permissions, reads the runner API, and attempts to revoke its temporary token. It does not register runners or execute workflows. Record sanitized results in docs/validation after the actual check.

Before validation, restrict the actual PEM file ACL with `./scripts/github/Protect-RunnerAppKey.ps1 -Path .local/secrets/personal-app.pem`. This disables inherited permissions and grants only the current provisioning user; it does not print key contents. Run as the Windows identity that will operate the provisioner.

## Rationale and authoritative references

Authentication-only App: no inbound webhook, OAuth flow, user permissions, PAT, or client secret. Repository Administration write is needed for the runner API and is broad, so limit installation to selected repositories. Only-on-this-account matches the current personal ownership boundary; other owners need their own installations and App visibility selection.

Verified [GitHub registration instructions](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app), [installation instructions](https://docs.github.com/en/apps/using-github-apps/installing-your-own-github-app), and [private key instructions](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/managing-private-keys-for-github-apps) on 2026-10-08. This records guidance, not successful manual setup.
