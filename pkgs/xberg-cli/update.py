#!/usr/bin/env python3
"""Update xberg-cli to the newest release that actually carries its archive.

Upstream publishes a release before its build assets finish uploading, and one
can be left without assets entirely. Selecting a tag by version alone hands
nix-update a URL that 404s — and it rewrites the version attribute before it
prefetches, leaving the pin pointing at a source that does not exist. Only
releases that have settled and ship `xberg-cli-x86_64-unknown-linux-gnu.tar.gz`
are eligible, so the newest unusable tag is skipped instead of adopted.

An explicit `XBERG_UPDATE_VERSION=vX.Y.Z` bypasses the settling window (an
operator asking for a specific release) but still requires the archive.
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from urllib.request import Request, urlopen

ASSET = "xberg-cli-x86_64-unknown-linux-gnu.tar.gz"
SETTLING = timedelta(hours=float(os.environ.get("XBERG_UPDATE_SETTLING_HOURS", "24")))
STABLE = re.compile(r"v[0-9]+\.[0-9]+\.[0-9]+")


def releases():
    url = "https://api.github.com/repos/xberg-io/xberg/releases?per_page=100"
    found = []
    while url:
        request = Request(url, headers={"User-Agent": "nix-dotfiles-xberg-cli-update"})
        with urlopen(request, timeout=60) as response:
            found.extend(json.load(response))
            link = re.search(r'<([^>]+)>;\s*rel="next"', response.headers.get("Link", ""))
            url = link[1] if link else None
    return found


def key(tag):
    return tuple(int(part) for part in tag[1:].split("."))


def has_asset(release):
    return any(asset["name"] == ASSET for asset in release["assets"])


def settled(release, now):
    if not release["published_at"]:
        return False
    published = datetime.fromisoformat(release["published_at"].replace("Z", "+00:00"))
    return now - published >= SETTLING


def main():
    target = os.environ.get("XBERG_UPDATE_VERSION", "stable")
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
            raise ValueError(f"no settled release carries {ASSET}")
        tag = max(eligible, key=key)
    else:
        if target not in found:
            raise ValueError(f"{target} carries no {ASSET}; leaving the pin alone")
        tag = target

    if "--latest" in sys.argv:
        print(tag.removeprefix("v"))
        return

    subprocess.run(
        [
            "nix-update",
            "--flake",
            "--version",
            tag,
            "--version-regex",
            r"^v([0-9]+)\.([0-9]+)\.([0-9]+)$",
            "xberg-cli",
        ],
        check=True,
    )
    print(f"xberg-cli-update: {tag}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"xberg-cli-update: {error}", file=sys.stderr)
        sys.exit(1)
