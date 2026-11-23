# BST Forgejo runner image

A Debian tools image for the Forgejo Runner host executor. It contains Forgejo
Runner, Node.js and npm, Python with venv, Git, Bash, curl, jq, SSH and archive
tools. The default user is UID/GID 65532. Mount a writable workspace at
`/work` and provide writable temporary storage when using a read-only root.

```sh
docker build -t bst-runner-image:test .
docker run --rm bst-runner-image:test --version
```

GitHub-hosted Actions builds and tests Linux amd64. Main builds publish to
`ghcr.io/bst-adm/bst-runner-image:sha-<commit>`; release tags publish under
their version. Pull requests only build and test. The publish job records the
digest and signs a provenance attestation. Deploy by digest and verify with:

```sh
gh attestation verify oci://ghcr.io/bst-adm/bst-runner-image@sha256:<digest> \
  --repo bst-adm/bst-runner-image
```

GitHub may require setting the new package visibility to Public in package
settings for anonymous pulls. This repository builds independently of the
runner pools that consume the image. Base images are pinned; Debian packages
are resolved from the configured distribution repositories at build time.

## Build projects in their Dockerfiles

The host runner includes Docker CLI and Buildx, Node for JavaScript actions,
and Python for small workflow utilities. Project compilers, package
dependencies, and tests belong in the project's Dockerfile. The runner image
contains no Docker daemon. A live workflow needs access to a compatible
BuildKit builder. For a remote builder, configure its TLS files and use:

```sh
docker buildx create --name ci --driver remote \
  --driver-opt "cacert=$BUILDKIT_CA,cert=$BUILDKIT_CERT,key=$BUILDKIT_KEY" \
  "$BUILDKIT_ENDPOINT"
docker buildx inspect ci --bootstrap
```

Use a test stage to preserve the test command's status and reports (JUnit XML,
LCOV or Cobertura). Export them through a scratch stage. Keep the publish step
behind a successful check of the recorded status. The sample Dockerfile shows
the stage layout and also guards the runtime target against failed tests.

```sh
docker buildx build --builder ci --target reports --output type=local,dest=reports .
printf 'Test exit status: %s\n' "$(cat reports/exit-code)" >> "$GITHUB_STEP_SUMMARY"
test "$(cat reports/exit-code)" = 0
```

In the Forgejo workflow, use a reviewed Forgejo-compatible artifact upload
step with `if: always()` to retain reports even after test failure. A coverage
summary can read the exported report. For trusted release builds, authenticate
to the destination registry, then push the runtime target:

```sh
docker buildx build --builder ci --target runtime \
  --cache-from "type=registry,ref=$CACHE_IMAGE" \
  --cache-to "type=registry,ref=$CACHE_IMAGE,mode=max" \
  --tag "$RELEASE_IMAGE" --push .
```

Use a separate cache ref per project and trust boundary. Keep registry
credentials in workflow secrets and pass build-time secrets via BuildKit
secret mounts instead of build arguments. The release push needs write
permission to the output image and cache. Buildx works with a separate
builder, keeping the node Docker socket outside the runner.
