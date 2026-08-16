# Proposal: dendritic-single-tree

## Why

The current layout keeps two parallel trees — `flake-modules/` (one-liner aspect
wrappers, domain-grouped) and `modules/{home,system}` (raw class modules,
class-first) — duplicating domain structure and adding indirection files.
Validated against the canonical dendritic sources (mightyiam/dendritic README,
Dendrix guide, denful/import-tree semantics, real repos: mightyiam/infra,
vic/vix, jonwin1/nixos-jonwin): the wrapper+impl two-tree split appears in zero
community repos and contradicts the pattern's core rules (every file has one
interpretation — a flake-parts module; feature closure in one unit; paths name
features, not classes).

## What Changes

- Collapse to a single `modules/` scan root: every `.nix` file is a flake-parts
  module publishing `flake.modules.homeManager.<name>` / `flake.modules.systemManager.<name>`
  with the class module inline as the value (raw module function becomes the value).
- One file per feature across all classes it applies to: `nix.nix`, `ssh.nix`,
  `tailscale.nix` each hold both class values (validation: class-named files like
  `nix/{home,system}.nix` are a deviation).
- Split aggregates (`agents`, `foundation`, `services`) into per-feature aspect
  files; the host already toggles features individually.
- Move host composition in-tree: `modules/hosts/arch.nix` builds both host
  outputs from published aspects; `flake.nix` becomes a minimal manifest.
  Per-host raw files live `/_`-ignored beside it.
- Move flake-level scaffolding and perSystem tooling to `modules/flake/`.
- Delete `flake-modules/` and `modules/{home,system}`.
- Update the four canonical specs that hardcode old paths (ssh-client, tmux,
  mutagen, wezterm-config) and the maintained docs.

## Impact

- All module files move/rewrap (mechanical); no behavior change intended.
- `nix flake check`, treefmt, statix/deadnix filesets, and lefthook continue to
  pass; niri `extraConfig` render ordering must be preserved.
