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
