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

Current capacity update: while the organization is inactive, allocate four jobs to the personal repository within the existing four-job host cap. Redistribute before enabling organization capacity; see decision 0015.

Supplied by the user on 2026-10-08:

- Personal repository: [AnnabiGihed/RaidManager](https://github.com/AnnabiGihed/RaidManager), repository registration scope.
- Organization: [Pivot-Softwares](https://github.com/Pivot-Softwares), organization registration scope. The selected organization repositories still need to be specified.
- Organization repository policy requested: shared organization runner capacity for all repositories, subject to actual GitHub access settings. Public repository eligibility and trusted trigger policy still need verification.
- Capacity approved (updated 2026-10-08): two concurrent jobs per target, up to four total across the initial personal and organization targets. The organization limit is shared across its repositories, not allocated per repository. Service containers are supporting resources, not additional job slots.
- Workloads requested: Linux jobs, Docker builds, container actions, and service containers. The user subsequently clarified on 2026-10-08 that Windows jobs are not needed; Windows execution is out of scope.

These are requested targets, not evidence of verified access, visibility, App installations, or runner registration. Keep target names in deployment configuration, never hardcoded into reusable tooling.

Progress on 2026-10-08: personal App access, four production slots, successful existing workflows, single-job environment replacement, continuous supervised operation and probe recovery have been verified. RaidManager is currently public, which the user says is temporary during configuration. Personal workflows use the local labels; organization setup is deferred. See personal operations validation for exact evidence and unperformed tests.

## Interpretation

Ephemeral means at most one job per runner plus destruction of its container and writable job state. A permanently running trusted controller is compatible with disposable job runners. No PAT does not mean no credentials: a GitHub App private key and short-lived GitHub-issued credentials are needed.

No exposed ports permits outbound HTTPS and ordinary Docker internal networking; it does not automatically prevent jobs accessing the LAN. Job trust and isolation need a separate design.

## Remaining operational boundaries

- Organization visibility, App installation and access policy are deferred.
- Personal operation requires the owning Windows account to be signed in, the PC awake and Docker available. Four slots use the measured eight-CPU/15.62-GiB engine budget; see resource configuration and validation.
- Keep workflow secrets scoped and maintain trusted trigger policy for the temporarily public repository. Privileged job-local Docker remains the accepted trust boundary; no hostile-code or LAN isolation guarantee is made.
- Keep runner/tool images maintained and verify representative future workloads; synthetic four-slot success does not guarantee every build fits.

Do not invent organization installation values or claim unperformed reboot/cancellation/container-action tests.
