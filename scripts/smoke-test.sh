#!/usr/bin/env bash
# Check that a built EE image carries the pinned Packer, Ansible and Python.
# Usage: smoke-test.sh IMAGE
set -euo pipefail

image="${1:?usage: smoke-test.sh IMAGE}"
runtime="${CONTAINER_RUNTIME:-podman}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

eval "$("$repo_root/scripts/packer-build-args.py")"
ansible_core="$(uv export --project "$repo_root" --locked --only-group ee --no-hashes --no-header --no-annotate --no-emit-project | sed -n 's/^ansible-core==//p')"

run() {
    "$runtime" run --rm "$image" "$@"
}

check() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: $name is '$actual', expected '$expected'" >&2
        exit 1
    fi
    echo "ok: $name $actual"
}

check packer "$PACKER_VERSION" "$(run /usr/bin/packer version | awk 'NR == 1 { sub(/^v/, "", $2); print $2 }')"
check ansible-core "$ansible_core" "$(run python3.12 -c 'import ansible.release; print(ansible.release.__version__)')"
check python 3.12 "$(run python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
check user 1000 "$(run id -u)"

run ansible-runner --version >/dev/null
run ansible-galaxy collection list ansible.posix >/dev/null
run ansible-galaxy collection list community.general >/dev/null
for bin in ssh sshpass rsync git xorriso; do
    run sh -c "command -v $bin" >/dev/null || { echo "FAIL: $bin missing" >&2; exit 1; }
done
echo "ok: runtime binaries"
