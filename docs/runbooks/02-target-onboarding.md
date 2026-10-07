# Target onboarding

Status: implementation plan; no App or runners created. Repeat these steps for each new repository or organization.

1. Run [host preflight](01-host-preflight.md). Establish trusted workflows, required toolchains, and resource limits before deploying.
2. Choose repository scope for a personal repository, or organization scope for an organization. Confirm target administrator/owner authority and which repositories should be allowed.
3. Create or select a GitHub App. Repository bootstrap needs repository Administration write; organization bootstrap needs organization Self-hosted runners write. Disable incoming webhooks. Record any additional endpoint permissions separately.
4. Install the App under the intended owner with the narrowest supported access. Record non-secret App and installation IDs. Store its private key under ignored `.local/secrets/` with restricted host access. Job containers must never receive that key.
5. Copy `config/targets.example.json` to ignored `.local/targets.json`. Add a unique target ID, correct scope/owner/repository, App references, routing labels, and approved runner limit. Null App IDs in the example are deliberately incomplete. Labels do not grant repository access.
6. Validate configuration and installation access using the forthcoming tooling. Start runners only after provisioning, isolation, and cleanup checks pass.
7. Run a trusted smoke workflow against the intended label. Verify a second job uses a fresh runner and workspace, and record disposal and recovery evidence.

Adding a target should require configuration and GitHub installation authorization rather than code edits or target-specific image builds. The controller, schema validator, deployment files, and smoke workflow are not implemented yet.
