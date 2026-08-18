## Why

An external review benchmarked this repository's patterns against the canonical
Dendritic Nix reference. That review confirmed, against
[`mightyiam/dendritic`](https://github.com/mightyiam/dendritic) and
[`dendrix.denful.dev/Dendritic.html`](https://dendrix.denful.dev/Dendritic.html),
that a set of current patterns are **approval-gated anti-patterns** in this
repository dialect (`.skills/dendritic-nix/SKILL.md`, §"Anti-patterns and
deviation protocol"). The use of `specialArgs`/`extraSpecialArgs` as a
dependency bus, the ambient `hostFacts` record, the monolithic
`modules/secrets.nix` registry, duplicated package ownership, and the niri
import-order coupling are all on that list.

This change is **architectural cleanup only** — no new features surface. The
goal is to make the single Arch host conform to the dialect before NixOS class
introspection on migration day, so NixOS modules can be added to the same
feature tree without inheriting the anti-patterns.

## What Changes

Four task groups remove the anti-patterns and establish the canonical shape:

### Group A — Mechanical SSOT cleanup
- Remove duplicated package ownership: `eza` (`modules/dev-tools/cli.nix:22` —
  duplicate of `programs.eza.enable`) and `pistol` (`modules/shell/default.nix:25` —
  duplicate of `programs.pistol.enable`).
- Collapse hardcoded literals onto their canonical typed owners: greeter
  `--user saurabhj` → `hostFacts.username`; navi `--flake .#saurabhj` → derived
  from `config.home.username`; LiteLLM port `8765` → `config.programs.litellm.port`
  in three files (aichat `api_base`, hermes `base_url`, `_generated.nix` `baseURL`).
- Sync the stale KDE platform-theme comment (portals now sets `gtk3`, not `qt6ct`).
- Add a cheap CI job building `.#checks.x86_64-linux.{statix,deadnix,treefmt}`
  (the current `nix flake check --no-build --no-write-lock-file` only evaluates,
  never executes checks).
- Add `COMPAT(arch):` / `TODO(nixos):` markers (tenet 14) to all remaining
  Arch-specific hacks.

### Group B — Eliminate `inputs`/`hostFacts` anti-pattern + typed topology
- Define a typed top-level `topology` option (flake-parts), populated once from
  the Arch host composition layer, replacing the `hostFacts` ambient record.
- Remove `inputs` argument injection from lower-level modules via lexical
  capture at the top-level feature boundary (tenet 8).
- Replace `hostFacts.*` reads with native options whenever possible:
  `config.home.username`, `config.home.homeDirectory`,
  `pkgs.stdenv.hostPlatform.system` (tenet 7).

### Group C — Secrets hybrid aspect-owned design
- Split the `modules/secrets.nix` monolith (tenet 10): a SOPS foundation
  module + a shared-credentials aspect, with service-specific templates owned
  by their consumer feature modules. sops-nix's `sops.placeholder.X` mechanism
  (built from the fully-merged module config) makes cross-module reference
  safe.
- Delete the monolith; register the two new aspects.

### Group D — Niri KDL file-include refactor (DMS-style)
- Move monique/noctalia contributions out of niri's `extraConfig` (a
  `types.lines` merge, order-coupled to host import list — tenet 12) into
  separate `.kdl` files written via `xdg.configFile`, then include them from
  niri's own single-author `extraConfig` string via `include optional=true`.

## Consequences

- `modules/hosts/arch.nix` removes `inputs` + `hostFacts` from
  `specialArgs`/`extraSpecialArgs`, registers `sops` + `credentials` in
  `hmAspects`, and drops the import-order warning comment.
- `modules/hosts/arch/_facts.nix` is removed or shrunk to host-local literals;
  service topology folds into `topology.services`.
- `modules/secrets.nix` is deleted; SOPS activation/decryption behavior is
  unchanged (same sops-nix, same secrets, just relocated + owner-split).
- Niri's rendered `config.kdl` is byte-equivalent to today.
- CI gains real derivation-based checks (statix/deadnix/treefmt) on top of the
  existing no-build eval gate.

## Out of scope (deferred to NixOS day)

Niks3 post-build-hook + socket path consolidation (niks3 is being replaced by a
native NixOS module on migration day — but its current code still gets the
topology fix). Secret ciphertext reorganization into
shared/users/hosts/services dirs (single age key + single host today). Formal
`session-credentials` three-scope infrastructure. A new `shrub.primaryUser`
namespace (system-manager is transitional). `cli.nix` split. Extract
`workstation-home` composition. These are documented explicitly in `design.md`.
