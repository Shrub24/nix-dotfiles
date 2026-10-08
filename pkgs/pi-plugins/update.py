#!/usr/bin/env python3
"""Refresh the npm and branch pins owned by the compiled plugin source set."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import quote
from urllib.request import Request, urlopen


NPM = re.compile(r'(npmTarball "(?P<name>[^"]+)" \{\s*version = ")(?P<version>[^"]+)(";\s*hash = ")(?P<hash>[^"]+)(";\s*\})')
BRANCHES = {
    "omniroute": ("omnirouteSrc", "Shrub24/OmniRoute", "deploy/edge"),
    "fork-in": ("forkInSrc", "onsails/fork-in", "master"),
}


def fetch(url):
    headers = {"User-Agent": "nix-dotfiles-pi-plugins-update"}
    if url.startswith("https://api.github.com/") and (token := os.environ.get("GITHUB_TOKEN")):
        headers["Authorization"] = f"Bearer {token}"
    with urlopen(Request(url, headers=headers), timeout=60) as response:
        return json.load(response)


def github_hash(repo, revision):
    digest = subprocess.check_output([
        "nix-prefetch-url", "--unpack", f"https://github.com/{repo}/archive/{revision}.tar.gz",
    ], text=True).strip()
    return subprocess.check_output([
        "nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", digest,
    ], text=True).strip()


def main():
    filename = Path("pkgs/pi-plugins/default.nix")
    text = filename.read_text()
    names = {match["name"] for match in NPM.finditer(text)}
    if not names:
        raise ValueError("no npm pins found")
    targets = None
    if target_file := os.environ.get("PI_PLUGINS_UPDATE_TARGETS"):
        targets = json.loads(Path(target_file).read_text())
        if not isinstance(targets, dict) or set(targets) != names | BRANCHES.keys():
            raise ValueError("recorded targets must name every npm and branch pin exactly once")
        if not all(isinstance(value, str) and value for value in targets.values()):
            raise ValueError("each recorded target must be a nonempty string")

    resolved = {}
    for name in sorted(names):
        target = targets[name] if targets else "latest"
        package = fetch(f"https://registry.npmjs.org/{quote(name, safe='')}/{quote(target, safe='')}")
        version = package["version"]
        if targets and version != target:
            raise ValueError(f"{name}: recorded target must be an exact version")
        url = f"https://registry.npmjs.org/{name}/-/{name.rsplit('/', 1)[-1]}-{version}.tgz"
        if package["dist"]["tarball"] != url:
            raise ValueError(f"{name}: unexpected tarball URL")
        expected = package["dist"]["integrity"]
        actual = json.loads(subprocess.check_output([
            "nix", "store", "prefetch-file", "--hash-type", "sha512", "--json", url,
        ], text=True))["hash"]
        if actual != expected:
            raise ValueError(f"{name}: tarball integrity differs from registry metadata")
        resolved[name] = (version, actual)

    def npm_pin(match):
        version, digest = resolved[match["name"]]
        return match[1] + version + match[4] + digest + match[6]

    text = NPM.sub(npm_pin, text)
    for name, (binding, repo, branch) in BRANCHES.items():
        target = targets[name] if targets else branch
        if targets and not re.fullmatch(r"[0-9a-f]{40}", target):
            raise ValueError(f"{name}: recorded target must be a full commit SHA")
        revision = fetch(f"https://api.github.com/repos/{repo}/commits/{quote(target, safe='')}")["sha"]
        if not re.fullmatch(r"[0-9a-f]{40}", revision) or (targets and revision != target):
            raise ValueError(f"{name}: target did not resolve to the requested commit")
        digest = github_hash(repo, revision)
        pattern = rf'({binding} = fetchFromGitHub \{{.*?rev = ")[^"]+(";.*?sha256 = ")[^"]+(";)'
        text, count = re.subn(pattern, lambda match: match[1] + revision + match[2] + digest + match[3], text, flags=re.DOTALL)
        if count != 1:
            raise ValueError(f"{name}: expected one checkout pin, found {count}")
        print(f"pi-plugins-update: {name} -> {revision}", flush=True)
    filename.write_text(text)
    print(f"pi-plugins-update: refreshed {len(names)} npm pins", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"pi-plugins-update: {error}", file=sys.stderr)
        sys.exit(1)
