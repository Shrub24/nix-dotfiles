# Tasks

## 1. Remove the retired package

- [ ] 1.1 Remove byterover: drop its entry from `nvfetcher.toml`, delete `pkgs/byterover/`, remove the `byterover-cli` binding from `pkgs/default.nix`, and drop the `.brv/**` exclusion from `modules/flake/tooling.nix`; verify no reference remains outside `openspec/` and that `nix flake check --no-build --no-write-lock-file` passes.

## 2. Declare pins with the package that owns them

- [ ] 2.1 `pkgs/pi-bolt`: declare the release tag, the source tree and the AOT runtime asset as literals in the file — the version being that tag minus upstream's prefix — instead of receiving `src`, `version` and `runtime` from `pkgs/default.nix`, and correct the file's `pkgs/_sources` comment; verify `nix build .#packages.x86_64-linux.pi-bolt` yields the same upstream revision as before, by comparing the embedded pi-extensions store path and the runtime revision with the pre-change build.
- [ ] 2.2 `pkgs/xberg-cli` and `pkgs/codexbar`: declare `version` and `src` as literals instead of receiving them from `pkgs/default.nix`; verify each builds and reports the same version as before.
- [ ] 2.3 `pkgs/pi-plugins`: replace the `_sources/generated.nix` import with a literal OmniRoute checkout pin and restate the `npmTarball` comment as the owner-and-script reason rather than "nvfetcher cannot"; verify the compiled plugin set is unchanged by comparing the two generated `plugins.ts` manifest derivations against the pre-change hashes.
- [ ] 2.4 Delete `pkgs/_sources/` and reduce `pkgs/default.nix` to plain `callPackage`s with no `generatedSources` binding; verify the flake evaluates and every package in the overlay builds.

## 3. Register the owners and provide the update mechanism

- [ ] 3.1 Import `nix-fleet.flakeModules.packageUpdates` in `modules/flake/` and register the four owners, publishing each new name as a `packages.<system>` output beside the existing `packages.pi-bolt` and `packages.pi-bolt-child` declarations; verify the app's preflight accepts the registry, that `nix eval .#packages.x86_64-linux --apply builtins.attrNames` lists every registered name, and that an unregistered name is refused without any owner being updated.
- [ ] 3.2 Make `pi-plugins` a derivation over its pinned source set, carrying the recipe attrset and the update script in `passthru` while `pi-bolt` keeps consuming the recipes; verify the derivation builds and the compiled plugin set is unchanged.
- [ ] 3.3 Write the `pi-bolt` owner's update script, moving the release tag, source tree, runtime asset and `npmDepsHash` in one step with the hash refreshed by a nested `nix-update --version=skip --no-src`; verify a recorded-target run moves all four together and that a second run at the same target produces no diff.
- [ ] 3.4 Write the `pi-plugins` owner's update script for the 25 npm tarballs and the OmniRoute branch head; verify a recorded-target run produces exactly the expected pin diff, a re-run is a no-op, and an unresolvable OmniRoute target fails the run instead of resolving to a release.
- [ ] 3.5 Write `xberg-cli`'s update script with the release tag family selected explicitly and leave `codexbar` on the standard path; verify each owner updates at a recorded target and re-runs clean, and give codexbar a script if the standard path cannot locate or update it.
- [ ] 3.6 Move the operator surface and docs to the new mechanism: replace the `justfile`'s `nvfetcher` and `nvfetcher-one` recipes with the update app (all owners, and one named owner), and update `ARCHITECTURE.md` and `context/pi-plugin-sources.md`; verify `just --list` shows the new recipes and that no live document still describes nvfetcher as how pins are updated.

## 4. Retire nvfetcher and record the supersession

- [ ] 4.1 Delete `nvfetcher.toml` and remove the dev-shell entry, `apps.nvfetcher-update` and the `pkgs/_sources/**` exclusion from `modules/flake/tooling.nix`; verify `grep -rn nvfetcher` finds nothing outside `openspec/` and `context/`, and that `nix flake check --no-build --no-write-lock-file` passes.
- [ ] 4.2 Mark the capability superseded: set `status: superseded` in `openspec/specs/nvfetcher-package-sources/spec.md`, move its `INDEX.md` row to superseded, and add the `package-updates` row with this change as its source; verify `openspec validate adopt-fleet-package-updates` passes and the INDEX status matches the spec front-matter.
- [ ] 4.3 Record why in `context/`: an entry for the mechanism swap carrying the locator rule, the tracked-only-evaluation trap and the per-owner script reasons, plus its index line; verify `ktw-lint` reports 0 errors and 0 warnings.

## 5. Acceptance

- [ ] 5.1 Run the update app as a candidate at recorded targets for every owner and verify the canonical validation on the result: `nix fmt` reports no changes, `nix flake check --no-build --no-write-lock-file` passes, and both NixOS configurations evaluate.
- [ ] 5.2 Prove idempotence across the whole registry: re-run at the same recorded targets and verify the working copy shows no diff.
- [ ] 5.3 Verify the migration delivered no content change: both NixOS toplevels evaluate, and the `pi-bolt` and `pi-bolt-child` pair builds with the same compiled plugin sets and the same Pi version as before the change.

## Workflow follow-up

- Archive this change once the acceptance group passes: the canonical `package-updates` spec is created from its delta, and the nvfetcher spec's two requirements are removed while the retirement requirement stays.
- The CI half — validation gates, the reusable build-push-cache workflow and its provisioning — stays tracked in `settle-after-nixos-transition` and consumes the registered owners and the canonical acceptance established here.
