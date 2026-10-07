# 0008: Two concurrent jobs per target

- Date: 2026-10-08
- Status: accepted capacity limit; operational verification pending
- Supersedes: the one-job-per-target capacity in decision 0007

## Context and decision

The user reported an Intel Core i7-13700HX, 48 GB RAM, 8 GB graphics memory, and 1.84 TB storage, then requested two jobs per target. Set `maxRunners` to 2 for both initial targets in the configuration example.

Allow up to two simultaneous jobs for AnnabiGihed/RaidManager and two shared across all authorized Pivot-Softwares repositories: four jobs total for the initial targets. Each runner still processes at most one job and is destroyed afterward. Service containers consume additional resources but do not count as independent workflow job slots.

## Alternatives and rationale

The prior two-job total was a conservative initial limit. The user explicitly increased it. Assigning two jobs per organization repository would exceed the requested target-level limit. Do not automatically allocate unlimited capacity when adding targets; choose a host-wide budget during controller implementation.

## Consequences and limitations

Hardware values are user-supplied, not independently measured. Four jobs are a configured upper limit, not proof that every combination of Docker builds and service containers fits. Verify Docker allocation, available disk, and peak memory/CPU usage with representative jobs. Resource limits and the host-wide budget remain pending. GPU access is not implied.

## Validation

Updated the saved configuration example and requirements. Shell execution failed before process startup with `helper_unknown_error: setup refresh had errors`; JSON parsing, Git checks, commit, push, and runtime concurrency tests could not run. No deployed capacity has changed because no runners are deployed.
