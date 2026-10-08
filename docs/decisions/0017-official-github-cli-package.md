# 0017: Official GitHub CLI package

Date: 2026-10-08. Status: Accepted; image build and four live replacements verified.

## Context and decision

The user requires GitHub CLI 2.101.0 or later from GitHub's own package repository. This supersedes the distribution `gh` selection in decision 0014; other workflow tools remain installed during the root image build. Jobs continue as the unprivileged runner user.

Use `https://cli.github.com/packages` with an architecture-specific APT source and a repository-scoped `signed-by` keyring. Verify the downloaded keyring against the SHA-256 published in [GitHub's installation instructions](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). An APT preference for package `gh`, origin `cli.github.com`, priority 1001 selects the official package over distribution candidates. APT verifies signed repository metadata and package hashes. No authentication credentials are needed to install the package.

Follow the user's requested version range rather than an exact CLI release pin: install the current official candidate and fail the build unless the installed version is at least 2.101.0. Cached builds retain their resolved package; uncached builds can resolve a newer official version. Base images remain digest-pinned. The build smoke check separately verifies the executable's version, path and repository configuration without network access. The live pool inspector reports each runner's CLI version and warns about older draining runners.

## Alternatives and consequences

- Distribution `gh`: rejected because the prior image's 2.45.0 does not meet the requested minimum.
- Release archive or direct `.deb`: viable, but bypasses the specifically requested official APT installation workflow.
- Exact CLI version pin: improves package repeatability, but requires deliberate updates; the user requested 2.101.0 or later. Record the resolved version for each image rollout.

Keyring checksum rotation fails closed. Reverify GitHub's published checksum before updating it; never bypass signature or checksum checks. Image builds need outbound HTTPS to GitHub's package service. No PAT, App permission change, container port publication or job-time sudo is introduced.

## Validation

See [the CLI rollout evidence](../validation/2026-10-08-github-cli.md). The official repository supplied 2.102.0; keyring verification, image build, compiler/toolchain checks, unprivileged execution and offline CLI minimum-version checks passed. Rebuilding alone does not change a running controller's pinned image ID, so use the graceful service restart in runbook 08.
