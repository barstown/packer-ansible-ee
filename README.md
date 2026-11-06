# Packer AWX execution environment

An Ansible execution environment (EE) for building VM templates with Packer
from AWX. It can provision RHEL 8, 9 and 10 guests.

| Component       | Version                         | Pinned in                                  |
| --------------- | ------------------------------- | ------------------------------------------ |
| Base image      | Rocky Linux 10 minimal (digest) | [execution-environment.yml]                |
| Python          | 3.12 (EL10 platform Python)     | [execution-environment.yml]                |
| Packer          | see `.mise/config.toml`         | [.mise/config.toml] + [.mise/mise.lock]    |
| ansible-core    | 2.16.x                          | [pyproject.toml] + [uv.lock] (`ee` group)  |
| ansible-runner  | 2.4.x                           | [pyproject.toml] + [uv.lock] (`ee` group)  |
| Collections     | ansible.posix, community.general | [requirements.yml]                        |

ansible-core is held at 2.16 because 2.17 dropped Python 3.6, which is RHEL 8's
platform Python on the guests Packer provisions. ansible-core 2.16 supports
controller Python up to 3.12, which is also EL10's platform Python. The
`rhel8-compat` rules in [.renovaterc.json5](.renovaterc.json5) stop Renovate from
moving past either, or past community.general 11.x.

[execution-environment.yml]: execution-environment.yml
[.mise/config.toml]: .mise/config.toml
[.mise/mise.lock]: .mise/mise.lock
[pyproject.toml]: pyproject.toml
[uv.lock]: uv.lock
[requirements.yml]: requirements.yml

## How versions flow

Every version is pinned in exactly one place:

- **Packer**: the `aqua:hashicorp/packer` entry in `.mise/config.toml`.
  `scripts/packer-build-args.py` reads that version and its linux-x64 sha256
  from `.mise/mise.lock`. Those are passed as the `PACKER_VERSION` and
  `PACKER_SHA256` build args, and the image build verifies the download
  against the checksum. CI uses the same version in the image tag and the
  `io.packer.version` label.
- **Python packages**: the `ee` dependency group in `pyproject.toml`, locked by
  `uv.lock`. `mise run requirements` exports the locked closure to
  `requirements.txt` (generated, not committed). The base build stage installs
  ansible-core and ansible-runner with that file as a pip constraint, so the
  EE definition carries no versions of its own.
- **Tools** (Python, uv, lefthook, actionlint, zizmor): `.mise/config.toml`,
  locked in `.mise/mise.lock`. CI installs them through `jdx/mise-action`.

Renovate keeps all of these up to date, including the base image tag and digest.

## Setup

Install [mise](https://mise.jdx.dev), then:

```bash
mise trust
mise install   # also installs the lefthook git hooks
uv sync
```

When you `cd` into the repository, mise activates the uv virtual environment.
It runs the same ansible-core as the image.

## Tasks

```bash
mise run build [tag]   # build ghcr.io/barstown/packer-ansible-ee:<tag> (default: dev) with podman
mise run test [tag]    # smoke test that image
mise run lint          # ansible-lint, actionlint, zizmor
mise run create        # only generate the build context in ./context
```

Build with `mise run build`, not `ansible-builder build` directly. The plain
command lacks the generated `requirements.txt` and the Packer build args.

### Updating versions

- Packer: change the version in `.mise/config.toml`, then run `mise lock`. The
  pre-commit hook does this for you.
- Python packages: `uv add --group ee 'ansible-runner==X.Y.Z'`, or edit
  `pyproject.toml` and run `uv lock`.
- Collections: edit `requirements.yml`.

## Publishing

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds the image
and smoke tests it on every pull request. It publishes to
`ghcr.io/<owner>/<repo>` on pushes to `main`, on the 1st of each month (05:00
UTC, to pick up OS errata), and on manual dispatch. Published tags:

- `latest`
- `<YY.MM>`: monthly channel
- `<YY.MM.DD>-<PACKER_VERSION>`: e.g. `26.11.05-1.16.2`

Published images carry OCI labels, an `io.packer.version` label, provenance
attestations and an SBOM.

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs the linters on
pull requests.
