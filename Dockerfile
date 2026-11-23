FROM data.forgejo.org/forgejo/runner:13.1.0@sha256:c4af85fd9f0dd03788676a534781a87c71aa2c6a37737143e017eb94d4312952 AS forgejo

FROM docker:29-cli@sha256:34507eb5069d8be82c95dd3b6987d4250fd5fee49b82e2509b7d7a7030740d6d AS docker_cli

FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git jq openssh-client python3 python3-venv unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
COPY --from=forgejo /bin/forgejo-runner /usr/local/bin/forgejo-runner

COPY --from=docker_cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker_cli /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx

RUN groupadd --gid 65532 runner \
    && useradd --uid 65532 --gid 65532 --home-dir /work --no-create-home --shell /bin/bash runner

ENV HOME=/work
WORKDIR /work
USER 65532:65532
ENTRYPOINT ["forgejo-runner"]
