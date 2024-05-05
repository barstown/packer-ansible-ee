# Custom AWX EE

My default Execution Environment for AWX, based on 

## Build the image locally

First, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

Then run the following command from the root of this repo:

```bash
$ ansible-builder build -v3 -t github.com/barstown/custom-ansible-ee # --container-runtime=docker # Is podman by default
```

If ansible-builder is installed using pipx, you may need to also install setuptools into the venv.

```bash
$ pipx inject ansible-builder setuptools
```
