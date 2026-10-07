# Official sources

Verified by official documentation search on 2026-10-07. Recheck live documentation before selecting versions or implementing endpoints; these links are references, not frozen specifications.

| Source | Relevance |
| --- | --- |
| [GitHub runner reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners) | Ephemeral/JIT behavior, outbound HTTPS, App permissions, updates and diagnostics |
| [Runner REST endpoints](https://docs.github.com/en/rest/actions/self-hosted-runners) | Repository/organization bootstrap, supported tokens and endpoint permissions |
| [GitHub App installation tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app) | Installation authentication, resource scoping, one-hour expiration |
| [Self-hosted runner concepts](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners) | Self-hosted model and operator responsibilities |
| [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) | Current billing rules; artifact/storage costs need separate consideration |
| [Docker Engine security](https://docs.docker.com/engine/security/) | Daemon authority and container isolation limits |
| [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/) | Docker API trust boundary |

Research established the baseline; actual installation permissions, organization plan features, Docker backend, and end-to-end registration remain unverified.
