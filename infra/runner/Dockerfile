ARG CLIENT_IMAGE
ARG RUNNER_IMAGE
FROM ${CLIENT_IMAGE} AS dockercli
FROM ${RUNNER_IMAGE}
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential ca-certificates curl git gzip jq openssh-client unzip \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /etc/apt/keyrings \
    && chmod 755 /etc/apt/keyrings \
    && curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
       https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo '6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b  /etc/apt/keyrings/githubcli-archive-keyring.gpg' | sha256sum --check \
    && chmod 644 /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && printf 'Package: gh\nPin: origin cli.github.com\nPin-Priority: 1001\n' > /etc/apt/preferences.d/github-cli \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' gh)" ge 2.101.0 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/
COPY --chmod=755 infra/runner/entrypoint.sh /usr/local/bin/ephemeral-entrypoint
USER runner
WORKDIR /home/runner
ENV DOCKER_HOST=unix:///job-socket/docker.sock
ENV DOTNET_INSTALL_DIR=/job-work/.dotnet
ENTRYPOINT ["/usr/local/bin/ephemeral-entrypoint"]
