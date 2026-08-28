## Why

The temporary `hermes-agent-src` fork is pinned to a no-longer-available commit, blocking flake evaluation. Upstream Hermes Agent now ships the Home Manager module this repository needs, so the fork is redundant.

## What Changes

- Remove the `hermes-agent-src` flake input and update the upstream `hermes-agent` lock entry past the Home Manager module merge.
- Import `inputs.hermes-agent.homeManagerModules.default` directly.
- Move Hermes configuration and service enablement from the former fork-specific `programs.hermes-agent` schema to upstream `services.hermes-agent`; retain upstream's `programs.hermes-agent` only for CLI installation.
- Preserve the existing LiteLLM configuration, SOPS environment file, and Docs MCP/QMD server registrations.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-core`: Hermes Agent is configured through its upstream Home Manager module rather than its NixOS module or a fork-specific Home Manager schema.

## Impact

- Affects `flake.nix`, `flake.lock`, `modules/agents/hermes.nix`, and the host Hermes enablement in `modules/hosts/arch/_home.nix`.
- Removes the unavailable `github:yzx9/hermes-agent/feat/home-manager` dependency.
- Requires network access to update the upstream flake input; normal validation remains subject to Hermes' PyPI build dependency.
