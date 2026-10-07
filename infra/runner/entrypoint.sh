#!/bin/bash
set -euo pipefail
# Bootstrap arrives on stdin, never in Docker environment metadata or an image layer.
IFS= read -r bootstrap
token=$(printf '%s' "$bootstrap" | jq -er '.token')
url=$(printf '%s' "$bootstrap" | jq -er '.url')
name=$(printf '%s' "$bootstrap" | jq -er '.name')
labels=$(printf '%s' "$bootstrap" | jq -er '.labels | join(",")')
unset bootstrap
for i in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then break; fi
    sleep 1
done
docker info >/dev/null
./config.sh --unattended --ephemeral --disableupdate --url "$url" --token "$token" --name "$name" --labels "$labels" --work /job-work >/dev/null 2>&1
unset token
exec ./run.sh
