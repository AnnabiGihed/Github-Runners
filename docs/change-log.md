# Change log

## 2026-10-08: Distinguish runner slots from Docker containers

- Investigated another container-count/disk screenshot: four owned runner/daemon pairs, newer queued/running workflows and observed completion/replacement in supervision logs. Separate screenshot .NET container was no longer present; no unrelated workload was touched. Clarified the warm-pool baseline in desktop status/maintenance and runbook; retained four-slot capacity and active supervision.

## 2026-10-08: Scoped live disk cleanup

- Audited logical Docker storage and confirmed normal completed-job deletion/replacement. With explicit user approval removed six unshared unused December 2024 cache records, reclaiming about 1.28 GB; cache fell from 5.136 to 3.855 GB. Kept current/recent images/cache, jobs, Docker and supervision active.
- Added preview/apply exact-cache tooling and desktop Clean obsolete disk cache. Future runner images carry a project label; successful builds invoke label/age-scoped dangling-image cleanup. Dependency-retained obsolete cache and unclear-provenance records remain; no global prune or VHDX shrink is claimed. Decision 0021 records policy and evidence.

## 2026-10-08: Resume queued personal workflows

- Diagnosed queued workflows with Docker available but intentional persistent stop, zero slots and no running controller. Resumed through the saved service command at the user's request. Added explicit stopped-pool guidance to desktop status and the runbook; job completion cleanup remains automatic while active supervision replenishes. Live assignment evidence is in personal operations validation.

## 2026-10-08: Keep Docker available during cleanup

- Applied the user's no-shutdown policy: removed the desktop shutdown action, converted legacy memory release calls to cleanup-only, and blocked the old backend restart/cold-start test before mutation. Disposable job environments are still destroyed; shared images/build caches and unrelated workloads remain available. Decision 0020 supersedes the shutdown part of 0019 and records RAM/cache limitations.

## 2026-10-08: Stopped cleanup and memory release

- Found four exited runner containers and running job daemons after supervision stopped without a persistent stop. Saved cleanup-only controller mode and stop helper; executed them to remove all recorded runner/daemon/volume/network resources while retaining diagnostics and stopped state.
- Supervisor now retries cleanup after stop until retained jobs/environments disappear, without replenishment. Added optional guarded Docker Desktop shutdown and desktop Stop & release memory action; no actual backend shutdown or global WSL/cache settings were changed in this work. Regression fixture and desktop smoke passed; see decision 0019 and validation.

## 2026-10-08: Windows PowerShell desktop launch compatibility

- Fixed the public launcher and shortcut generator to run under Windows PowerShell 5.1 and hand off to a verified existing PowerShell 7.4+ runtime. Added runtime discovery, explicit-path support and actionable missing-runtime errors; app/controller requirements remain unchanged. Recorded the choice in decision 0018 and added actual legacy-shell regression checks.

## 2026-10-08: Native desktop runner manager

- Added WPF setup/targets, status and maintenance screens with asynchronous allowlisted script actions, protected key import, validated atomic target edits, guarded removal, workflow-label copying and a local shortcut generator. Decision 0018 and runbook 09 record prerequisites, security choices, rollback and limits.
- Isolated transaction tests and actual window/dispatcher/status smoke passed; read-only live pool worker displayed busy production registrations. Existing personal jobs/configuration were left running. Full fresh/organization GUI onboarding and previously listed acceptance checks remain unperformed.

## 2026-10-08: Reusable onboarding guide refresh

- Corrected stale onboarding planning language. Documented existing repository/organization configuration, protected keys, validation, graceful activation, labels, capacity redistribution and rollback. Decision 0005 distinguishes implemented tooling from unperformed additional-target acceptance. No live configuration changed.

## 2026-10-08: Official GitHub CLI package

- Replaced distribution `gh` with GitHub's signed APT repository, scoped keyring and verified published checksum. Official candidate 2.102.0 passed build-time and offline minimum 2.101.0 checks and existing image toolchain checks.
- Added live CLI version inspection and performed a graceful scheduled-service image rollout. Decision 0017 records provenance, package selection, update policy and alternatives; CLI validation records the resolved image and live results. Organization remains deferred.

## 2026-10-08: Continuous personal operation and recovery acceptance

- Deferred organization rollout as requested. Installed interactive-user logon supervision and a five-minute watchdog; production no longer expires hourly. Persistent stop/resume, exclusive locks, Docker readiness/relaunch and state-preserving error retries are saved and documented in decision 0016/runbook 08.
- Added protected, redacted, bounded runner/worker diagnostic checkpointing and retention outside disposable containers. Tested stopped-container collection without raw host staging, retention/ownership and representative redaction.
- Live probe runner failure, abrupt controller exit and injected API outage recovery passed. Four concurrent local C/Docker/PostgreSQL/bundled-Node workloads passed; all probe environments were removed. Stopped Docker Desktop only after safe drain/no active containers, and verified automatic engine/four-runner restoration by the scheduled supervisor.
- Balanced per-slot resources after observing a throttled .NET build, and added live aggregate budget validation plus effective daemon/runner isolation/resource checks. Preserved existing busy jobs and tightened idle cleanup to deregister before local destruction so rejected deletion retains resources.
- Confirmed successful self-hosted CI (build-test/companion/Sonar), Lua/addon, docs, project hierarchy and review runs. Later review retries passed after an operator-signoff step failure. Saved scoped App-authenticated public status inspection and observed-concurrency reporting without new permissions or PATs.
- Detailed evidence and unperformed physical reboot/network/cancellation/GitHub container-action tests are in personal operations validation. Synthetic four-slot success is separate from observed real-job concurrency. Relevant PowerShell parsing, configuration, resource, App and diagnostic checks passed.

## 2026-10-08: Project automation routing verified on main

- User requested routing project automation locally. Read RaidManager's existing published configuration rather than creating duplicate workflows. Public raw main files for project-hierarchy.yml, dependency-task.yml, and review.yml all declare runs-on: [self-hosted, linux, pc-personal]. No workflow edit or permission expansion was needed.
- Added reusable public routing audit tooling. The unauthenticated contents API hit its rate limit; explicit workflow filenames use public raw files as a read-only fallback without authentication. The previously published feature branch subsequently returned 404; no branch recreation was attempted.
- Verified routing configuration only, not a successful local project automation execution. Existing workflow tokens/permissions remain responsible for API authorization; no provisioning credentials are delivered to jobs. Earlier GitHub-hosted review observations predate this current-main audit.

## 2026-10-08: Four-slot personal capacity and toolchain rollout

- Interpreted the user's four-concurrent-job request as four personal slots within the existing host cap of four, while the organization is inactive. Added a reusable validated capacity setter and decision 0015; live local configuration validates with MaximumJobs=4. The two-plus-two example remains appropriate when both targets are configured.
- Prior controller reached its drain timeout and retained the busy job's environment. After CI completed, started a new bounded one-hour session to clean the retained environment and provision from the verified toolchain image. No busy job was forcefully removed.
- The completed CI's build-test failed Coverage comment with exit 127; companion passed and Sonar failed an HTTPS finding. New toolchain availability does not yet establish successful workflow retests.
- New session provisioned four runners; configuration tests passed. Pool inspection confirmed online ephemeral/unprivileged/volume-only/no-published-port runners, but job turnover prevented a simultaneous four-online snapshot. Adjusted the inspector to omit starting/completing resources rather than fail on their missing configuration. Four simultaneous successful jobs and representative resource-load measurements remain unverified.

## 2026-10-08: Preinstalled workflow toolchain

- Added build-essential, unzip, OpenSSH client, gzip, Git, curl, jq, gh, and CA certificates to the runner Dockerfile's root build stage; runtime remains USER runner. Retained pinned Docker CLI/Buildx and per-job daemon access. Rationale and mutable apt-version limitation are recorded in decision 0014.
- Built the image successfully and verified all required commands, Docker 29.8.2/Buildx 0.37.2, gh 2.45.0, non-root execution, writable-path environment, and successful C compilation/execution in a network-disabled smoke container. No claim yet that the Lua workflow or PostgreSQL tests pass.
- Requested graceful controller stop for rollout. Busy CI is allowed to finish; replacement session must start only after drain/cleanup completes. Companion in CI run 37703881764 succeeded, confirming that job's .NET path fix. Build-test was still running; Sonar failed an HTTPS-enforcement finding.

## 2026-10-08: User fixes and subsequent workflow checks

- User reported removing Lua sudo and fixing Sonar/docs findings. Observed feature commit `451082e84b7c23268c70d2dfcf2318f5714dbbd1`: addon run `37703881745` now fails at Build Lua 5.1.5 with exit 127; docs runs `37703881909` and `37703881758` still fail Work item hierarchy with exit 1. Public annotations do not establish the underlying missing command or hierarchy error. These observations do not establish whether later unpushed fixes exist.
- CI run `37703881764` had build-test and companion running on separate personal runners, with sonar queued. Success of the .NET fix and Sonar changes remains unverified.
- Pool inspection confirmed two online, ephemeral, unprivileged personal runners with only job volumes, no published ports, and writable .NET install paths. Controller output confirmed used environments removed and fresh runners provisioned.
- Review runs `37703978977` and `37703978773` succeeded on GitHub-hosted runners; all-workflow self-hosted migration is still incomplete.
- Extended saved public status inspection with bounded `-Count` and commit/branch/creation metadata so fixes can be matched to exact runs rather than assumed from recency. No authentication or App permissions were changed.

## 2026-10-08: First existing CI outcomes and .NET image rollout

- Existing addon, docs, and CI jobs all selected personal self-hosted runner identities and completed. The runs failed: Lua sudo dependency; companion/build-test .NET installation permissions; SonarCloud code findings; docs work-item hierarchy check (root cause not established from its generic annotation).
- Built/smoke-tested the .NET install-path image fix, requested graceful controller stop, and observed all busy jobs finish with owned environments removed. Preparing a new one-hour session on the corrected image. No running job was forcefully stopped.
- The .NET fix still needs a CI rerun; Lua workflow changes, docs hierarchy diagnosis, Sonar findings, and migration of the separately observed GitHub-hosted review workflows remain outstanding. No claim of successful full CI or all-workflow migration.
- Verified the new session has two online ephemeral production runners, unprivileged/volume-only/no host published ports, with the corrected .NET install path writable. Session is bounded to one hour; no unattended service is installed.

## 2026-10-08: Existing CI picked up personal runners

- Confirmed addon Lua and CI Sonar jobs executed on distinct production pc-personal runner identities; the controller removed their used environments and replenished them. Companion also picked up a fresh runner; docs remained active during observation.
- Public annotations confirmed Lua sudo failure, .NET /usr/share/dotnet permission failure, and SonarCloud code findings. Added saved public status/annotation inspection and documented precise limits in decision 0014.
- Prepared the user-writable .NET SDK path in the runner image and a saved graceful-stop request. Active sessions retain their original image content ID; image rollout requires drain/restart. Lua workflow edits and successful CI retest remain pending.

## 2026-10-08: Existing CI test routing enabled

- User chose existing CI instead of a separate smoke workflow and is committing the self-hosted runs-on change; the commit automatically triggers CI.
- Under the user's explicit all-self-hosted routing choice for the temporarily public personal repository, set trustedPublicWorkflows=true in ignored local configuration using saved tooling. This is an operator acknowledgement, not enforcement against untrusted workflow code.
- Starting a bounded one-hour personal controller session with two slots to accept the user's CI run. Online/CI results will be verified separately; organization capacity remains unconfigured.

## 2026-10-08: Personal controller registration verified

- Added bounded host warm-pool controller with exclusive lock, token renewal, ownership-checked persisted cleanup, startup-failure limit, idle replacement, and shutdown drain. Corrected helper command-name collision and single-label serialization exposed by initial tests.
- Verified two temporary personal runners online, locally configured ephemeral, unprivileged, volume-only, and without published host ports. Tests used random labels without defaults; no normal workflow ran. Both environments were removed after the bounded test.
- Added per-slot read-only bundled-runtime mounts and completed another bounded provisioning/cleanup cycle; real container jobs remain untested. Pool inspection was adjusted for concurrent cleanup.
- Saved a manual two-job smoke workflow template and controller runbook. RaidManager is temporarily public and final routing is intended to be fully self-hosted, per the user. GitHub CLI OAuth is unavailable; no PAT or workflow-write permission fallback was used, and the template was not published to RaidManager.
- Production runners are not left running. Real jobs, replacement after a job, service/container actions, failure recovery, durable diagnostics, unattended startup, and organization rollout remain pending.

## 2026-10-08: Personal App live access verified

- Found the user-provided PEM at the expected ignored path and restricted its ACL with saved tooling.
- Outbound live validation succeeded outside the network-restricted sandbox: installation identity/permissions and repository runner API access verified; temporary token revoked. No secrets displayed or runner registered.
- Recorded sanitized evidence in docs/validation/2026-10-08-personal-app-access.md. Workflow execution and controller lifecycle remain pending.

## 2026-10-08: Personal key placement check

- User reported the downloaded key was saved. The expected .local/secrets/personal-app.pem file was not found, and the secrets directory was empty. Filename-only checks found no PEM file under the repository or Downloads. No key contents were read.
- Added saved Windows ACL-hardening tooling for a regular key file; real key hardening and live GitHub checks remain pending the file's actual location.
- Verified ACL hardening on a disposable non-secret local fixture and removed it afterward; inheritance disabled and current-user-only access verified. Whitespace checks passed.

## 2026-10-08: Personal installation identifiers configured

- User supplied App ID 5230141 and installation ID 169036597. Created ignored personal-only .local/targets.json using saved initialization tooling; retained two job slots and the four-job host cap.
- Structural validation and ignore checks passed. Created the local secrets directory, but no private key has been received or read. Live installation/access checks remain pending.

## 2026-10-08: Guided personal App setup

- Added a screen-by-screen personal App walkthrough with authentication-only settings, selected RaidManager installation, distinct App/installation IDs, ignored PEM path, and live-validation prerequisites.
- Verified current official registration, installation, and key-management documentation. User creation/installation has not yet been confirmed. No App was created or secret handled in this step.

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

## 2026-10-08 — Reliability review

Reviewed lifecycle, supervision, authentication, desktop, diagnostics and maintenance without stopping Docker or production. Fixed cache provenance selection, misleading desktop active status and CLI inspection race. Seven fixture suites passed; four live runners online with isolation/resource checks passing. Documented open restart-timeout, oversized-diagnostic and output-memory risks plus outstanding failure acceptance in docs/reviews/2026-10-08-reliability.md; decision 0022. No 100% uptime claim.

## 2026-10-08 — Demand scaling trial

Added optional per-target demand mode with outbound Actions-read polling, custom-label matching, current-attempt pagination, bounded desired capacity and safe idle scale-down; warm mode remains default and rollback. User approved App permission and live queue read passed. Policy/controller transition fixtures, restart handoff, configuration/App/GUI guards and existing cleanup/resource/diagnostic tests passed. Live activation is in progress with busy environments retained; final acceptance evidence is in runbook 10. No Docker shutdown or PAT.

Trial checkpoint: live zero-to-demand provisioning verified at 10:22 UTC; addon and docs runs succeeded on fresh runners, and addon environment teardown was verified. Pool shrank to one active CI job with zero queued demand; idle-zero after CI completion remains pending. Desktop checkbox and read-only UI smoke passed. See runbook 10 for exact run links and limits.

Final demand checkpoint: CI succeeded; cached-queue repeat provisioning prevented by requiring a fresh successful scan for scale-up. Controller regression passed and refinement applied gracefully. At 10:33 UTC Docker had zero containers/volumes, supervision stayed active and queue demand was valid/zero. Shared images/cache retained.
