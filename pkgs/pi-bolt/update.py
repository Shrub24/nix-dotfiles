#!/usr/bin/env python3
"""Update the Pi-Bolt release and its coupled runtime/dependency pins."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.request import Request, urlopen


def release():
    target = os.environ.get("PI_BOLT_UPDATE_VERSION")
    if target and not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", target):
        raise ValueError("PI_BOLT_UPDATE_VERSION must be a stable X.Y.Z version")
    url = "https://api.github.com/repos/Shrub24/Pi-Bolt/tags?per_page=100"
    tags = []
    while url:
        headers = {"User-Agent": "nix-dotfiles-pi-bolt-update"}
        if token := os.environ.get("GITHUB_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
        with urlopen(Request(url, headers=headers), timeout=60) as response:
            tags.extend(tag["name"] for tag in json.load(response))
            next_page = re.search(r'<([^>]+)>;\s*rel="next"', response.headers.get("Link", ""))
            url = next_page[1] if next_page else None
    versions = [tag.removeprefix("bolt-v") for tag in tags if re.fullmatch(r"bolt-v[0-9]+\.[0-9]+\.[0-9]+", tag)]
    if target:
        versions = [version for version in versions if version == target]
    if not versions:
        raise ValueError("no matching stable Pi-Bolt release")
    return max(versions, key=lambda version: tuple(map(int, version.split("."))))


def prefetch(url, unpack=False):
    command = ["nix-prefetch-url"] + (["--unpack"] if unpack else []) + [url]
    digest = subprocess.check_output(command, text=True).strip()
    return subprocess.check_output(
        ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", digest], text=True
    ).strip()


def replace(text, pattern, value):
    result, count = re.subn(pattern, lambda match: match[1] + value + match[2], text, flags=re.DOTALL)
    if count != 1:
        raise ValueError(f"expected one pin for {pattern!r}, found {count}")
    return result


def main():
    tag = f"bolt-v{release()}"
    root = "https://github.com/Shrub24/Pi-Bolt"
    source_hash = prefetch(f"{root}/archive/{tag}.tar.gz", unpack=True)
    runtime_hash = prefetch(f"{root}/releases/download/{tag}/pi-bolt-runtime-linux-x64.tar.gz")
    filename = Path("pkgs/pi-bolt/default.nix")
    text = filename.read_text()
    text = replace(text, r'(  tag = ")[^"]+(";)', tag)
    text = replace(text, r'(  src = fetchFromGitHub \{.*?sha256 = ")[^"]+(";)', source_hash)
    text = replace(text, r'(  runtime = fetchurl \{.*?sha256 = ")[^"]+(";)', runtime_hash)
    filename.write_text(text)
    print(f"pi-bolt-update: {tag}", flush=True)
    subprocess.run([
        "nix-update", "--flake", "--version=skip", "--no-src",
        "--subpackage", "payload", "--override-filename", str(filename), "pi-bolt",
    ], check=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"pi-bolt-update: {error}", file=sys.stderr)
        sys.exit(1)
