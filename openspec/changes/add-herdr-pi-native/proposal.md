# Proposal: Native HM modules for Pi (pi-coding-agent) and Herdr

## Summary

Adopt upstream Home Manager modules `programs.pi-coding-agent` and `programs.herdr` for the two agents. Packages come from `inputs.llm-agents` (herdr 0.8.2, pi ~0.84.4) for integration assets. Settings stay Herdr/Pi-managed while experimenting (`settings = {}`); promote to Nix gradually. Don't make `~/.pi/agent` immutable.

## Motivation

Hand-rolled `programs.pi` predates the native HM module and pins an old `pkgs.pi` default. Upstream HM now ships `pi-coding-agent.nix` and `herdr.nix` with proper `settings`/`keybindings`/`context`/`extraPackages` coverage. Using the native modules removes drift and aligns with the hermes upstream-migration pattern.

## Scope

- Replace `modules/agents/pi.nix` hand-rolled options with a thin `programs.pi-coding-agent.package` override to `llm-agents Pi`.
- Add `modules/agents/herdr.nix` thin `programs.herdr.package` override to `llm-agents Herdr`.
- Host wiring in `modules/hosts/arch.nix` (`hmAspects`) and `modules/hosts/arch/_home.nix` (`enable`).
- Spec delta for `pi-agent-skeleton` (disabled-skeleton → native-module enabled).

No secrets, no system-manager/NixOS aspects.
