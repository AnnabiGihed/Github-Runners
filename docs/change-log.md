# Change log

## 2026-10-08: GitHub App authentication client

- Added host-side RS256 JWT signing, installation identity/permission checks, narrowly scoped tokens, sanitized API errors, and live access-check tooling with token revocation.
- Offline signature/tampering and installation-mismatch tests passed with a generated disposable RSA key; no real keys or HTTP calls were used. Configuration and whitespace checks passed.
- Updated App setup instructions and decision 0012. Live access tests await two installed Apps and local key/config files. Warm-pool/controller lifecycle implementation remains pending.

## 2026-10-08: Runner image and job-local Docker test

- Added official image digest resolution, locked Docker daemon/client and GitHub runner bases, narrow build context, LF shell policy, runner Dockerfile/entrypoint, and saved build tooling.
- Built local/ephemeral-github-runner:dev successfully. Network-disabled smoke check passed: unprivileged runner, config/run scripts, jq, Docker 29.8.2, and Buildx 0.37.2. BuildKit warns that Dockerfile base ARGs have no defaults; the build script supplies required pinned values.
- Passed the disposable job-local Docker test: Unix socket only, no daemon TCP API/host mounts/published host ports, nested container, and BuildKit image build. Confirmed no runner-lab containers, labeled volumes, or networks remained afterward.
- Added build/test and GitHub App setup runbooks. Decision 0011 records inputs, tradeoffs, test corrections, and remaining live workflow/controller validation. No GitHub runner registration occurred.

## 2026-10-08: WSL resource allocation activated

- Docker app restart retained the old limits. Verified the approved configuration and absence of unrelated WSL/container workloads, then ran the saved guarded backend restart.
- Host preflight now verifies 8 CPUs and 15.62 GiB memory in the Linux engine. No containers were created. Real job capacity and runner implementation remain pending.

## 2026-10-08: Privileged job-local Docker accepted

- User declined a dedicated VM and explicitly accepted privileged job-local Docker for trusted workflows. Recorded the exception and Unix-socket-only design in decision 0010 and AGENTS.md.
- Saved and parsed Set-RunnerWslResources.ps1; applied the approved 8 CPU/16 GB settings with a local ignored backup, preserving unrelated configuration. No Docker/WSL restart occurred; active engine allocation is not yet changed or verified.
- Whitespace checks passed. Runner/controller implementation and real workload/isolation tests remain pending.

## 2026-10-08: Verified Docker preflight and configuration guard

- Verified local Linux Docker engine access outside the sandbox: 2 CPUs, 3.83 GiB memory, no containers. Recorded WSL2 and host memory; measured approximately 414.7 GiB free on D:.
- Added a reusable configuration validator and host-wide four-job cap; negative tests and whitespace checks passed.
- User approved an 8 CPU/16 GiB resource budget; no settings have been applied. Documented the dedicated Linux VM option for explanation; selection remains pending.
- No App credentials, runner jobs, VM, or job-local engine have been provisioned.

## 2026-10-08: Execution recovered and commit preparation

- After the app restart, Git inspection and shell checks succeeded; confirmed the configured Github-Runners remote and main branch.
- Passed skill frontmatter, local Markdown links, PowerShell parsing, JSON parsing/capacity, and a secret-pattern scan. The bundled skill validator failed due to missing PyYAML; no dependency was installed.
- Prepared the skills, decisions, configuration example, and preflight tooling for commit/push. These checks do not establish Docker or runner readiness. See the foundation validation follow-up.

## 2026-10-08: Two jobs per target

- Updated both configuration example targets to `maxRunners: 2`, for four concurrent jobs total across the initial targets.
- Recorded user-reported hardware and superseded the earlier capacity limit in [decision 0008](decisions/0008-two-jobs-per-target.md).
- Shell execution remains unavailable; configuration validation, commit, push, and runtime testing remain unexecuted. No runners are deployed.

## 2026-10-08: Windows removed from scope

- The user clarified Windows jobs are not needed. Updated requirements and decision 0007 while preserving the earlier clarification history.
- Current workload scope is Linux with Docker builds, container actions, and service containers; one concurrent job per target.

## 2026-10-08: Workload and capacity clarification

- Recorded shared organization-wide capacity, Docker builds/container actions/services, Windows jobs, and approved one-job-per-target limits in requirements and [decision 0007](decisions/0007-workload-scope-and-capacity.md).
- Verified official Linux/Docker compatibility requirements and organization access-management documentation. Windows execution design remains pending the user's routing choice and host checks.
- Local shell read/inspection attempts still fail before startup. No new operational validation, commit, or push occurred.

## 2026-10-08: Implementation started

- Added a read-only Docker host preflight script, reusable target example, and preflight/onboarding runbooks.
- Recorded initial tooling/schema choices and pending capacity/workload inputs in [decision 0006](decisions/0006-initial-preflight-and-configuration.md).
- Attempted to read project skills/instructions, inspect Git, and run Docker version. The execution helper failed before shell startup. Previously authored skill content remains available in conversation context, but on-disk rereads could not be performed.
- New tooling remains unexecuted. Docker readiness, target access, script validation, commit, and push remain blocked by the execution helper. Implementation can continue on source files but cannot be claimed operational until execution is restored.

## 2026-10-08: Targets and reusable onboarding

- Recorded personal repository `AnnabiGihed/RaidManager` and organization `Pivot-Softwares` as user-supplied initial targets.
- Added configuration-driven reuse and repeatable onboarding requirements in [decision 0005](decisions/0005-reusable-target-onboarding.md) and project instructions.
- Exact configuration schema, onboarding tooling, organization repository selection, and live access checks remain pending.
- Attempted to read the project-records skill, requirements, and Git status; the local execution helper failed before starting the shell with `helper_unknown_error: setup refresh had errors`. Changes could be saved through the patch tool, but shell validation, commit, and push remain unavailable.

## 2026-10-08: Standing Git authorization

- Recorded the user's standing authorization to commit and push in `AGENTS.md` and [decision 0004](decisions/0004-standing-git-authorization.md).
- Attempted Git inspection; the local execution helper again failed before the shell started. Commit, push, and automated checks remain unexecuted.

## 2026-10-07: Skills and foundation

- Inspected the empty working tree and read the bundled skill-creator guidance.
- Created four repository-local skills, project instructions, ignore rules, and documentation navigation.
- Recorded requirements, open inputs, three decisions, and dated official source links.
- Confirmed the Docker executable is available without connecting to its engine or modifying settings.
- Validation evidence: [foundation checks](validation/2026-10-07-foundation.md).
- Remaining: collect deployment inputs, run saved host preflight, select the replenishment design, implement authentication/container lifecycle, and validate both GitHub scopes with real jobs.

No GitHub resources, Docker images/containers, firewall rules, or global skills were created. No commit or push was performed.
