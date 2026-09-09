# pi-agent-skeleton

## Purpose

Adopts upstream Home Manager native modules for Pi (`programs.pi-coding-agent`) and Herdr (`programs.herdr`) with llm-agents package overrides while keeping configuration mutable during experimentation.

## MODIFIED Requirements

### Requirement: Pi is enabled via the native HM module

The system SHALL enable Pi through the native `programs.pi-coding-agent` Home Manager module with its package pinned to `inputs.llm-agents` (`~0.84.4`) and SHALL leave `settings`, `keybindings`, `models`, `context`, and `extraPackages` at defaults (`{}`/`[]`/`""`) so `~/.pi/agent/settings.json` and Pi-installed packages remain mutable. `~/.pi/agent` SHALL NOT be made HM-immutable; Nix SHALL manage only obvious invariants (global instructions, executable dependencies, keybindings) as they stabilise.

#### Scenario: Pi is enabled with llm-agents package and mutable settings

- **WHEN** the Arch Home Manager configuration is applied
- **THEN** `programs.pi-coding-agent.enable = true` with `programs.pi-coding-agent.package = inputs.llm-agents.packages.${system}.pi`
- **AND** Pi installs its package and `~/.pi/agent/settings.json` is not rendered by HM (remains mutable)

#### Scenario: Nix does not make Pi configuration immutable

- **WHEN** the HM config is inspected with Pi enabled and defaults
- **THEN** `~/.pi/agent/settings.json` is not managed
- **AND** Pi can mutate its own configuration at runtime

## ADDED Requirements

### Requirement: Herdr is enabled via the native HM module

The system SHALL enable Herdr through the native `programs.herdr` Home Manager module with its package pinned to `inputs.llm-agents` (`herdr` 0.8.2) and `settings = {}` so `xdg.configFile."herdr/config.toml"` is not emitted and plugins/integrations remain Herdr-managed. Stable settings/plugins are promoted to Nix gradually.

#### Scenario: Herdr is enabled with llm-agents package and Herdr-managed config

- **WHEN** the Arch Home Manager configuration is applied
- **THEN** `programs.herdr.enable = true` with `programs.herdr.package = inputs.llm-agents.packages.${system}.herdr` and `programs.herdr.settings = {}`

### Requirement: Pi and Herdr aspect wiring

`modules/hosts/arch.nix` SHALL include both `"pi"` and `"herdr"` in `hmAspects`; `modules/hosts/arch/_home.nix` SHALL set `programs.pi-coding-agent.enable = true` and `programs.herdr.enable = true`. No system-manager/NixOS aspects are added.

#### Scenario: Host composition enables both agents

- **WHEN** `hmAspects` and `_home.nix` are inspected
- **THEN** both agents appear enabled and their packages resolve from `inputs.llm-agents`
