#!/usr/bin/env python3
"""Unpack the npm packages the compiled plugins import.

Pi-Bolt's plugin builder copies one node_modules into each plugin's own tree, so
the plugin code and its dependencies resolve inside the payload's tree. The packages
arrive as the registry's tarball pins (pkgs/pi-plugins owns those); this script is
the one place they are unpacked.
"""

import json
import os
import pathlib
import sys
import tarfile

packages = json.loads(pathlib.Path(sys.argv[1]).read_text())
out = pathlib.Path(os.environ["out"]) / "node_modules"

for entry in packages:
    target = out / entry["name"]
    target.mkdir(parents=True)
    with tarfile.open(entry["path"]) as archive:
        for member in archive.getmembers():
            # npm tarballs wrap everything in a top-level "package/" directory.
            parts = member.name.split("/", 1)
            if len(parts) < 2:
                continue
            member.name = parts[1]
            archive.extract(member, target, filter="data")
