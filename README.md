# Packer AWX execution environment

An Ansible execution environment for building Packer templates using AWX.

## Local setup requirements

Install `pip` (and optionally `pipx`) using your package manager.

```bash
$ sudo dnf install python3-pip pipx
```

Then, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

Although the official documentation suggests installing with `pip`, using `pipx` ensures each package gets it's own virtual environment.

If installing ansible-builder using pipx, you may need to also inject setuptools into the virtual environment.

```bash
$ pipx install ansible-builder
$ pipx inject ansible-builder setuptools
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

## Other repository dependencies

This repository also makes use of various extensions, as documented in the
[extensions.json](.vscode/extensions.json) file. These are optional, but
recommended usually. Some extension configuration files exist in this
repository that aren't necessary for ansible-builder functionality.
