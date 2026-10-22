# Desktop shell

## Monique is the sole monitor authority

**Id:** 22d417d6-877f-4173-917d-8a4bcca65e74
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

Niri's store-linked config includes Monique-owned runtime state, and Home Manager defines no inline output blocks. Hotplug handling is therefore never split between config layers.

**Alternatives:** unknown.
**Reason:** stated in the source as: so hotplug handling is never split between config layers.

## Niri config is store-linked

**Id:** e4316e06-7ff3-4bc8-abb7-5e01e56f35c7
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

The compositor boots from a read-only store path, which makes the desktop session fully declarative.

**Alternatives:** unknown.
**Reason:** stated in the source as: making the desktop session fully declarative.

## Noctalia GUI state is runtime state

**Id:** 6a52c81f-7af8-4d84-a9e7-d8dcfe690a3c
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

The shell owns its mutable settings outside the store. Treat them as machine-local, not as declarative configuration.

**Alternatives:** unknown.
**Reason:** unknown.

## Noctalia themes through its own template entries, declared locally

**Id:** cf6cf7bd-4a40-46fc-855b-389077a0eb26
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

`theme.templates.enable_builtin_templates` and `enable_community_templates` are off. Every template entry is a row in `modules/desktop/noctalia.nix`. A row names a store path input (the noctalia package for builtins, the pinned `community-templates` flake input for the rest), an output path, and a hook only where Nix cannot point the consuming application at the rendered file.

**Alternatives:** enabling the upstream template ids and bending the Nix config around their hooks. Rejected: hooks that rewrite store-linked configs fail, and a Nix-owned file cannot be a template's output.
**Reason:** the local rows keep every output path under Nix's control and need hooks only where the consumer cannot be pointed at the file.

## Vicinae and Noctalia module inputs follow the nixpkgs package version

**Id:** bbf03942-ef19-49c3-ad5c-d0bcad0356c3
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `modules/desktop/vicinae.nix`, `modules/desktop/noctalia.nix`, `renovate.json`; `pkgs.vicinae.version` 0.29.1 and `pkgs.noctalia.version` 5.3.0 at nixpkgs `fe132422`

Both inputs supply only the Home Manager module — `package = pkgs.vicinae` and `package = pkgs.noctalia` supply the build. They are pinned to the release tag that matches the installed package (`v0.29.1`, `v5.3.0`) rather than following the default branch, and the nix manager is disabled for them in Renovate.

**Alternatives:** follow the default branch, which is what the declarations did before: upstream commits daily, so the module runs ahead of the package and can address options the installed version does not have. Pin to the latest release, which drifts immediately — vicinae's `v0.29.2` was already newer than the packaged `0.29.1`.
**Reason:** a module and a binary that disagree about their own option surface fail quietly, at runtime, in the desktop session rather than at build time.
**Revisit when:** `pkgs.vicinae.version` or `pkgs.noctalia.version` moves, which is the signal to move the pin with it; or the package starts being built from the input rather than nixpkgs, which brings churn into a build and changes the reason to pin.
