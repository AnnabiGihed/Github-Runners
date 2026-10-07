# 0007: Organization sharing, workload scope, and capacity

- Date: 2026-10-08
- Status: accepted workload/capacity requirements; execution architecture pending
- Related requirements: organization-wide reuse, Docker execution, ephemeral isolation

## Context and decision

The user requested shared runner availability across Pivot-Softwares repositories and confirmed Docker builds, container actions, service containers, and Windows jobs. The user approved one concurrent job per target: one for AnnabiGihed/RaidManager and one shared across Pivot-Softwares. Keep this limit across all OS pools within a target, rather than giving each OS an additional slot.

An organization pool may serve multiple authorized repositories. Each ephemeral runner still executes at most one job; fresh replacement runners supply subsequent capacity. Runner-group repository access and workflow labels are separate controls. Requested all-repository access is recorded; public-repository eligibility and safe trigger policy remain unverified.

## Compatibility findings

GitHub documents that Docker container actions and service containers require Linux runners with Docker. Linux Docker runner images do not execute Windows jobs. Windows jobs therefore need a separate Windows execution environment and routing. Docker Desktop documents switching between Linux and Windows daemons; do not assume the existing host can provide both pools concurrently without a separately validated engine/backend design.

Current GitHub access-management documentation explicitly includes GitHub Free organizations for additional self-hosted runner groups and permits all-repository access. Another GitHub runner-group concept page currently names Team; verify actual organization settings before declaring controls operational. Public repository access is disabled by default in the documented group setup and must not be silently enabled.

## Alternatives and rationale

A single Linux runner image would miss the Windows requirement. Routing Windows jobs to GitHub-hosted runners changes the self-hosting requirement and needs the user's choice. Host Docker socket access or privileged nested Docker would change the documented isolation baseline and is not implicitly authorized by requesting Docker builds. Investigate compatible separate job-local engines or Linux container hooks before selecting an implementation; rootless compatibility and service-network/workspace semantics need tests.

## Consequences and limitations

The initial Linux-only baseline is insufficient for the complete requested workload. The existing example's maxRunners values are now approved capacity values, but its schema cannot yet describe OS scheduling or nested container support. No deployment claims are warranted. A Windows routing question is pending; Linux Docker design and documentation can proceed independently.

## Subsequent user clarification

On 2026-10-08 the user clarified: "no need for windows jobs". This supersedes the Windows workload requirement and pending Windows routing question above. Proceed with Linux Docker runners only; no Windows pool or GitHub-hosted Windows exception is needed. Docker builds, container actions, and service containers remain required. Per-target capacity remains one job, up to two total. The historical compatibility findings remain useful context, not current Windows implementation work.

## Sources and validation

Verified official documentation search on 2026-10-08:

- [Runner reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners): Linux/Docker requirements for container actions and service containers.
- [Runner group access management](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/manage-access): Free organization eligibility, all-repository access, public repository defaults.
- [Runner groups concept](https://docs.github.com/en/actions/concepts/runners/runner-groups): differing plan wording; live settings remain the acceptance evidence.
- [Docker Desktop Windows installation](https://docs.docker.com/desktop/setup/install/windows-install/): Linux/Windows daemon switching and Windows installation requirements.
- [Container customization](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/customize-containers): Linux runner container-hook support; no implementation selected.

Local shell execution again failed before starting. No Docker engine, Windows support, GitHub group setting, workload, commit, or push has been tested.
