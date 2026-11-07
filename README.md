# Packer AWX execution environment

An Ansible execution environment (EE) for building VM templates with Packer
from AWX. It can provision RHEL 8, 9 and 10 and Debian guests.

```text
ghcr.io/barstown/packer-ansible-ee:1
```

## Quick start

In AWX, go to **Administration → Execution Environments → Add**:

| Field | Value                                  |
| ----- | -------------------------------------- |
| Image | `ghcr.io/barstown/packer-ansible-ee:1` |
| Pull  | Always pull container before running   |

The image is public, so no registry credential is needed. Then pick this
execution environment on the job templates that run Packer.

`:1` moves to each new 1.x release. "Always pull" makes AWX use the newest
one; with the default policy, a node keeps whichever copy it pulled first.

## Using Packer

Packer is installed at **`/usr/bin/packer`** and is on `PATH`. Jobs run as a
non-root user (UID 1000).

Packer plugins aren't bundled, so run `packer init` before building. It
downloads the plugins your template's `required_plugins` block names into the
job's home directory, which starts empty on every job.

```yaml
- name: Install the template's Packer plugins
  ansible.builtin.command:
    cmd: /usr/bin/packer init .
    chdir: "{{ playbook_dir }}/packer/rhel9"
  changed_when: false

- name: Build the RHEL 9 template
  ansible.builtin.command:
    cmd: /usr/bin/packer build -var-file=vsphere.pkrvars.hcl .
    chdir: "{{ playbook_dir }}/packer/rhel9"
```

To try it outside AWX:

```bash
podman run --rm -it -v "$PWD:/work:Z" -w /work ghcr.io/barstown/packer-ansible-ee:1 packer version
```

## What's inside

- Packer (the version is in each release's notes)
- ansible-core 2.16 and ansible-runner on Python 3.12
- The `ansible.posix` and `community.general` (11.x) collections
- ssh, sshpass, rsync, git and xorriso
- Rocky Linux 10 minimal as the base

ansible-core stays on 2.16 so that it can still manage RHEL 8 guests, whose
Python 3.6 isn't supported by later versions.

## Choosing a tag

Use the major tag, `:1`. It gets every new feature, fix and OS security
update, and never a breaking change: those go out as `:2`. To stay on one
exact image, use a full version such as `:1.4.2`; it never changes. Each
[release](https://github.com/barstown/packer-ansible-ee/releases) lists what
changed and which Packer version it ships, and
[CHANGELOG.md](CHANGELOG.md) has the full history.

All the tags are described in
[CONTRIBUTING.md](CONTRIBUTING.md#published-images).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, the commit conventions
and how releases are made.

## License

[Apache 2.0](LICENSE.md)
