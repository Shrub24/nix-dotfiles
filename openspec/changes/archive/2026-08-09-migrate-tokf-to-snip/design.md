## Context

This repo manages developer tooling through a Home Manager flake plus a small set of custom packages under `pkgs/`. Today `tokf` is a custom Rust derivation that is installed as part of `programs.agentTools`, while OpenCode configuration is maintained imperatively under `apps/opencode/opencode.jsonc` and symlinked into place by Home Manager.

The replacement tool, `snip`, is an upstream Go CLI with an independent OpenCode plugin (`opencode-snip`) published on npm. The migration crosses package management, Home Manager composition, imperative OpenCode plugin wiring, and developer documentation. That makes a small design artifact worthwhile before implementation.

## Goals / Non-Goals

**Goals:**

- Package `snip` as a pinned custom Nix derivation in `pkgs/`
- Replace `tokf` with `snip` in the `programs.agentTools` package set
- Add `opencode-snip` to the OpenCode plugin list so OpenCode can transparently prefix shell commands with `snip`
- Remove the obsolete local `tokf` package and document the new tool locations/wiring
- Verify the Home Manager configuration still evaluates and builds cleanly

**Non-Goals:**

- Packaging `opencode-snip` as a Nix derivation
- Generating shell completions for `snip` (upstream does not currently ship them)
- Reworking non-OpenCode agent integrations such as Pi, Claude Code, or Aider
- Generalizing output filtering into a new reusable module abstraction

## Decisions

### D1: Build `snip` from GitHub source via `buildGoModule`

- **Decision**: Create `pkgs/snip/default.nix` using `buildGoModule`, pinned to a specific upstream release tag.
- **Rationale**: Upstream ships a single static Go binary and does not need CGO. Building from source keeps the derivation reproducible and consistent with the repo's custom packaging style.
- **Alternatives considered**:
  - Use nixpkgs `snip` — simpler, but currently version-lagged relative to upstream.
  - Fetch upstream release tarballs — quick, but less idiomatic and harder to patch later.

### D2: Keep OpenCode plugin installation imperative

- **Decision**: Add `opencode-snip@latest` to `apps/opencode/opencode.jsonc` rather than packaging the plugin in Nix.
- **Rationale**: The existing OpenCode setup already mixes npm-hosted plugins with local plugin paths in imperative config. Matching that pattern minimizes scope and avoids introducing a Node package build just for a thin plugin.
- **Alternatives considered**:
  - Package `opencode-snip` with `buildNpmPackage` — more reproducible, but unnecessary for this migration.
  - Skip the plugin and require manual `snip` prefixes — lower automation and weaker replacement for tokf.

### D3: Remove `tokf` entirely rather than running both tools in parallel

- **Decision**: Replace `tokf` rather than temporarily shipping both packages.
- **Rationale**: `tokf` is only lightly integrated in this repo. Dual-shipping would add ambiguity to `programs.agentTools` and docs without much migration benefit.
- **Alternatives considered**:
  - Keep `tokf` for one cycle — lower risk, but leaves the tool selection unclear.

### D4: Document the migration in existing architecture docs

- **Decision**: Update `ARCHITECTURE.md` and `STRUCTURE.md` instead of adding a new standalone document.
- **Rationale**: These files already describe package layout and agent tooling composition. Updating them keeps the repo's reference docs current without adding new documentation surface area.

## Risks / Trade-offs

- **[Risk]** Upstream `snip` moves faster than nixpkgs and may require future manual version bumps → **Mitigation**: keep it as a custom pinned package under `pkgs/`.
- **[Risk]** OpenCode plugin behavior could change independently of the CLI → **Mitigation**: rely on the small upstream plugin, keep the config change isolated, and validate that OpenCode still loads its plugin list.
- **[Trade-off]** Imperative plugin installation is less reproducible than a Nix package → **Mitigation**: preserve the current repo convention and document the plugin entry explicitly.
- **[Trade-off]** `snip` does not ship shell completions like `tokf` did → **Mitigation**: accept the loss for now because the primary workflow is transparent OpenCode integration, not direct shell-first usage.

## Migration Plan

1. Add a new `pkgs/snip` derivation and wire it into the flake overlay.
1. Replace `tokf` with `snip` in `programs.agentTools`.
1. Add `opencode-snip@latest` to the OpenCode plugin list.
1. Update architecture/structure docs and remove `pkgs/tokf`.
1. Verify `nix eval` and `nix build` for the Home Manager activation package.
1. If the build or plugin wiring regresses, roll back by restoring the `tokf` overlay entry/package and removing the `opencode-snip` plugin entry.

## Open Questions

1. Should `snip` eventually be switched back to nixpkgs once the packaged version catches up?
1. Do we want a follow-up to package `opencode-snip` declaratively, or is the imperative plugin model good enough long-term?
