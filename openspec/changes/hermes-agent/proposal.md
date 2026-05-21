## Why

The home-manager configuration has a coding agent (`pi`) but no general-purpose assistant. Hermes by NousResearch ships with a NixOS module (`services.hermes-agent`), but this repo is home-manager-only (no NixOS). The solution: a thin home-manager wrapper module (`home/modules/hermes.nix`) that maps the NixOS module's options to home-manager equivalents — `home.file` for configs, `systemd.user.services` for the gateway, `home.packages` for CLI access.

## What Changes

- **New flake input**: `hermes-agent.url = "github:NousResearch/hermes-agent"` in `flake.nix`
- **New module file**: `home/modules/hermes.nix` — home-manager module wrapping hermes-agent
- **Modified file**: `home/default.nix` — add import of `hermes.nix`
- **Sops integration**: API keys via sops-nix rendered to `~/.hermes/.env`

## Capabilities

### New Capabilities

- `flake-integration`: Add hermes-agent flake input, expose package to home-manager
- `hermes-module`: Home-manager module at `home/modules/hermes.nix` with typed options (settings, mcpServers, documents, environment)
- `mcp-setup`: Pre-configured MCP servers matching existing pi config
- `secrets-management`: Sops-nix integration for API keys via `~/.hermes/.env`

### Modified Capabilities

None — net-new integration.

## Impact

- **Modified file**: `flake.nix` — add hermes-agent input
- **New file**: `home/modules/hermes.nix` (~150-200 lines)
- **Modified file**: `home/default.nix` — add import + hermes config
- **Secrets**: API keys via sops-nix → `~/.hermes/.env`
- **User service**: `systemd.user.services.hermes-agent` (optional, for gateway mode)
