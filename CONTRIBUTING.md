# Contributing

How to work on this repo: local setup, commit conventions, CI and releases. To
use the image, see the [README](README.md).

## Setup

Install [mise](https://mise.jdx.dev), then from the repo root:

```bash
mise trust
mise install   # also installs the lefthook git hooks
uv sync
```

When you `cd` into the repository, mise activates the uv virtual environment.
It runs the same ansible-core as the image.

The pre-commit hook runs on the files you stage: it formats and locks the mise
config, checks `uv.lock` is current, and runs ansible-lint, actionlint and
zizmor.

| Command             | Does                                                                           |
| ------------------- | ------------------------------------------------------------------------------ |
| `mise run build [tag]` | Build `ghcr.io/barstown/packer-ansible-ee:<tag>` (default `dev`) with podman |
| `mise run test [tag]`  | Smoke test that image                                                       |
| `mise run lint`        | ansible-lint, actionlint and zizmor, as in CI                               |
| `mise run create`      | Only generate the build context in `./context`                              |

Build with `mise run build`, not `ansible-builder build` directly. The plain
command lacks the generated `requirements.txt` and the Packer build args.

## Making a change

1. Branch from `main` and make your change.
2. Open a pull request with a [Conventional Commits](https://www.conventionalcommits.org)
   title (see [Commit messages](#commit-messages)).
3. Wait for the required `CI Success` and `Build, test and publish` checks. The
   build check builds the image and runs the smoke test, but never publishes.
4. **Squash merge.** It's the only merge method allowed on `main`.

**The PR title becomes the commit message on `main`**, and that commit message
decides the changelog entry and the version bump. The repo's squash setting
uses the PR title as the commit title with an empty body, so individual branch
commits don't matter. Fix the PR title, not the commits. No CI check enforces
the format, so check it before merging.

Merging doesn't publish anything. The change waits in the release pull request
until that is merged (see [Releasing](#releasing)).

## Commit messages

```text
<type>(<optional scope>): <description>
```

| Type                                                         | Use for                                                       | Release |
| ------------------------------------------------------------ | ------------------------------------------------------------- | ------- |
| `fix`                                                        | something in the image or build that behaved wrongly          | patch   |
| `feat`                                                       | new or newer software in the image that shouldn't break users | minor   |
| `feat!` / `fix!`                                             | a change that may break playbooks or AWX jobs                 | major   |
| `chore`, `ci`, `docs`, `refactor`, `build`, `test`, `deps`, … | everything else                                              | patch   |

Examples:

```text
fix: install xorriso from AppStream
feat: add the community.vmware collection
feat(packer): update Packer (1.16.2 ➔ 1.17.0)
feat!: drop RHEL 8 support and move to ansible-core 2.17
ci: run the smoke test against both runtimes
```

A `!` (or a `BREAKING CHANGE:` footer) always means a major release, whatever
the type. Ask whether anyone following the major tag (`:1`) could have a job
break; if so, it's breaking. A title that isn't a conventional commit is left
out of the changelog and doesn't count toward a release.

### Renovate

Renovate's commit messages follow the same rules, set in
[`.renovaterc.json5`](.renovaterc.json5):

| Update                                     | Commit                         | Release |
| ------------------------------------------ | ------------------------------ | ------- |
| Major of anything in the image             | `feat(<scope>)!:`              | major   |
| Minor, or minor of a `0.x` package         | `feat(<scope>):` / `feat(<scope>)!:` | minor / major |
| Patch, digest, lock file maintenance       | `fix(<scope>):` / `chore(deps):` | patch |
| GitHub Actions                             | `ci(github-action):`           | patch   |
| mise tools other than Packer               | `chore(mise):`                 | patch   |

Packer updates use the `packer` scope so they stand out in the changelog, and
base image updates use `container`. Majors of tooling that never ships in the
image (Actions, renovate-config, mise tools other than Packer, and
ansible-lint) have the `!` removed so they don't cut a major release. They
still land on `major-` branches. If you add a tool that doesn't ship in the
image, add it to the last two rules in `.renovaterc.json5`.

## Changing versions

Every version is pinned in exactly one place, and Renovate keeps them all up
to date:

| Component                     | Pinned in                                                               |
| ----------------------------- | ----------------------------------------------------------------------- |
| Base image (tag and digest)   | [`execution-environment.yml`](execution-environment.yml)                |
| Packer                        | [`.mise/config.toml`](.mise/config.toml) + [`.mise/mise.lock`](.mise/mise.lock) |
| ansible-core, ansible-runner  | `ee` group in [`pyproject.toml`](pyproject.toml) + [`uv.lock`](uv.lock) |
| Collections                   | [`requirements.yml`](requirements.yml)                                  |
| Tools (Python, uv, linters)   | [`.mise/config.toml`](.mise/config.toml) + [`.mise/mise.lock`](.mise/mise.lock) |

- **Packer**: change the version in `.mise/config.toml`, then run `mise lock`
  (the pre-commit hook does this for you). `scripts/packer-build-args.py`
  reads the version and its linux-x64 sha256 from the lockfile. Those are
  passed as the `PACKER_VERSION` and `PACKER_SHA256` build args, and the image
  build verifies the download against the checksum. CI puts the same version
  in the `io.packer.version` label and the release notes.
- **Python packages**: `uv add --group ee 'ansible-runner==X.Y.Z'`, or edit
  `pyproject.toml` and run `uv lock`. `mise run requirements` exports the
  locked closure to `requirements.txt` (generated, not committed). The base
  build stage installs ansible-core and ansible-runner with that file as a pip
  constraint, so the EE definition carries no versions of its own. The `dev`
  group is local and CI tooling only and is never installed into the image.
- **Collections**: edit `requirements.yml`.

### RHEL 8 holds

ansible-core is held at 2.16 because 2.17 dropped Python 3.6, RHEL 8's platform
Python on the guests Packer provisions. ansible-core 2.16 supports controller
Python up to 3.12, which is also EL10's platform Python. The `rhel8-compat`
rules in `.renovaterc.json5` stop Renovate from moving past either, or past
community.general 11.x. Once no RHEL 8 templates are built, delete those rules
rather than relaxing them, and release the result as a major.

## Automation

| Workflow                                                   | Runs on                                          | Does                                                    |
| ---------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------- |
| [CI](.github/workflows/ci.yml)                             | Pull requests and `main`                         | Lints; reports `CI Success`                             |
| [Release Please](.github/workflows/release-please.yml)     | Pushes to `main`                                 | Maintains the release pull request and creates releases |
| [Build EE image](.github/workflows/build.yml)              | Pull requests, releases, monthly, manual         | Builds and smoke tests; publishes releases              |

- `CI Success` and `Build, test and publish` are the required checks. Both
  pass on release pull requests, where the lint and build jobs are skipped
  because they only change `CHANGELOG.md` and the manifest.
- Release Please authenticates as the `release-bot` GitHub App, using the
  `RELEASE_BOT_CLIENT_ID` and `RELEASE_BOT_PRIVATE_KEY` repository secrets. A
  release made with `GITHUB_TOKEN` wouldn't trigger the build workflow, and a
  pull request opened with it wouldn't run the required checks. The app needs
  Contents, Pull requests and Issues set to read and write, and is installed
  on this repo only.
- Publishing uses `GITHUB_TOKEN` with `packages: write`.

## Releasing

Releases are automated by [release-please](https://github.com/googleapis/release-please):

1. Every merge to `main` opens or updates a `chore(release): X.Y.Z` pull
   request. It bumps the version from the commits merged since the last
   release and writes `CHANGELOG.md`.
2. **Merge that pull request to release.** Merging it creates the `X.Y.Z` tag
   and GitHub release.
3. The release triggers the build workflow. It builds the tag's source without
   the layer cache, smoke tests it, and pushes `X.Y.Z`, `X.Y`, `X` and
   `latest` with provenance and an SBOM. It then appends the Packer version and
   pull command to the release notes.

Several changes can go out together by leaving the release pull request open.
To force a specific version, add a `Release-As: X.Y.Z` footer to a commit
message (in the squash merge dialog's description field).

### Monthly rebuilds

On the 1st of each month at 05:00 UTC, the build workflow rebuilds the latest
release from its tag, not from `main`, and pushes it under the same tags. The
base image is pinned by digest, so it's the `microdnf upgrade` step in the
build that picks up the errata. Unreleased changes on `main` are never
included.

Because the workflow file comes from `main` but the source comes from the tag,
cut a release soon after changing how the image is built, so the two don't
drift apart.

To rebuild by hand:

```bash
gh workflow run build.yml                 # the latest release
gh workflow run build.yml -f tag=1.4.2    # a specific release
```

Rebuilding an older release only updates its own `X.Y.Z` tag; the floating
`X.Y`, `X` and `latest` tags stay on the latest release.

## Published images

Images are published to `ghcr.io/barstown/packer-ansible-ee`:

| Tag                       | Example  | Follows                                     |
| ------------------------- | -------- | ------------------------------------------- |
| `<MAJOR>`                 | `1`      | the newest release with no breaking changes |
| `<MAJOR>.<MINOR>`         | `1.4`    | patch releases of that minor                |
| `<MAJOR>.<MINOR>.<PATCH>` | `1.4.2`  | one release, rebuilt monthly for OS errata  |
| `latest`                  | `latest` | the newest release, including breaking ones |

What a bump means for someone running jobs:

- **Major**: something they rely on may break. For example, a new ansible-core
  or base image major, or dropping support for a guest OS.
- **Minor**: new or newer software that shouldn't break playbooks. For
  example, a new Packer minor or a new collection.
- **Patch**: fixes, patch updates, and changes to the build that don't affect
  what's in the image.

Every tag moves when its release is rebuilt, so the only immutable reference is
a digest (`ghcr.io/barstown/packer-ansible-ee:1@sha256:…`). Consumers who use
Renovate get this with `docker:pinDigests`. Only the newest release is rebuilt
monthly: an older `1.4.2` stops getting OS errata once `1.4.3` or `1.5.0` is
out.

Each image carries OCI labels, including `org.opencontainers.image.version`
(the release) and `io.packer.version`, plus build provenance and an SBOM:

```bash
podman image inspect ghcr.io/barstown/packer-ansible-ee:1 \
  --format '{{ index .Labels "org.opencontainers.image.version" }} packer {{ index .Labels "io.packer.version" }}'
docker buildx imagetools inspect ghcr.io/barstown/packer-ansible-ee:1 --format '{{ json .Provenance }}'
docker buildx imagetools inspect ghcr.io/barstown/packer-ansible-ee:1 --format '{{ json .SBOM }}'
```
