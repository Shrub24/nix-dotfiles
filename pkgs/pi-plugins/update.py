#!/usr/bin/env python3
"""Refresh the npm and branch pins owned by the compiled plugin source set."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile
from urllib.parse import quote
from urllib.request import Request, urlopen


NPM = re.compile(r'(npmTarball "(?P<name>[^"]+)" \{\s*version = ")(?P<version>[^"]+)(";\s*hash = ")(?P<hash>[^"]+)(";\s*\})')
BRANCHES = {
    "omniroute": ("omnirouteSrc", "Shrub24/OmniRoute", "deploy/edge"),
    "fork-in": ("forkInSrc", "onsails/fork-in", "master"),
}


def npm_url(name, version):
    return f"https://registry.npmjs.org/{name}/-/{name.rsplit('/', 1)[-1]}-{version}.tgz"


def prefetch(name, version, expected=None):
    """The tarball's SRI hash and store path, checked against a recorded pin when given."""
    meta = json.loads(
        subprocess.check_output(
            ["nix", "store", "prefetch-file", "--hash-type", "sha512", "--json", npm_url(name, version)],
            text=True,
        )
    )
    if expected is not None and meta["hash"] != expected:
        raise ValueError(f"{name} {version}: tarball integrity differs from the recorded pin")
    return meta["hash"], meta["storePath"]


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


def resolve_manifest(name, store_path, workdir):
    """The plugin's package.json, as a file: extracted from its npm tarball."""
    with tarfile.open(store_path) as archive:
        extracted = archive.extractfile("package/package.json")
        if extracted is None:
            raise ValueError(f"{name}: the tarball has no package/package.json")
        manifest = extracted.read().decode()
    target = Path(workdir) / f"{name.replace('/', '_')}.json"
    target.write_text(manifest)
    return target


def lock_member_manifests(sources, tarballs, extensions_root, workdir):
    """NAME=MANIFEST for every lock member, from the list Nix passed in."""
    if not sources:
        raise ValueError("PI_LOCK_MEMBERS is not set, so the lock members are unknown")

    specs = []
    for source in sources.split():
        member, sep, where = source.partition("=")
        kind, _, value = where.partition(":")
        if not sep or not ((kind == "npm" and value) or (kind == "manifest" and value)):
            raise ValueError(f"{source} is not MEMBER=npm:PACKAGE or MEMBER=manifest:PATH")
        if kind == "manifest":
            specs.append(f"{member}={extensions_root}/{value}")
            continue
        store_path = tarballs.get(value)
        if store_path is None:
            raise ValueError(f"{member}: no prefetched tarball for {value}")
        specs.append(f"{member}={resolve_manifest(member, store_path, workdir)}")
    return specs


def lock_only():
    """Regenerate the lock from the pins already in the recipe file, pinning nothing."""
    text = Path("pkgs/pi-plugins/default.nix").read_text()
    tarballs = {}
    for match in NPM.finditer(text):
        _, store_path = prefetch(match["name"], match["version"], match["hash"])
        tarballs[match["name"]] = store_path
    write_lock(tarballs)


def write_lock(tarballs):
    """Combine the lock members' manifests into the plugin lock."""
    extensions_root = os.environ.get("PI_EXTENSIONS_ROOT")
    if not extensions_root:
        raise ValueError("PI_EXTENSIONS_ROOT is not set, so the directory-shaped members cannot be read")
    with tempfile.TemporaryDirectory() as workdir:
        specs = lock_member_manifests(
            os.environ.get("PI_LOCK_MEMBERS", ""), tarballs, extensions_root, workdir
        )
        subprocess.run(
            ["update-plugin-lock", str(Path("pkgs/pi-plugins/plugins.lock.json")), *specs], check=True
        )


def main():
    if "--lock-only" in sys.argv[1:]:
        lock_only()
        return
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
        expected = package["dist"]["integrity"]
        if package["dist"]["tarball"] != npm_url(name, version):
            raise ValueError(f"{name}: unexpected tarball URL")
        digest, store_path = prefetch(name, version, expected)
        resolved[name] = (version, digest, store_path)

    def npm_pin(match):
        version, digest, _ = resolved[match["name"]]
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

    # The lock is derived from the pins, so it is regenerated here rather than in
    # a second command: an unregenerated lock stages versions the plugins no
    # longer declare, which the compile refuses.
    write_lock({name: entry[2] for name, entry in resolved.items()})


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"pi-plugins-update: {error}", file=sys.stderr)
        sys.exit(1)
