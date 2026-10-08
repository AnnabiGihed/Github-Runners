# 0023 — Outbound queue-based demand scaling

Date: 2026-10-08. Status: accepted for a personal trial; live completion evidence recorded separately.

## Context and choice

The user wants to try zero idle runners. Add optional per-target `scalingMode: demand`; absent/warm keeps existing behavior. Preserve four-job host cap and single-job disposal. Controller and Docker remain running. Poll every 60 seconds (configurable 60–300), creating fresh capacity for busy plus matching queued jobs, bounded by target maximum. Only scale down excess idle slots older than a two-minute startup grace; existing ownership/busy/deregistration guards remain.

Use GitHub App repository Actions read alongside existing management permission; narrow tokens accordingly. Poll queued and in-progress workflow runs because an active workflow can contain queued jobs. Read current-attempt jobs, paginate, deduplicate runs and require every requested label supported plus at least one configured target label. Ignore hosted/Windows/other-target/completed/approval-wait jobs. Stop counting at maximum; pagination-limit or API failure is unavailable demand, never empty demand. Hold existing capacity and suspend new scaling until a successful snapshot; normal completed-job cleanup still runs.

Organization code discovers installation-accessible, owner-matching, non-archived repositories; access settings and label routing still require organization acceptance. Organization live rollout remains deferred. Existing GUI edits retain advanced options; mode is changed by a saved configuration command for this trial.

## Alternatives and consequences

Warm pools offer faster pickup but retain idle volumes/processes. Inbound webhooks violate the no-exposure constraint. An outbound scale-set client is an alternative with different dependencies/protocol and needs its own evaluation; this trial extends existing REST/App tooling. Polling adds startup delay, API usage and eventual-consistency races. Dedicated labels are required; generic self-hosted-only jobs intentionally do not scale targets. Stale snapshots can briefly create unused capacity; startup grace and the next successful scan remove it. Large organizations/pagination limits need workload-specific validation, not an unlimited guarantee.

No PAT, exposed port, Docker restart, host socket mount or privilege change. Short-lived tokens remain host-only. An App permission change was performed manually by the user; Actions-read live verification passed before activation.

## Validation and sources

Policy and actual-controller fixture tests cover zero/queued/busy/API failure/return-to-zero. Configuration rejects invalid modes and aggressive intervals; App tests reject missing Actions permission; GUI tests retain scaling options. See [trial runbook](../runbooks/10-demand-scaling.md) for executed evidence and rollback.

Official sources checked 2026-10-08: [workflow runs](https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10), [current-attempt jobs](https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10), [self-hosted scaling](https://docs.github.com/en/actions/reference/runners/self-hosted-runners). This supersedes fixed warm replenishment in 0013 only for targets explicitly configured demand.

Applying during a real busy workload exposed the previous restart helper's wait for supervisor exit. The supervisor intentionally stays alive until busy jobs finish. The helper now resumes after controller lock release following bounded drain, allowing the same supervisor to reload configuration and preserve busy state. A fixture with held supervisor lock and retained busy slot passed. Controller-lock timeout still leaves explicit resume necessary.

Live refinement: scale up only on a fresh successful queue scan; cached counts can refer to jobs already assigned. Cached-snapshot controller regression passed. At 10:33 UTC zero containers/volumes, active supervision and healthy zero-demand polling were verified; cold-start addon/docs and CI workflows succeeded.
