# 0002: GitHub App authentication and outbound-only connectivity

- Date: 2026-10-07
- Status: accepted baseline; replenishment/controller selection pending
- Related requirements: no PAT, no exposed ports, personal and organization support

## Context and decision

Use GitHub App installation authentication for runner API calls. Keep separate personal repository and organization installation targets. Grant repository Administration write for repository bootstrap and organization Self-hosted runners write for organization bootstrap, with additional permissions only when a documented endpoint needs them.

Keep App key custody in trusted provisioning, outside job containers. Disable incoming webhooks for this baseline. Runners connect outbound over HTTPS; do not publish ports or expose a Docker TCP API.

## Alternatives and rationale

PATs violate the requirement. Manual registration tokens can bootstrap a runner but do not provide renewable App-based automation. Workflow `GITHUB_TOKEN` is not the selected runner-management credential. Incoming webhook autoscaling conflicts with no port exposure. Compare a small replenished pool, job polling, and supported outbound scale-set clients later using actual workflow/resource needs; none is implemented or selected yet. Kubernetes/ARC would add platform complexity without an established need.

## Consequences and limitations

An App private key remains a long-lived secret. Installation tokens expire after one hour and must be renewed; runner registration tokens and JIT payloads remain sensitive. Installation approval and exact permissions must be checked against real targets. Organization runners cannot serve unrelated personal repositories. GitHub Free organization features must be checked individually; do not assume paid runner-group controls. Do not promise billing or storage costs from the plan label alone.

## Sources and validation

See [official sources](../references/official-sources.md): runner reference, runner REST endpoints, installation tokens, and billing. No live App or runner API calls were made. Outbound-only authentication/registration has not been tested on this PC.
