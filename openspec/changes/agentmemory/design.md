## Context

agentmemory is a persistent memory server for AI coding agents. It consists of two components:
- **iii-engine**: Rust binary (ELv2 licensed) — runs as a background daemon providing WebSocket-based KV state, vector search, and worker orchestration
- **@agentmemory/agentmemory**: npm package (TypeScript) — the CLI/MCP layer that connects to iii-engine, manages observations, compression, injection, and the viewer UI

The engine is distributed as a prebuilt static binary from GitHub releases. The npm package has no native build steps (tsdown bundler) and no postinstall scripts. They communicate over WebSocket on localhost:49134.

This repo follows a dendritic Nix structure: `pkgs/` for derivations, `modules/home/agents/` for agent modules, `hosts/arch/home.nix` for host composition.

## Goals / Non-Goals

**Goals:**
- Package both iii-engine and agentmemory as Nix derivations under `pkgs/`
- Create a `programs.agentmemory` Home Manager module with systemd user service
- Wire agentmemory as an MCP server into Hermes configuration
- Enable on the `arch` host
- Manage secrets (LLM API keys) via sops-nix

**Non-Goals:**
- OpenCode integration (future, imperative config)
- Full Rust source build of iii-engine (use prebuilt release tarballs)
- nixpkgs upstreaming (ELv2 blocks it)
- Multi-agent or team memory setup
- Docker/Podman deployment

## Decisions

### D1: Fetch iii-engine from release tarballs vs source build
- **Decision**: Fetch prebuilt static binary from GitHub releases
- **Rationale**: The engine is a monorepo with Rust workspace, React frontend, and Python SDK. Full source build needs Rust 1.85+, pnpm, and libcap-ng. The release tarballs are fully static musl binaries — trivial to `fetchurl` + `installPhase`
- **Alternatives considered**: Source build via `craneLib` — more pure but more maintenance burden for a binary that's already statically compiled

### D2: buildNpmPackage vs bun-based wrapper for agentmemory
- **Decision**: `buildNpmPackage` from GitHub source
- **Rationale**: The npm package is unusually clean — no postinstall, no native addons, no node-gyp. Standard `buildNpmPackage` with `npmDepsHash` works directly. The derivation wraps the binary to add iii-engine to PATH
- **Alternatives considered**: Bun systemd service (`bun x @agentmemory/agentmemory`) — simpler but impure, version-drifts over time, and doesn't compose with the module's declarative package option

### D3: Wrapping the agentmemory binary with iii-engine
- **Decision**: Wire via `wrapProgram` — `--prefix PATH : ${iii-engine}/bin`
- **Rationale**: agentmemory spawns iii-engine as a child process and discovers it via PATH lookup. No hardcoded paths in the npm source. PATH wrapping is the lightest-touch integration
- **Alternatives considered**: Symlinking in postInstall, patching the JS source — both more invasive

### D4: Module shape — standalone vs merged into existing agent modules
- **Decision**: Standalone `programs.agentmemory` in `modules/home/agents/agentmemory.nix`
- **Rationale**: agentmemory is a stateful daemon with its own service lifecycle, state dir, env/secrets, and port config. Merging into `tools.nix` (which is for stateless CLI binaries) would conflate concerns. A standalone module is cleaner dendritic practice
- **Alternatives considered**: Adding to `tools.nix` + external service file

### D5: Hermes integration — MCP config only vs hooks
- **Decision**: MCP server entry only initially
- **Rationale**: agentmemory's Hermes `integrations/hermes/` provides both an MCP config and optional hook scripts. The MCP config (pointing at `http://localhost:3111/mcp`) is zero-build and trivially reversible. The hooks add observation capture on every tool call — can be added in a follow-up once the base works
- **Alternatives considered**: Both at once — risks conflating debugging surface

### D6: Secrets management
- **Decision**: Module exposes `environment` and `environmentFile` options matching the Hermes pattern. Host config wires sops secrets for API keys
- **Rationale**: Consistent with existing `programs.hermes` pattern. API keys are read at service start, not at build time
- **Alternatives considered**: Hardcoding in module, passthru from host — both worse for security

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| **Version coupling**: agentmemory and iii-engine versions are coupled (`docker-compose.yml` pins v0.11.2, warns v0.11.6 breaks protocol) | Pin both to the same version pair in the module. Document the upgrade dance |
| **ELv2 license drift**: License change could complicate future use | Personal overlay is unaffected, but document the license limitation |
| **Port conflicts**: 3111 (REST), 3113 (viewer UI) must be free | Default to 127.0.0.1 only. Module should allow port overrides via `settings` |
| **iii-engine release binary not updated**: Repo moves to new version, old binary disappears from releases | Use a specific tag (v0.11.2) not a moving `latest`. Add a `version` passthru for easy bumps |
| **Runtime download of embedding models**: `@xenova/transformers` downloads ~80MB model on first inference | Document that local embeddings download to state dir at first use. Not a build-time concern |
