## Context

This repo currently uses a Home Manager-managed Bifrost user service as the local OpenAI-compatible gateway at `http://localhost:8765/v1`. Bifrost configuration is generated from `modules/home/agents/bifrost/aliases.nix` and `generated.nix`, then consumed by multiple downstream clients: OpenCode provider overlay generation, aichat, agentmemory, and other local tooling.

The migration target is LiteLLM, but the immediate goal is not custom routing. The immediate goal is parity: preserve the local gateway role, preserve the current logical model names and fallbacks, preserve the sops-managed secret flow, and minimize churn for downstream clients. The current first-cut implementation proved that simply reshaping the old Bifrost alias tree is not sufficient: LiteLLM requires explicit provider-aware deployment semantics, especially for custom OpenAI-compatible endpoints. Custom routing hooks and quota-aware policy remain follow-up work, but a simple global Headroom ASGI middleware layer is now in scope as a gateway-wide enhancement for this coding machine.

## Goals / Non-Goals

**Goals:**

- Replace the Bifrost user service with a LiteLLM proxy service managed declaratively through Home Manager
- Preserve the localhost gateway contract during the first migration phase, including current logical aliases where practical
- Generate LiteLLM config from repo-managed Nix data rather than handwritten mutable YAML
- Reuse the existing provider secrets and sops template pattern for runtime API keys
- Update OpenCode and local clients so they can continue using the local gateway with minimal behavioral drift
- Leave the repo in a state where a later custom routing hook can be added without another structural rewrite

**Non-Goals:**

- Implementing custom Python routing hooks in phase 1
- Introducing Redis, distributed state, or multi-worker coordination in phase 1
- Designing quota-aware provider switching policy in this change
- Adding per-alias or policy-aware middleware selection in this change
- Preserving Bifrost as a parallel runtime long-term after parity is verified

## Decisions

### D1: Introduce LiteLLM as a new Home Manager agent module

- **Decision**: Add a new `modules/home/agents/litellm/` module rather than overloading the existing Bifrost module in place.
- **Rationale**: The service runtime, generated config format, and future extension surface are materially different. A dedicated module keeps the implementation clearer and reduces migration risk while still allowing a staged cutover.
- **Alternatives considered**:
  - Mutate `programs.bifrost` into a LiteLLM-backed module — lower short-term churn, but misleading and harder to maintain.
  - Run LiteLLM imperatively outside Home Manager — faster to prototype, but not declarative.

### D2: Preserve the local gateway contract in phase 1 while normalizing downstream naming

- **Decision**: Keep the first migration focused on parity by preserving the local gateway role and logical model names, while converging generated downstream provider naming on `litellm` instead of carrying forward the temporary `bifrost` compatibility label.
- **Rationale**: OpenCode, aichat, and agentmemory already depend on the local proxy contract. Keeping that contract stable shrinks the blast radius and makes it easier to validate parity before introducing smarter routing.
- **Alternatives considered**:
  - Keep the `bifrost` label indefinitely for compatibility — lower short-term churn, but misleading and already causing confusion during debugging.
  - Redesign model names during the migration — unnecessary churn for a parity-first phase.

### D3: Generate LiteLLM model configuration from a LiteLLM-native declarative schema

- **Decision**: Keep the current logical aliases, but move the generated config input into a LiteLLM-native schema that explicitly models deployments, provider semantics, and fallback model groups instead of reusing the old Bifrost-shaped alias tree.
- **Rationale**: The current alias map captures the user-facing contract, but not the provider semantics LiteLLM needs to instantiate deployments correctly. A LiteLLM-native schema keeps the declarative source of truth in-repo while avoiding Bifrost-specific assumptions.
- **Alternatives considered**:
  - Continue reusing `modules/home/agents/bifrost/aliases.nix` — simplest mechanically, but already produced invalid LiteLLM deployment definitions.
  - Handwrite LiteLLM YAML — simpler initially, but drifts from the repo's generated-config convention.

### D4: Keep routing policy simple, but allow global Headroom ASGI middleware in the gateway runtime

- **Decision**: Use built-in LiteLLM routing/fallback behavior only for routing, while allowing an optional global Headroom ASGI middleware layer to wrap the LiteLLM proxy app.
- **Rationale**: The user wants a simple, coding-machine-wide compression middleware without introducing per-alias middleware policy or custom routing code. Headroom's ASGI integration matches its documented proxy-mode shape better than the proxy callback path and avoids callback interface mismatches.
- **Alternatives considered**:
  - Defer Headroom entirely — simpler, but misses a low-complexity global optimization the user wants immediately.
  - Add per-alias middleware policy now — more flexible, but unnecessary complexity for the current single-user setup.
  - Add Redis now to prepare for budgets — premature for a single-user parity migration.

### D5: Keep secrets in sops-managed env templates and generated config in XDG paths

- **Decision**: Follow the existing repo pattern: render provider secrets into a LiteLLM-specific env file via `modules/home/sops.nix`, and render the LiteLLM config into `~/.config/litellm/config.yaml` with Home Manager.
- **Rationale**: This matches current conventions used by Bifrost and other agent services, keeps secrets out of the generated config file, and allows clean systemd `EnvironmentFile` wiring.
- **Alternatives considered**:
  - Inline secrets into config YAML — simpler, but not acceptable for repo-managed declarative config.
  - Use imperative local config files outside Home Manager — inconsistent with repo conventions.

## Risks / Trade-offs

- **[Risk]** LiteLLM built-in routing may not perfectly match Bifrost's current fallback semantics → **Mitigation**: scope phase 1 to the current aliases only, generate deterministic config from the existing alias map, and validate each logical model path before removing Bifrost.
- **[Risk]** Downstream consumers may depend on small Bifrost-specific quirks beyond plain OpenAI-compatible behavior → **Mitigation**: preserve localhost gateway usage and logical model names first, then update individual clients only where required.
- **[Trade-off]** Converging downstream provider naming on `litellm` now adds a small amount of client config churn → **Mitigation**: keep logical model names stable and keep the localhost endpoint unchanged so the only churn is provider labeling.
- **[Trade-off]** Deferring custom routing means phase 1 does not deliver quota-aware behavior yet → **Mitigation**: explicitly design the module and generated config so a later hook package and routing policy can be layered on without replacing the service again.
- **[Trade-off]** Global Headroom enablement applies broadly rather than selectively by alias → **Mitigation**: keep it behind a single module option and defer per-alias policy until there is evidence it is needed.

## Migration Plan

1. Add a new LiteLLM Home Manager module plus generated config logic.
1. Add a LiteLLM runtime env template in `modules/home/sops.nix` and wire the user service to it.
1. Define a LiteLLM-native declarative alias/deployment schema and generate provider-aware deployments plus fallback model groups from it.
1. Update OpenCode provider overlay generation and host-level client configuration to consume the LiteLLM gateway under LiteLLM-native naming.
1. Add optional global Headroom ASGI middleware support to the LiteLLM runtime.
1. Validate Home Manager evaluation/build and verify each parity alias resolves through LiteLLM.
1. Disable or remove Bifrost-specific service/config wiring once parity is confirmed.
1. If parity validation fails, roll back by re-enabling the current Bifrost service/module and restoring the previous generated provider/client wiring.

## Open Questions

1. Do any current consumers rely on Bifrost-specific response/model-list behavior that should be captured as explicit parity checks before implementation?
1. Should the future custom routing hook live as a separate package/module from the start, even if phase 1 does not enable it yet?
