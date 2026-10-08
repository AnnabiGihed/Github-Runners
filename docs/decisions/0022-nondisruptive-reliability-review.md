# 0022 — Non-disruptive reliability review

Date: 2026-10-08. Status: accepted; recovery findings remain open.

## Context and decision

The user requires optimization/security to preserve availability. Keep Docker and the production pool running during review; use source inspection, disposable regression fixtures and read-only live checks. Do not claim 100% uptime or deploy untested recovery architecture.

Supersede decision 0021's command-based cache ownership inference. Shared builder cache needs reviewed exact IDs plus existing usage/sharing/mutability guards. Keep project-label/age image cleanup. Desktop status must distinguish supervision from GitHub availability. Compare captured CLI version without a second racing exec.

## Alternatives and consequences

Global pruning and package-command heuristics risk unrelated reusable data and are rejected. Production fault injection offers stronger evidence but interrupts availability; use separate validation probes/maintenance instead. Conservative cleanup may reclaim less disk. Broad restart/diagnostic/stream changes require recovery tests before deployment.

## Validation

Seven fixture suites and live four-slot checks passed; see [review](../reviews/2026-10-08-reliability.md). Long-drain restart, oversized diagnostic teardown and unbounded attached output remain open, explicitly documented follow-up work.
