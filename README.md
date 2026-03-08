# Packer AWX execution environment

An Ansible execution environment for building Packer templates using AWX.

## Tooling (mise + uv)

This project uses mise to pin Python and uv, and uv to manage Python CLI
packages inside a project-local venv.

First-time setup:

```bash
mise trust
mise install
uv init --bare
```

When you `cd` into the repo, mise will auto-activate the uv venv.

Add or update Python tools and packages:

```bash
uv add ansible-builder==3.1.1 ansible-core==2.20.3 ansible-lint==26.3.0 setuptools>=82.0.0,<83.0.0
uv sync
```

Update tool versions pinned by mise:

```bash
mise install
```

## Build the image locally

Run the following command from the root of this repository to start the build:

```bash
$ ansible-builder build -v3 -t ghcr.io/barstown/packer-ansible-ee # --container-runtime=docker # Is podman by default
```

Optionally re-tag or add new tags to the image

```bash
$ podman image tag ghcr.io/barstown/packer-ansible-ee:latest ghcr.io/barstown/packer-ansible-ee:v2
```

## Push the image to your container registry

```bash
$ podman push ghcr.io/barstown/packer-ansible-ee:latest
```

## GitHub Actions image publishing

The workflow at `.github/workflows/build-ee-image.yml` builds and publishes this
execution environment:

- on demand via `workflow_dispatch`
- monthly on the 1st day of the month (05:00 UTC)

It pushes these tags to `ghcr.io/<owner>/<repo>`:

- `latest`
- `<YYYYMMDD>`
- `packer-<PACKER_VERSION>`
- `<YYYYMMDD>-packer-<PACKER_VERSION>`

The workflow detects the Packer version by running `packer version` in the built
image, then records it in the Actions run summary.

## Other repository dependencies

This repository also makes use of various extensions, as documented in the
[extensions.json](.vscode/extensions.json) file. These are optional, but
recommended usually. Some extension configuration files exist in this repository
that aren't necessary for ansible-builder functionality.
