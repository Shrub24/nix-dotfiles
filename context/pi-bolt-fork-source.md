# Pi-Bolt fork source

## The payload compiled a fork branch ahead of release, and its engine stamp had to match the pinned release's runtime

**Id:** b3b36265-64f4-47d0-92c3-5730ed8b797c
**Type:** decision
**Status:** superseded
**Superseded by:** 8cd16a96-d846-4e6c-b4aa-1e95c3d510fe
**Evidence:** confirmed
**Source:** `scripts/runtime-stamp.sh` run on the locked inputs, 2026-11-10 —
`sync/pi-1.5.1` at `f435dbcc` → `9606e2f852e92ee9`; `bolt-v1.1.4` (the pin) →
`2e54e6641c78fd6d`, the value in Pi-Bolt.nix's `nix/runtime-data.nix`; `bolt-v1.1.6`
and `bolt-v1.1.7` → `f8df9521cb288289`
**Verification:** corroborated — the pin's stamp recomputes to the recorded runtime stamp,
and every engine input the branch carries is byte-identical to 1.1.7's except
`scripts/build-runtime.ps1`, which differs only in line endings
**Revisit when:** superseded — Pi-Bolt 1.2.1 shipped the 1.5.1 and 1.5.2 work as an official release with
1.2.0's runtime, so the override is gone and the payload compiles the release the `pi-bolt-nix` input pins.

`modules/flake/inputs.nix` declared `pi-bolt-fork` at
`github:Shrub24/Pi-Bolt/sync/pi-1.5.1` (`flake = false`, a source) and follows
`pi-bolt-nix.inputs.pi-bolt-source` onto it. Pi-Bolt.nix compiles `pi-bolt-source`
into the payload and takes its runtime from the release, so the follow is the whole
override — nothing else in this repository names a Pi-Bolt source.

**Reason:** the branch carries the pi v1.5.1 sync (`sources.json` profile
`profiles/pi-1.5.1`, `VERSION` 1.1.8) that no release has yet. Its engine is the one
1.1.6 introduced: `patches/bun.patch` moved from `77bfcc39` at 1.1.4 to `cd3f4d7a`,
while `patches/webkit.patch`, `scripts/build-runtime.sh`, `scripts/toolchain/*`, the
runtime hints and the two `sources.json` engine entries are unchanged since 1.1.7.
The only hashed file the branch changes is `scripts/build-runtime.ps1`, and only by
storing it with CRLF endings.

**Consequence:** the branch cannot build against the 1.1.4 pin — `nix/pi-bolt.nix`
aborts with "this source's engine is not release 1.1.4's" — and relaxing
`checkRuntimeStamp` there would be unsound, since `bun.patch` genuinely moved. Two
sound paths, both starting from the release the engine belongs to: pin
`bolt-v1.1.7` (and record its runtime), after which the branch edits a stamped file
without changing the engine and the check is relaxed for exactly that case, as
[pi-bolt-release-pins](pi-bolt-release-pins.md) allows; or wait for 1.1.8, whose
published runtime mints the branch's own stamp and needs no relaxation.

**History:** the input existed once before, for `fix/weak-render-owners`, and was
dropped when that fix reached release 1.0.9. The constraint that returned it is the
same one recorded then: following a fork branch moves the runtime with it.
