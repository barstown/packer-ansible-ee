#!/usr/bin/env python3
"""Print the mise-pinned Packer version and linux-x64 checksum as KEY=value lines.

The output is valid for both `eval` in a shell and `>> "$GITHUB_OUTPUT"`.
"""

import sys
import tomllib
from pathlib import Path

TOOL = "aqua:hashicorp/packer"
PLATFORM = "platforms.linux-x64"
MISE_DIR = Path(__file__).resolve().parent.parent / ".mise"

config = tomllib.loads((MISE_DIR / "config.toml").read_text())
lock = tomllib.loads((MISE_DIR / "mise.lock").read_text())

pinned = config["tools"][TOOL]
locked = lock["tools"][TOOL][0]

if locked["version"] != pinned:
    sys.exit(
        f"{TOOL} is {pinned} in .mise/config.toml but {locked['version']} in "
        ".mise/mise.lock; run `mise lock` and commit the result."
    )

algorithm, _, digest = locked[PLATFORM]["checksum"].partition(":")
if algorithm != "sha256":
    sys.exit(f"Expected a sha256 checksum for {TOOL}, got {algorithm}.")

print(f"PACKER_VERSION={pinned}")
print(f"PACKER_SHA256={digest}")
