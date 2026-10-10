# Pi-Bolt release pins

## A tag supplies the source; the runtime is a separate asset keyed to the engine stamp

**Id:** 8cd16a96-d846-4e6c-b4aa-1e95c3d510fe
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Verification:** corroborated — the runtime archive's digest moved with `bolt-v0.7.3` (`ed148751…` → `3d82cc55…`), matching the stamp's coverage of the webkit and bun pins, both patches and both runtime build scripts
**Revisit when:** upstream changes what the runtime stamp covers, or a release ships without the archive

The pin consumes `opensec-git/Pi-Bolt` at `bolt-v0.7.3`. A tag supplies the
source tree; the compiled engine the AOT step builds against is a separate
release asset, `pi-bolt-runtime-linux-x64.tar.gz`, whose hash is keyed to the
engine stamp rather than to the version. When the stamp is unchanged between
two releases the newer tag reuses the older archive byte for byte, so the hash
does not move with the version.

**Reason:** upstream's `release.yml` asserts the tree's `VERSION` equals the
tag, so a tag is the only version at which the tree and the runtime are
published together. The runtime itself is built by hand on Linux and on a Mac
and attached to the tag's draft, which is why it can lag the tag or be missing
from it.

**Rejected alternatives:** pointing the runtime URL at whichever release
carries the archive splits one owner's two pins across repositories, and the
owner's update step writes both from one root, so it would undo itself.
Building a fresh runtime would diverge from upstream's artifact for no gain.

**Consequence:** a release whose engine stamp moved must carry its own runtime
archive before the pin can move. Otherwise the update stops at the asset
prefetch — the tag's source archive is present, so the release looks fine while
the pin cannot be written from it.

**History:** from 2026-10-08 to 2026-10-10 the pin consumed `Shrub24/Pi-Bolt` at
`bolt-v0.7.2`, a fork release carrying Pi coding-agent 1.1.0 ahead of upstream.
That fork's releases carry no assets — Actions does not run there — so its
runtime archive was uploaded to the tag by hand from the upstream release whose
engine stamp matched. The pin returned to upstream once `bolt-v0.7.3` published
with its own runtime archive.
