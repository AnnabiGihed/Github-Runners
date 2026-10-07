ARG CLIENT_IMAGE
ARG RUNNER_IMAGE
FROM ${CLIENT_IMAGE} AS dockercli
FROM ${RUNNER_IMAGE}
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential ca-certificates curl gh git gzip jq openssh-client unzip \
    && rm -rf /var/lib/apt/lists/*
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/
COPY --chmod=755 infra/runner/entrypoint.sh /usr/local/bin/ephemeral-entrypoint
USER runner
WORKDIR /home/runner
ENV DOCKER_HOST=unix:///job-socket/docker.sock
ENV DOTNET_INSTALL_DIR=/job-work/.dotnet
ENTRYPOINT ["/usr/local/bin/ephemeral-entrypoint"]
