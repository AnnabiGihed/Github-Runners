# 0014: Existing CI toolchain compatibility

- Date: 2026-10-08
- Status: live failures identified; .NET image adjustment built; Lua workflow adjustment pending

## Context and choices

The user's commit routed existing addon, docs, and CI jobs to pc-personal. Two completed jobs were removed and replaced with fresh identities. Public job/annotation reads verify actual runner assignment without adding Actions permissions to the App.

The .NET companion job failed because setup-dotnet tried to create /usr/share/dotnet. Set DOTNET_INSTALL_DIR=/job-work/.dotnet in the runner image, using the job-owned workspace shared with the daemon. Each job's SDK state is deleted with its workspace. Official setup-dotnet documentation supports an alternative user-writable directory. Preserve unprivileged execution and no-new-privileges rather than granting root.

The pinned leafo Lua action unconditionally executes sudo apt-get install for readline/ncurses on Linux. Its live annotation reports sudo exit 1. Do not install a fake sudo wrapper or enable passwordless root to conceal this incompatibility. The Lua workflow should use a dependency-prepared image and user-space compilation or another compatible setup step; that concrete workflow edit and package selection remain pending.

SonarCloud reported code-smell annotations; do not remove or bypass the gate to make runner migration appear successful. The user is committing in RaidManager; this runner repository's App does not have permissions to modify its workflow/code.

## Update and validation

Controller sessions pin the local runner image content ID, so rebuilding does not change active jobs or subsequent provisioning within that same session. Apply the new image after requesting a graceful controller stop, letting busy jobs drain, removing the stop flag, and starting another session. Do not forcibly remove running jobs for an image update.

Saved public-status tooling reads run/job metadata and capped annotations with token-pattern redaction, not raw workflow logs. Initial verification can race resource cleanup; the inspector reports a changing pool instead of claiming a missing container is still online. Full successful CI, real container actions/services, and four concurrent jobs remain unverified.

References: [setup-dotnet documented install directories](https://github.com/actions/setup-dotnet/tree/v6#environment-variables), [pinned Lua action source](https://github.com/leafo/gh-actions-lua/blob/6919171ccf181b826f44b9bca76307b577217377/main.js), checked 2026-10-08.
