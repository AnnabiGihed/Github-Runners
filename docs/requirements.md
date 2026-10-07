# Requirements

Recorded: 2026-10-07, Europe/Paris.

## User requirements

1. Host ephemeral GitHub Actions runners on this PC in Docker.
2. Use no personal access tokens.
3. Expose no ports: no published Docker ports, inbound firewall/router changes, tunnels, webhook listeners, or remote Docker TCP listeners.
4. Support personal GitHub Pro repository workloads and GitHub Free organization workloads.
5. Keep all documentation in organized `docs/` files, and all authored scripts/YAML/deployment assets in organized repository paths.
6. Record every material decision and choice.
7. First create the skills needed to carry out this project cleanly.
8. Make setup reusable in easy, documented steps for additional personal repositories and organizations. Adding a target must use configuration rather than edits to controller code or runner images.

## Initial targets

Supplied by the user on 2026-10-08:

- Personal repository: [AnnabiGihed/RaidManager](https://github.com/AnnabiGihed/RaidManager), repository registration scope.
- Organization: [Pivot-Softwares](https://github.com/Pivot-Softwares), organization registration scope. The selected organization repositories still need to be specified.
- Organization repository policy requested: shared organization runner capacity for all repositories, subject to actual GitHub access settings. Public repository eligibility and trusted trigger policy still need verification.
- Capacity approved (updated 2026-10-08): two concurrent jobs per target, up to four total across the initial personal and organization targets. The organization limit is shared across its repositories, not allocated per repository. Service containers are supporting resources, not additional job slots.
- Workloads requested: Linux jobs, Docker builds, container actions, and service containers. The user subsequently clarified on 2026-10-08 that Windows jobs are not needed; Windows execution is out of scope.

These are requested targets, not evidence of verified access, visibility, App installations, or runner registration. Keep target names in deployment configuration, never hardcoded into reusable tooling.

Progress on 2026-10-08: personal App access and two temporary online ephemeral registrations have been verified; probe environments were removed afterward. RaidManager is currently public, which the user says is temporary during configuration. The intended final routing is all RaidManager workloads on these runners. Real workflow execution, production trigger policy, and organization setup remain pending.

## Interpretation

Ephemeral means at most one job per runner plus destruction of its container and writable job state. A permanently running trusted controller is compatible with disposable job runners. No PAT does not mean no credentials: a GitHub App private key and short-lived GitHub-issued credentials are needed.

No exposed ports permits outbound HTTPS and ordinary Docker internal networking; it does not automatically prevent jobs accessing the LAN. Job trust and isolation need a separate design.

## Inputs needed before deployment

- Target visibility and trusted trigger policy for organization-wide access; initial personal repository and organization names are recorded above.
- Who can create/install GitHub Apps and manage runners at each scope.
- Workflow needs: OS, architecture, toolchains, Docker builds/container actions/services, and access to private packages.
- Trusted trigger policy, particularly public repositories and fork pull requests.
- Docker CPU/memory/storage budget, PC availability/sleep behavior, and tolerated queue latency. Concurrency is approved at two jobs per target. User-reported hardware: Intel Core i7-13700HX, 48 GB RAM, 8 GB graphics memory, and 1.84 TB storage; available resources and Docker allocation remain unverified.
- Actual Docker server/backend state. The executable is present; engine readiness has not been checked.

These inputs do not block creation of the project skills. Do not invent values to deploy runners.
