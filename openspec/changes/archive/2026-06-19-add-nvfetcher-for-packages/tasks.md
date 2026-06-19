## 1. Add nvfetcher foundations

- [x] 1.1 Add a pinned `nvfetcher` flake input and expose a repo-local command or shell path for running nvfetcher.
  - refs: `flake.nix`
  - criteria: maintainers can run nvfetcher from the repo without ad-hoc global setup
  - verify: evaluate or run the nvfetcher entrypoint/help path from the flake
- [x] 1.2 Create the repo nvfetcher configuration for `snip`, `kreuzberg-cli`, and `headroom-ai`.
  - refs: `nvfetcher.toml`, `pkgs/snip/default.nix`, `pkgs/kreuzberg-cli/default.nix`, `pkgs/headroom-ai/default.nix`
  - criteria: only the scoped package set is declared and the excluded packages remain out of scope
  - verify: nvfetcher parses the config successfully

## 2. Seed and wire generated package sources

- [x] 2.1 Generate and commit nvfetcher source metadata for the selected package set.
  - refs: generated source metadata path, `nvfetcher.toml`
  - depends: 1.2
  - criteria: committed generated metadata exists for all three target packages
  - verify: generated metadata evaluates cleanly in Nix
- [x] 2.2 Wire the generated source metadata into the flake overlay for `snip`, `kreuzberg-cli`, and `headroom-ai`.
  - refs: `flake.nix`
  - depends: 2.1
  - criteria: the overlay passes generated source/version data into `snip` and `kreuzberg-cli`, and passes generated version metadata into `headroom-ai`, without disturbing excluded package wiring
  - verify: flake evaluation succeeds for the affected package paths

## 3. Migrate target derivations

- [x] 3.1 Refactor `pkgs/snip/default.nix` to consume generated source metadata while preserving its Go build behavior.
  - refs: `pkgs/snip/default.nix`
  - depends: 2.2
  - criteria: `snip` no longer hardcodes upstream version/source fetch fields inline
  - verify: build or evaluate `snip`
- [x] 3.2 Refactor `pkgs/kreuzberg-cli/default.nix` to consume generated source metadata while preserving its release-tarball install flow.
  - refs: `pkgs/kreuzberg-cli/default.nix`
  - depends: 2.2
  - criteria: `kreuzberg-cli` no longer hardcodes upstream version/source fetch fields inline
  - verify: build or evaluate `kreuzberg-cli`
- [x] 3.3 Refactor `pkgs/headroom-ai/default.nix` to consume generated version metadata while remaining wheel-based.
  - refs: `pkgs/headroom-ai/default.nix`
  - depends: 2.2
  - criteria: `headroom-ai` uses generated version metadata and still declares `format = "wheel"`
  - verify: build or evaluate `headroom-ai`

## 4. Validate the update workflow

- [x] 4.1 Validate end-to-end evaluation/build behavior for the three migrated packages.
  - refs: `flake.nix`, target derivations, generated source metadata
  - depends: 3.1, 3.2, 3.3
  - criteria: all three packages evaluate or build successfully through the flake
  - verify: run the scoped flake/package checks
- [x] 4.2 Document the nvfetcher update path and the explicit exclusions retained in this repo.
  - refs: `nvfetcher.toml`, `flake.nix`, relevant docs/comments
  - depends: 4.1
  - criteria: maintainers can tell which packages are nvfetcher-managed versus intentionally left on other source workflows
