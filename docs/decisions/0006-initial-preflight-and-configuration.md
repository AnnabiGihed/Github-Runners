# 0006: Initial preflight and target example

- Date: 2026-10-08
- Status: accepted preflight; target schema and capacity proposed
- Related requirements: easy reuse, no exposed ports, organized tooling

## Context and decision

Begin implementation with a saved read-only PowerShell preflight for the Windows host and a JSON target example. Use built-in PowerShell JSON handling for this initial host check to avoid installing a dependency. Check the effective Docker endpoint before contacting its engine and accept only local named-pipe/Unix sockets. Reject non-Linux engine mode for the proposed Linux baseline.

The example separates repository and organization scope and references protected private-key files. App/installation IDs are null until supplied. One runner per target is a capacity proposal awaiting user input, not an approved allocation. The JSON format is an initial proposal; no controller consumes it yet.

## Alternatives and rationale

Ad-hoc unsaved setup commands would undermine reproducibility. An immediate deployment would assume engine readiness, workload compatibility, permissions, and resource limits without evidence. Local Docker management avoids exposing the daemon or opening inbound ports. JSON avoids adding a YAML parser for simple host/configuration tooling.

## Consequences and limitations

The preflight reports engine allocation, not spare capacity or a complete host-security assessment. It does not collect raw endpoints, usernames, or container identities in its output. Shared App versus separate App selection remains pending. Organization repository authorization, workflow compatibility, deployment design, and schema validation remain outstanding.

## Validation

Shell execution failed before the process started with `helper_unknown_error: setup refresh had errors`. The new PowerShell script has not been parsed or executed, and the configuration example has not been machine-validated. No host changes, GitHub API calls, commit, or push occurred.
