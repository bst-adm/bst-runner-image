FROM golang:1.26.8-bookworm@sha256:dc9ad6c05acc7a88e5b71bde60a5fe3bd4b9f0db209011711b464107438a8107 AS forgejo
WORKDIR /src
RUN git clone --depth 1 --branch v13.2.2 https://code.forgejo.org/forgejo/runner.git . \
    && test "$(git rev-parse HEAD)" = 0e61343d1cb98d2a381d0d18f34aea408e66e4d2
COPY patches/forgejo-runner-cancellation.patch /tmp/runner-cancellation.patch
RUN git apply --check /tmp/runner-cancellation.patch \
    && git apply /tmp/runner-cancellation.patch \
    && go test ./internal/pkg/report \
    && CGO_ENABLED=0 go build -trimpath -tags 'netgo osusergo' \
       -ldflags '-s -w -X code.forgejo.org/forgejo/runner/v13/internal/pkg/ver.version=v13.2.2-cancellation.1' \
       -o /bin/forgejo-runner .

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
