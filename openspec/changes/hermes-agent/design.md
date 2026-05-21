## Context

This repo is a home-manager flake (`homeConfigurations.saurabhj`). Hermes provides a NixOS module (`services.hermes-agent`) that uses system-level features (systemd system service, user creation, activation scripts). We can't use it directly, but the hermes package works fine standalone — we just need a thin home-manager wrapper.

The NixOS module does these things:
1. Creates user/group → not needed (home-manager = current user)
2. Creates directories → `home.file` or `home.activation`
3. Writes config.yaml → `home.file.".hermes/config.yaml"`
4. Writes .env → `home.file.".hermes/.env"` or sops-nix
5. Systemd service → `systemd.user.services.hermes-agent`
6. CLI to PATH → `home.packages`

## Goals / Non-Goals

**Goals:**
- Add hermes-agent as a flake input
- Create `home/modules/hermes.nix` mirroring NixOS module options
- Use `home.file` for config.yaml and .env
- Use `systemd.user.services` for optional gateway
- Use `home.packages` for CLI access
- Mirror MCP servers from existing `pi` config

**Non-Goals:**
- NixOS-specific features (user creation, tmpfiles, activation scripts)
- Container mode (requires Docker/Podman system integration)
- Adding `nixosConfigurations` to this flake

## Decisions

### 1. Home-manager module, dendritic-compatible

**Decision**: Create `home/modules/hermes.nix` as a home-manager module using `home.file` and `systemd.user.services`.

**Rationale**: This repo is home-manager-only. The NixOS module can't be used directly. A thin wrapper maps the same options to home-manager equivalents.

**Dendritic compatibility**: The module is feature-scoped (hermes only) and follows the same pattern as pi.nix. Config generation (options → config.yaml) is environment-agnostic; deployment (home.file) is home-manager-specific. In the future, the config generation logic could be extracted into a shared module for both NixOS and home-manager backends — consistent with the README's goal of "shared modules between nixos/ and home/".

### 2. Config rendering via home.file

**Decision**: Render `config.yaml` via `home.file.".hermes/config.yaml".text = builtins.toJSON cfg.settings`.

**Rationale**: Same pattern as `pi.nix`. Simple, declarative, no activation scripts needed.

### 3. Secrets via sops-nix home.file

**Decision**: Use `sops.secrets` with `home.file` to render `.env` to `~/.hermes/.env`.

**Rationale**: Sops-nix already configured in this repo. `home.file` with sops path is the standard pattern.

### 4. Systemd user service (optional)

**Decision**: Provide `systemd.user.services.hermes-agent` for running the gateway in the background.

**Rationale**: User-level systemd works without NixOS. Gateway mode provides persistent agent availability.

### 5. MCP servers mirror pi config

**Decision**: Same MCP server set as existing `pi` config: context7, desktop-commander, jina-reader, github, semgrep, nixos, markdownify.

**Rationale**: Consistency. User already uses these with pi.

## Risks / Trade-offs

- **[Risk]** hermes-agent flake breaking changes → **Mitigation**: Pin in flake.lock
- **[Risk]** Systemd user service may not be available on all systems → **Mitigation**: Make service optional via `enableGateway` option
- **[Trade-off]** No container mode → **Mitigation**: Acceptable for v1; can add later with Docker/Podman home-manager integration

## Open Questions

1. What model should be the default?
2. Should the gateway service be enabled by default or opt-in?
