# mcp-nixos on the mcp 1.x SDK

## mcp-nixos keeps the mcp 1.x SDK that our pinned nixpkgs no longer defaults to

**Id:** b4822f6a-d921-4ca3-abab-9bf022a96bd2
**Type:** workaround
**Status:** active
**Evidence:** confirmed
**Source:** nixpkgs commits `3201cb18d` (_mcp-nixos: use mcp_1_) and `c9a6f0169`
(_mcp-nixos: 3.0.1 -> 3.0.2_); nixpkgs PRs #575004 (mcp 1.29.0 -> 2.2.0, merged),
#563493 (fastmcp 3.4.7 -> 4.0.10, open)
**Revisit when:** nix-fleet's nixpkgs pin passes 2026-10-25, or fastmcp 4 reaches
nixpkgs

The `mcp-nixos` entry in `pkgs/default.nix` rebuilds nixpkgs' package with its
Python scope's `mcp` pinned to `mcp_1`.

**Reason:** `fastmcp-slim` declares `broken = lib.versionAtLeast mcp.version "2"`,
and `fastmcp` 3.4.7 links it, so every consumer of `fastmcp` becomes unbuildable
once `mcp` leaves 1.x. The nixpkgs rev this repository pins through nix-fleet
(`3ec6363`, 2026-10-23) is one of those: it moved `mcp` to 2.2.0 and left the
consumers alone, which surfaced as an evaluation failure on
`mcp-nixos.service`'s `ExecStart`. Upstream fixed it inside the package a day
later, because fastmcp 4 — the version that does speak mcp 2.x, and the one
mcp-nixos 3.1.0 requires — had not landed.

**Alternatives:** pin nix-fleet back to `0122575` (`nixpkgs` `fe13242`, 2026-10-15),
which costs two weeks of nixpkgs for one package; add a second nixpkgs input for
this package alone, which duplicates a full nixpkgs evaluation and a Python
closure to fix six lines; raise `problems.handlers."fastmcp-slim".broken` to
`"ignore"`, which clears the gate without making fastmcp 3.4.7 run on mcp 2.x.
**Unknown:** whether mcp-nixos 3.1.0 alone would have sufficed, since it needs
fastmcp 4 and nixpkgs still carries 3.4.7.
