## Context

See proposal.md for motivation. The current configuration imports a temporary, non-flake fork to obtain a Home Manager module and configures it through `programs.hermes-agent`. That fork's locked revision is unavailable. Upstream Hermes Agent now exposes an equivalent Home Manager module, but its shared configuration and daemon options belong to `services.hermes-agent`; `programs.hermes-agent` only owns CLI installation.

## Goals / Non-Goals

**Goals:**

- Use the upstream Home Manager module directly and remove the obsolete fork input.
- Preserve current runtime behavior: LiteLLM provider, SOPS environment file, and conditional Docs MCP/QMD registrations.
- Keep service and CLI enablement explicit at host composition.

**Non-Goals:**

- Change Hermes settings, models, secrets, or MCP topology.
- Add a local compatibility wrapper or NixOS-specific Hermes configuration.
- Update unrelated flake inputs.

## Decisions

### Import the upstream Home Manager module directly

Import `inputs.hermes-agent.homeManagerModules.default` after updating the existing upstream input. This replaces the unavailable fork and its non-flake import workaround. A local wrapper is rejected because upstream's module provides the required option set and lifecycle management.

### Split daemon configuration from CLI installation

Move `settings`, `environmentFiles`, `mcpServers`, and package selection to `services.hermes-agent`. Keep `programs.hermes-agent.enable` solely for the user-profile CLI, and explicitly enable both upstream option groups in the host configuration. This follows the upstream ownership boundary instead of preserving the fork's overloaded `programs` schema.

### Preserve service-owned secrets and conditional MCP registration

Keep `hermes.env` in the Hermes feature module and continue to reference the runtime SOPS template path. Retain the current conditional contributions for Docs MCP and QMD. This preserves the secrets ownership model and prevents configuration churn.

## Risks / Trade-offs

- [The upstream schema may have changed since the PR merge] → Update the single upstream input first, then evaluate the resulting Home Manager options before applying the migration.
- [Hermes package builds require PyPI access] → Run evaluation first; report any build-only network failure separately from configuration correctness.
- [A service/CLI split could omit one capability] → Enable and evaluate both `services.hermes-agent` and `programs.hermes-agent` at the host layer.

## Migration Plan

1. Update the upstream `hermes-agent` input and remove `hermes-agent-src`.
1. Move the feature configuration to the upstream namespaces and update host enablement.
1. Conduct a high-level static review and strictly validate the OpenSpec change. Nix evaluation, builds, and tests are intentionally skipped at user direction.
1. Roll back by restoring the prior lock file and module configuration; no runtime data migration is required.
