# 0004: Standing authorization to commit and push

- Date: 2026-10-08
- Status: accepted
- Related requirements: repository-managed artifacts and recorded choices

## Context and decision

The user stated: "you can always commit and push". Treat this as standing authorization to commit and push project work to the configured repository remote without repeated permission requests. Record this in `AGENTS.md` for future sessions.

## Alternatives and rationale

Requesting approval for each commit or push would conflict with the user's expressed preference. Leaving completed work only in the working tree would not use the granted authorization.

## Consequences and limitations

Review changes for secrets and run available relevant checks before publishing. This authorization does not imply force-pushing, rewriting shared history, or publishing credentials. Prior entries stating that no commit or push was performed remain historical facts.

## Validation

Attempted to inspect project instructions, Git status, configured remotes, and branch on 2026-10-08. The shell execution helper failed before starting with `helper_unknown_error: setup refresh had errors`. No commit or push could be executed, and the remote/branch remain unverified.
