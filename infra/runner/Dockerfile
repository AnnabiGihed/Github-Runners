ARG CLIENT_IMAGE
ARG RUNNER_IMAGE
FROM ${CLIENT_IMAGE} AS dockercli
FROM ${RUNNER_IMAGE}
USER root
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/
COPY --chmod=755 infra/runner/entrypoint.sh /usr/local/bin/ephemeral-entrypoint
USER runner
WORKDIR /home/runner
ENV DOCKER_HOST=unix:///job-socket/docker.sock
ENTRYPOINT ["/usr/local/bin/ephemeral-entrypoint"]
