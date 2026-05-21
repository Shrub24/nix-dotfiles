## 1. Flake Input

- [x] 1.1 Add `hermes-agent.url = "github:NousResearch/hermes-agent"` to `flake.nix` inputs
- [x] 1.2 Pass hermes package to home-manager via `extraSpecialArgs` or inline in module
- [x] 1.3 Run `nix flake lock` to pin the hermes-agent input

## 2. Home-Manager Module Skeleton

- [x] 2.1 Create `home/modules/hermes.nix` with `{ config, lib, pkgs, inputs, ... }:` pattern
- [x] 2.2 Define `options.programs.hermes.enable` with `mkEnableOption`
- [x] 2.3 Define `options.programs.hermes.package` defaulting to hermes-agent from flake
- [x] 2.4 Define `options.programs.hermes.settings` as freeform attrs (rendered as config.yaml)
- [x] 2.5 Define `options.programs.hermes.mcpServers` as attrs (merged into settings.mcp_servers)
- [x] 2.6 Define `options.programs.hermes.environment` as attrsOf str (non-secret env vars)
- [x] 2.7 Define `options.programs.hermes.environmentFiles` as listOf str (secret file paths)
- [x] 2.8 Define `options.programs.hermes.documents` as attrsOf str (workspace files)
- [x] 2.9 Define `options.programs.hermes.enableGateway` for systemd user service
- [x] 2.10 Add import of `hermes.nix` to `home/default.nix`

## 3. Config Rendering

- [x] 3.1 Implement `home.file.".hermes/config.yaml"` rendering from `settings` attrset
- [x] 3.2 Implement `home.file.".hermes/.env"` rendering from `environment` + `environmentFiles`
- [x] 3.3 Implement `home.file` for each document in `documents` attrset
- [x] 3.4 Add hermes package to `home.packages`

## 4. MCP Servers (mirror pi config)

- [x] 4.1 Configure context7 MCP server (stdio, pnpx)
- [x] 4.2 Configure desktop-commander MCP server (stdio, pnpx)
- [x] 4.3 Configure jina-reader MCP server (HTTP, auth header)
- [x] 4.4 Configure github MCP server (HTTP, auth header)
- [x] 4.5 Configure semgrep MCP server (stdio)
- [x] 4.6 Configure nixos MCP server (stdio, uvx)
- [x] 4.7 Configure markdownify MCP server (stdio, node)

## 5. Systemd User Service

- [x] 5.1 Implement `systemd.user.services.hermes-agent` (ExecStart = `hermes gateway`)
- [x] 5.2 Configure service environment (HOME, HERMES_HOME, MESSAGING_CWD)
- [x] 5.3 Configure service restart policy

## 6. Integration

- [x] 6.1 Add hermes config block to `home/default.nix` (enable, settings, mcpServers)
- [x] 6.2 Verify `home-manager build` evaluates without errors
- [ ] 6.3 Verify config files generated under `~/.hermes/`

**Note:** Build fails due to network issue (PyPI timeout downloading `tqdm`). Configuration is correct - hermes-agent derivation was resolved successfully. Re-run build when network access to PyPI is available.
