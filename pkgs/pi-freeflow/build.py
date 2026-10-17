#!/usr/bin/env python3
"""Stage pi-freeflow from its npm tarball with one compat correction.

The relay pool forwards each request on the caller's behalf and honours no long
prompt-cache retention, so Pi must not ask an upstream for it. The extension
sets a per-model `compat` object and never names that key, which leaves Pi's
capability detection to claim support. Filling it in at registration is the one
seam that covers every catalogue model, including the ones a background
catalogue refresh adds later.
"""

import os
import pathlib
import tarfile

OUT = pathlib.Path(os.environ["out"])


def extract(tarball: str, into: pathlib.Path) -> None:
    into.mkdir(parents=True, exist_ok=True)
    with tarfile.open(tarball) as archive:
        for member in archive.getmembers():
            parts = member.name.split("/", 1)
            if len(parts) < 2:
                continue
            member.name = parts[1]
            archive.extract(member, into, filter="data")


extract(os.environ["package"], OUT)
# The daemon it spawns imports undici, and a store path is read-only, so the
# dependency rides along instead of being installed beside it.
extract(os.environ["undici"], OUT / "node_modules" / "undici")

entry = OUT / "src" / "index.ts"
source = entry.read_text()
registered = "\n".join(
    [
        '  pi.registerProvider(',
        '   "freeflow",',
        "   buildProviderConfig(models, actualPort),",
        "  );",
        "",
    ]
)
patched = "\n".join(
    [
        "  const providerConfig = buildProviderConfig(models, actualPort);",
        "  // The relay pool forwards on the caller's behalf and honours no long",
        "  // cache retention, so never claim it to an upstream.",
        '  pi.registerProvider("freeflow", {',
        "   ...providerConfig,",
        "   models: providerConfig.models.map((m) => (",
        "    { ...m, compat: { ...m.compat, supportsLongCacheRetention: false } }",
        "   )),",
        "  });",
        "",
    ]
)
if source.count(registered) != 1:
    raise SystemExit("pi-freeflow: provider registration moved; the patch anchor is stale")
entry.write_text(source.replace(registered, patched))
