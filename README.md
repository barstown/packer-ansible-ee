# Packer AWX EE

My Execution Environment for building Packer templates in AWX.

## Local setup requirements

Install `pip` (and optionally `pipx`) using your package manager.

```bash
$ sudo dnf install python3-pip pipx
```

Then, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

Although the official documentation suggests installing with `pip`, I prefer to
use `pipx` so that each package gets it's own isolated environment.

If ansible-builder is installed using pipx, you may need to also inject setuptools into the venv.

```bash
$ pipx install ansible-builder
$ pipx inject ansible-builder setuptools
```

## Build the image locally

Then run the following command from the root of this repo:

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

## Other repo dependencies

This repo also makes use of the various extensions, as documented in the
[extensions.json](.vscode/extensions.json) file. These are optional, but
recommended in most cases. Some extension configuration files exist in this
repository that are not strictly necessary for ansible-builder functionality.
