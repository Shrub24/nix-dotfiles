# Pi-Bolt release pins

## A tag supplies the source; the runtime is a separate asset keyed to the engine stamp

**Id:** 8cd16a96-d846-4e6c-b4aa-1e95c3d510fe
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** Pi-Bolt.nix's `scripts/update-runtime.sh`, `nix/runtime.json` and `keys/release.pub`, at the revision this repository's `pi-bolt-nix` input locks
**Verification:** corroborated — the runtime archive's digest moved with `bolt-v0.7.3`, matching the stamp's coverage of the webkit and bun pins, both patches and both runtime build scripts; in the flake, each recorded release carries its own stamp and both platforms' archives, and `0.9.4` and `0.9.5` differ in both stamp and hash
**Revisit when:** upstream changes what the runtime stamp covers, a release ships without the archive, or the flake stops verifying the release's signature against its pinned key

The runtime is a release asset, `pi-bolt-runtime-linux-<arch>.tar.gz`, keyed to
the engine stamp rather than to the version: a tag whose stamp is unchanged
reuses the previous release's archive byte for byte, so the hash does not move
with the version. This repository does not fetch either artifact. The
`pi-bolt-nix` input owns that pin — the release tag, and `nix/runtime.json`,
which records each release version's stamp and archive hash per platform — and
reads it through `release` and `source` arguments whose defaults are its own
inputs (`pi-bolt` at the release tag, `pi-bolt-source` following it).

**Reason:** upstream's `release.yml` asserts the tree's `VERSION` equals the tag,
so a tag is the only version at which the tree and the runtime are published
together. The runtime itself is built by hand on Linux and on a Mac and attached
to the tag's draft, which is why it can lag the tag or be missing from it. Its
recording is a verification chain rather than a hash copied by hand:
`scripts/update-runtime.sh` fetches the release's `SHA256SUMS`, its signature and
`RUNTIME_STAMP`, verifies the signature against `keys/release.pub` — the
repository's pinned copy of the release key, not the copy in the release — then
checks each archive's digest against the signed sums, and re-running it for a
recorded version checks the recording without changing it. A source whose engine
stamp is not the runtime's fails the build (`checkRuntimeStamp`), which is relaxed
only for a branch that edits stamped files without changing the engine.

**Rejected alternatives:** each consumer fetching the archives and verifying them
itself duplicates the chain per repository and gives the release pin a second
author. Following a release without recording a stamp would let a source compile
against the wrong engine, since the archive alone does not say which engine it is.

**Consequence:** a release whose engine stamp moved must carry its own runtime
archive and be recorded in the flake before this repository can move its input.
Bumping Pi-Bolt is `nix flake update pi-bolt-nix`; a source that needs a runtime
of its own — a branch touching the engine, its patches, the toolchain or the
hints — cannot be built without `checkRuntimeStamp = false`.

**History:** from 2026-10-08 to 2026-10-10 the pin consumed `Shrub24/Pi-Bolt` at
`bolt-v0.7.2`, a fork release carrying Pi coding-agent 1.1.0 ahead of upstream.
That fork's releases carry no assets — Actions does not run there — so its
runtime archive was uploaded to the tag by hand from the upstream release whose
engine stamp matched; the pin returned to upstream once `bolt-v0.7.3` published
with its own runtime archive. Until 2026-10-19 the pin lived in `pkgs/pi-bolt` as
a `bolt-v0.9.4` tag beside fetches of the compile kit and the runtime; adopting
the flake moved it into that repository's `nix/runtime.json` and made this
repository a consumer, with `pi-bolt` no longer carrying an updater of its own.
