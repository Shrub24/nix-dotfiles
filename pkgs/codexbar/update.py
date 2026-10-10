#!/usr/bin/env python3
"""Update CodexBar to a settled release carrying the Linux x86_64 CLI archive."""

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from urllib.request import Request, urlopen

ASSET = "CodexBarCLI-v{version}-linux-x86_64.tar.gz"
SETTLING = timedelta(hours=float(os.environ.get("CODEXBAR_UPDATE_SETTLING_HOURS", "24")))
STABLE = re.compile(r"v[0-9]+\.[0-9]+\.[0-9]+(-cc)?")


def releases():
    url = "https://api.github.com/repos/Shrub24/CodexBar/releases?per_page=100"
    found = []
    while url:
        request = Request(url, headers={"User-Agent": "nix-dotfiles-codexbar-update"})
        with urlopen(request, timeout=60) as response:
            found.extend(json.load(response))
            link = re.search(r'<([^>]+)>;\s*rel="next"', response.headers.get("Link", ""))
            url = link[1] if link else None
    return found


def key(tag):
    return tuple(int(part) for part in re.match(r"v([0-9.]+)", tag)[1].split("."))


def has_asset(release):
    version = release["tag_name"][1:]
    return any(asset["name"] == ASSET.format(version=version) for asset in release["assets"])


def settled(release, now):
    if not release["published_at"]:
        return False
    published = datetime.fromisoformat(release["published_at"].replace("Z", "+00:00"))
    return now - published >= SETTLING


def main():
    target = os.environ.get("CODEXBAR_UPDATE_VERSION", "stable")
    if target != "stable" and not STABLE.fullmatch(target):
        raise ValueError(f"expected stable or an exact stable vX.Y.Z tag, got: {target}")

    now = datetime.now(timezone.utc)
    found = {
        release["tag_name"]: release
        for release in releases()
        if STABLE.fullmatch(release["tag_name"]) and has_asset(release)
    }

    if target == "stable":
        eligible = [tag for tag, release in found.items() if settled(release, now)]
        if not eligible:
            raise ValueError(f"no settled release carries {ASSET.format(version='X.Y.Z')}")
        tag = max(eligible, key=key)
    else:
        if target not in found:
            raise ValueError(f"{target} carries no {ASSET.format(version=target[1:])}; leaving the pin alone")
        tag = target

    subprocess.run(
        ["nix-update", "--flake", "--version", tag, "codexbar"],
        check=True,
    )
    print(f"codexbar-update: {tag}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"codexbar-update: {error}", file=sys.stderr)
        sys.exit(1)
