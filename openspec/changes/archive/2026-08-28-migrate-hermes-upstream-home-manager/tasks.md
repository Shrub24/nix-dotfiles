## 1. Upstream dependency

- [x] 1.1 Update the `hermes-agent` flake input and remove the obsolete `hermes-agent-src` fork.
  - refs: `flake.nix`, `flake.lock`
  - criteria: the lock resolves upstream Hermes at or after the Home Manager module merge; no `hermes-agent-src` reference remains.
  - verify: `nix flake metadata --no-write-lock-file`

## 2. Home Manager migration

- [x] 2.1 Import upstream's Home Manager module and move Hermes service configuration to `services.hermes-agent`.

  - refs: `modules/agents/hermes.nix`, `specs/agent-core/spec.md`
  - criteria: existing SOPS environment, LiteLLM settings, and conditional Docs MCP/QMD servers are preserved.

- [x] 2.2 Enable Hermes' service and CLI through their respective upstream option namespaces.

  - refs: `modules/hosts/arch/_home.nix`
  - criteria: the host enables both `services.hermes-agent` and `programs.hermes-agent` without a local compatibility wrapper.

## 3. Review

- [x] 3.1 Conduct a high-level static review and validate the OpenSpec change.
  - refs: `openspec/specs/repository-validation/spec.md`
  - notes: Nix evaluation, builds, and tests are intentionally skipped at user direction.
  - verify: `openspec validate --strict`
