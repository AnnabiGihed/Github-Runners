# GitHub App setup

Status: manual setup instructions; no App or installation created by this project yet.

Prepare two Apps initially to separate authority:

1. Under personal account developer settings → GitHub Apps, create an App with a unique name and project repository homepage URL. Disable the active webhook setting. No OAuth callback or user authorization flow is required for installation authentication. Grant repository Administration read/write only for runner management. Install it on AnnabiGihed/RaidManager using selected-repository access.
2. Under Pivot-Softwares organization settings → Developer settings → GitHub Apps, create a separate App. Disable webhooks and grant organization Self-hosted runners read/write. Install it in Pivot-Softwares. Runner repository access is controlled separately by organization runner policy; select all repositories as requested, but do not enable public/untrusted jobs without reviewing their triggers.
3. Record each App ID and installation ID in ignored .local/targets.json, copied from config/targets.example.json. Installation ID is available in the installed-App settings URL. These IDs are identifiers; private keys and access tokens are secrets.
4. Generate each App's private key and place it in the matching ignored .local/secrets/ path. Restrict its host permissions to the user operating the trusted provisioner. Never paste keys into chat, commit them, or mount them in job containers.
5. Run scripts/config/Test-RunnerConfiguration.ps1 with the local config. Then use PowerShell 7.2+ to run `./scripts/github/Test-RunnerGitHubAccess.ps1 -ConfigPath .local/targets.json`. It checks installation identity, mints a narrowed installation token, reads the target runner API, and attempts token revocation. It prints only validation status, never tokens. Runner provisioning tooling remains pending; successful access checks alone do not prove registration or job execution.

Never invoke credential-returning module functions interactively without assigning the result: normal PowerShell output would display their returned secret objects. Do not enable transcripts, HTTP verbose/debug capture, or log request/response payloads during authentication.

For another target, repeat installation under its owner and add configuration. Do not copy a different owner's installation ID. App reuse can be evaluated later; separate Apps avoid granting unnecessary repository Administration authority to organization-only provisioning.

Official references: [Creating an App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app), [installation authentication](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app), [runner permissions](https://docs.github.com/en/actions/reference/runners/self-hosted-runners).
