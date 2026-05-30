## Why

Add persistent memory to AI coding agents (Hermes, OpenCode) via agentmemory — a local memory server that captures tool use, compresses observations, and injects relevant context across sessions. Solves the "re-explain the whole project" problem without external services (SQLite + local vector index).

## What Changes

- **New package**: `pkgs/iii-engine` — fetch prebuilt static Rust binary from GitHub releases
- **New package**: `pkgs/agentmemory` — buildNpmPackage for `@agentmemory/agentmemory` on npm
- **New module**: `modules/home/agents/agentmemory.nix` — programs.agentmemory with systemd user service, state dir, env/secrets, ports
- **Host config**: Enable on `arch` host in `hosts/arch/home.nix`
- **Hermes integration**: Wire agentmemory MCP server into hermes-agent config.yaml
- **OpenCode integration** (future): Add MCP entry to imperative `raw/opencode/opencode.jsonc`

## Capabilities

### New Capabilities

- `engine-package`: Nix derivation for `iii-hq/iii` v0.11.2 static Rust binary from GitHub releases
- `agent-package`: Nix derivation for `@agentmemory/agentmemory` via buildNpmPackage, wrapped with iii-engine on PATH
- `agent-service`: Home Manager module `programs.agentmemory` — enable flag, systemd user service, state directory (`~/.agentmemory`), env/secrets wiring, port config
- `hermes-integration`: Hermes MCP server config pointing at agentmemory daemon, plus optional hook scripts

### Modified Capabilities

- *(none — no existing specs are changing)*

## Impact

| Area | Affected |
|------|----------|
| Packages | New: `pkgs/iii-engine`, `pkgs/agentmemory` |
| Modules | New: `modules/home/agents/agentmemory.nix` |
| Flake | New flake input for `iii-engine` fetch? Or inline fetchurl in derivation |
| Host | `hosts/arch/home.nix`: enable `programs.agentmemory` |
| Hermes | `modules/home/agents/hermes.nix` or host: wire agentmemory MCP |
| OpenCode | Future: `raw/opencode/opencode.jsonc` MCP entry |
| Secrets | LLM API keys for compression: Anthropic/OpenAI/Gemini via sops |
| Licensing | `iii-engine` is ELv2 — fine for personal overlay, blocks nixpkgs |
| Ports | 3111 (REST), 3113 (viewer UI) — bind to 127.0.0.1 |
| Systemd | New user service: `agentmemory` |
