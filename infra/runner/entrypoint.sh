#!/bin/bash
set -euo pipefail
# Bootstrap arrives on stdin, never in Docker environment metadata or an image layer.
IFS= read -r bootstrap
token=$(printf '%s' "$bootstrap" | jq -er '.token')
url=$(printf '%s' "$bootstrap" | jq -er '.url')
name=$(printf '%s' "$bootstrap" | jq -er '.name')
labels=$(printf '%s' "$bootstrap" | jq -er '.labels | join(",")')
extra=()
if [ "$(printf '%s' "$bootstrap" | jq -r '.validation // false')" = true ]; then extra+=(--no-default-labels); fi
unset bootstrap
for i in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then break; fi
    sleep 1
done
docker info >/dev/null
if ! result=$(./config.sh --unattended --ephemeral --disableupdate --url "$url" --token "$token" --name "$name" --labels "$labels" --work /job-work "${extra[@]}" 2>&1); then
    # Registration-phase diagnostics only; redact the supplied bootstrap token.
    printf '%s\n' "${result//$token/[REDACTED]}" >&2
    exit 1
fi
unset token
exec ./run.sh
