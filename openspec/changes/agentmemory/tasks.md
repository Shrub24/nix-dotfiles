## 1. iii-engine Package (`pkgs/iii-engine`)

- [ ] 1.1 Create `pkgs/iii-engine/default.nix` — fetch prebuilt static binary from GitHub releases (v0.11.2, musl, x86_64-linux)
- [ ] 1.2 Set fixed-output derivation hash via `fetchurl` with verified sha256
- [ ] 1.3 Add `version` passthru, meta.license (ELv2), meta.platforms
- [ ] 1.4 Register in flake overlay (`final.callPackage ./pkgs/iii-engine { }`)

## 2. agentmemory Package (`pkgs/agentmemory`)

- [ ] 2.1 Create `pkgs/agentmemory/default.nix` — `buildNpmPackage` from GitHub source
- [ ] 2.2 Set `npmDepsHash` via `importNpmLock` or `npmDeps` with correct lockfile resolution
- [ ] 2.3 Add `buildPhase` — runs `tsdown` (already in build script), copies iii-config.yaml, docker-compose.yml, viewer/index.html to dist/
- [ ] 2.4 Add `installPhase` — installs dist/ to lib/node_modules/agentmemory, creates bin/agentmemory symlink
- [ ] 2.5 Wrap binary with `--prefix PATH : ${iii-engine}/bin` for engine discovery
- [ ] 2.6 Add meta with source URL, license (Apache-2.0 for agentmemory itself), platforms
- [ ] 2.7 Register in flake overlay

## 3. agentmemory HM Module (`modules/home/agents/agentmemory.nix`)

- [ ] 3.1 Create module with `programs.agentmemory` option tree:
  - `enable` (bool)
  - `package` (package, default from pkgs)
  - `enginePackage` (package, default from pkgs)
  - `enableGateway` (bool, default true)
  - `settings` (freeform attrs → AGENTMEMORY_* env vars)
  - `environment` (attrset)
  - `environmentFile` (nullable path)
- [ ] 3.2 Implement settings-to-env-vars translation (uppercase, AGENTMEMORY_ prefix, III_ prefix for port vars)
- [ ] 3.3 Add `systemd.user.services.agentmemory` — ExecStart, Restart=on-failure, RestartSec=5s, environment, environmentFile
- [ ] 3.4 Ensure `~/.agentmemory/` state directory exists (systemd StateDirectory or mkdir in service)
- [ ] 3.5 Import module in `modules/home/agents/default.nix`

## 4. Host Config + Secrets

- [ ] 4.1 Enable `programs.agentmemory` in `hosts/arch/home.nix`
- [ ] 4.2 Wire secrets (Anthropic/OpenAI/Gemini API keys) via sops-nix `environmentFile` if needed
- [ ] 4.3 Configure initial settings (injectContext, embedOnSave, etc.)

## 5. Hermes Integration

- [ ] 5.1 Add agentmemory MCP server entry to hermes-agent config (`mcpServers.agentmemory.url = "http://localhost:3111/mcp"`)
- [ ] 5.2 Configure in host — either via `programs.hermes-agent` options or imperative hermes config.yaml edit
- [ ] 5.3 (Optional) Deploy Hermes integration hook scripts from agentmemory's `integrations/hermes/` to `~/.hermes/hooks/`

## Notes

- **nix-init**: User may run `nix-init` interactively to bootstrap base derivations for `pkgs/iii-engine` and `pkgs/agentmemory`. If so, review and adjust the generated output to match the spec requirements above.
- **iii-engine release URL format**: `https://github.com/iii-hq/iii/releases/download/iii/v{VERSION}/iii-{TARGET}.tar.gz` with `{TARGET}=x86_64-unknown-linux-gnu` (musl, fully static)
- **agentmemory GitHub release/versions**: Check latest tag from `https://github.com/rohitg00/agentmemory/tags` — must be compatible with iii-engine v0.11.2
