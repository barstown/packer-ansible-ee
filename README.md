# Packer AWX EE

My Execution Environment for building Packer templates in AWX.

## Build the image locally

First, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

If ansible-builder is installed using pipx, you may need to also install setuptools into the venv.

```bash
$ pipx inject ansible-builder setuptools
```

Then run the following command from the root of this repo:

```bash
$ ansible-builder build -v3 -t ghcr.io/barstown/packer-ansible-ee # --container-runtime=docker # Is podman by default
```
