#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" -ne 0
test ! -e /job-work/four-slot-marker
touch /job-work/four-slot-marker
# Hold each process long enough to measure overlapping work, then exercise actual tools.
sleep 20
printf 'int main(void){return 0;}\n' > /job-work/probe.c
gcc /job-work/probe.c -o /job-work/probe
/job-work/probe
printf 'FROM scratch\nLABEL runner.test=four-slots\n' | docker build -t four-slot-build -
docker run --name pg-smoke -d -e POSTGRES_PASSWORD=fixture-only -p 5432:5432 postgres:17-alpine
ready=false
for attempt in $(seq 1 90); do
  if docker exec pg-smoke pg_isready -U postgres; then ready=true; break; fi
  sleep 1
done
test "$ready" = true
docker exec pg-smoke psql -U postgres -v ON_ERROR_STOP=1 -c 'SELECT 1;'
# host here means only this job's nested engine/daemon network namespace.
docker run --rm --network host --entrypoint pg_isready postgres:17-alpine -h 127.0.0.1 -U postgres
docker rm -f pg-smoke
docker run --rm --mount type=bind,src=/home/runner/externals,dst=/runner-externals,readonly --entrypoint /runner-externals/node24/bin/node node:24-bookworm-slim -e 'console.log("bundled-container-runtime-passed")'
echo four-slot-workload-passed
