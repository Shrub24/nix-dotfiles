# Tasks — Native HM modules for Pi and Herdr

- [x] 1. Replace `modules/agents/pi.nix` hand-rolled `programs.pi` with native `programs.pi-coding-agent` thin package override to `inputs.llm-agents` Pi (keep `settings = {}` so `~/.pi/agent` stays mutable).

  - refs: `modules/agents/pi.nix`
  - criteria: no `options.programs.pi` definition remains; module sets `programs.pi-coding-agent.package = inputs.llm-agents.packages.${system}.pi`; relies on upstream HM `pi-coding-agent.nix` (`programs.pi-coding-agent.{enable,package,settings,keybindings,models,context,extraPackages}`).
  - verify: `nix flake check --no-build` eval passes; `pi.enable = false` no longer valid (now `pi-coding-agent.enable`).

- [x] 2. Add `modules/agents/herdr.nix` thin wrapper for native `programs.herdr` with package override to `inputs.llm-agents` Herdr, `settings = {}` (Herdr-managed plugins initially).

  - refs: `modules/agents/herdr.nix` (new)
  - criteria: `programs.herdr.package = inputs.llm-agents.packages.${system}.herdr`; `settings` left default `{}` so no `xdg.configFile."herdr/config.toml"` is emitted.
  - verify: module follows `hermes.nix` thin-wrapper pattern (no option definitions, just package override).

- [x] 3. Host wiring: add `"herdr"` to `hmAspects` in `modules/hosts/arch.nix`; set `programs.pi-coding-agent.enable = true` and `programs.herdr.enable = true` in `modules/hosts/arch/_home.nix` (replacing `pi.enable = false`).

  - refs: `modules/hosts/arch.nix:hmAspects`, `modules/hosts/arch/_home.nix:programs`
  - criteria: both agents enabled via native options; no `pi`/`herdr` aspect excluded from `embeddedHmAspects` (user-scoped only, no NixOS aspect).
  - verify: HM activation includes both packages; `~/.pi/agent/settings.json` not managed (mutable).

- [ ] 4. Validate: `nix fmt`, `nix flake check --no-build --no-write-lock-file`, `openspec validate --strict add-herdr-pi-native`.

  - criteria: statix/deadnix/nixfmt pass; HM + NixOS eval pass (including VM checks); strict validation passes.
