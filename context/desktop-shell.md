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
