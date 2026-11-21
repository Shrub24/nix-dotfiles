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

## The request-model change is carried as a fork branch, not a patch over the source

**Id:** 2f38deb5-ad4e-44b4-8cce-0b7fc5be44fc
**Type:** decision
**Status:** superseded
**Superseded by:** 8ba502cc-7ca6-48e9-8a89-11a1e4dd999c
**Evidence:** confirmed
**Source:** nixbot build 3 of Shrub24/nix-dotfiles, 2026-11-19 — "cannot build pi-bolt-request-model-source.drv^out during evaluation because the option 'allow-import-from-derivation' is disabled"

`pi-bolt-source` follows `github:Shrub24/Pi-Bolt/request-model`: `bolt-v1.2.1` plus one commit carrying the change that forwards the resolved request model to context handlers (earendil-works/pi#10318). It replaced an `applyPatches` derivation swapped in as `source.outPath` in `pkgs/pi-bolt/default.nix`.

**Reason:** Pi-Bolt.nix reads the source during evaluation — `VERSION`, the workspace lockfile, and the `builtins.path` filters in `nix/source.nix` — so any derivation in the source's place is import-from-derivation, and the fleet's CI evaluates with it disabled. A fork branch keeps the source a plain input. Every file the branch carries is identical to the old patched output, which differed only by four `.orig` files `patch` left behind.
**Alternatives:** keep the patch and allow import-from-derivation for this repository, which breaks the fleet's build-free evaluation; patch inside Pi-Bolt.nix's build derivations, which it has no argument for.
**Revisit when:** superseded — Pi-Bolt.nix gained a `patches` argument applied inside its workspace build, the second alternative above.

## The request-model change is a patch passed through Pi-Bolt.nix's `patches`

**Id:** 8ba502cc-7ca6-48e9-8a89-11a1e4dd999c
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** Pi-Bolt.nix `nix/pi-bolt.nix` and `nix/workspace.nix` (`patches`); a payload built with `pkgs/pi-bolt/patches/request-model.patch` carries `requestModel` in its workspace and compiled executable, the unpatched build does not

`pkgs/pi-bolt/default.nix` passes `patches = [ ./patches/request-model.patch ]` to the payload; the source is the release `pi-bolt-nix` pins, with no follow. The patch is the `Shrub24/Pi-Bolt/request-model` commit, unchanged.

**Reason:** Pi-Bolt.nix applies `patches` in the workspace derivation's patch phase, after evaluation has read `VERSION`, the manifests and the lock from the unpatched input, so the fleet's build-free evaluation still holds, and there is no branch to rebase on each release.
**Consequence:** the patch may touch only the files the workspace builds from, minus `package.json` and `package-lock.json`; anything else fails its patch phase. A release that conflicts with it fails the build at that phase.
**Revisit when:** Pi exposes the request model natively (earendil-works/pi#10318): drop the patch.
