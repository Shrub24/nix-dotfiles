## 1. LiteLLM Module And Runtime Setup

- [x] 1.1 Create `modules/home/agents/litellm/default.nix` with `programs.litellm` options, generated config rendering, and a Home Manager-managed `systemd.user.services.litellm`
- [x] 1.2 Import the new LiteLLM module from `modules/home/agents/default.nix`
- [x] 1.3 Add a LiteLLM runtime env template to `modules/home/sops.nix` using the existing provider secret placeholders

## 2. Generated Routing And Provider Config

- [x] 2.1 Add LiteLLM config generation that reuses the current alias/provider source of truth to produce parity model entries and fallbacks
- [x] 2.2 Update `modules/home/opencode.nix` to generate an OpenCode provider overlay targeting the LiteLLM gateway
- [x] 2.3 Decide and apply the phase-1 downstream provider naming (`bifrost` compatibility label vs `litellm` label) consistently across generated config
- [x] 2.4 Replace the temporary Bifrost-shaped routing input with a LiteLLM-native declarative alias/deployment schema under `modules/home/agents/litellm/`
- [x] 2.5 Regenerate LiteLLM model entries and fallbacks with explicit provider-qualified deployment semantics for custom OpenAI-compatible upstreams
- [x] 2.6 Rename generated downstream provider/client naming from the temporary `bifrost` compatibility label to `litellm`

## 3. Host Wiring And Bifrost Retirement

- [x] 3.1 Update `hosts/arch/home.nix` so the host enables LiteLLM and points aichat plus other localhost gateway consumers at the LiteLLM-backed endpoint
- [x] 3.2 Update agentmemory and any other declarative local clients that currently depend on Bifrost-specific gateway wiring
- [x] 3.3 Disable or remove Bifrost-specific service/runtime wiring once LiteLLM parity wiring is in place
- [x] 3.4 Update declarative downstream clients to use LiteLLM-native provider naming where required while preserving the localhost endpoint contract

## 4. Global Headroom Middleware

- [x] 4.1 Add a Headroom-enabled LiteLLM runtime package path that the LiteLLM module can select declaratively
- [x] 4.2 Extend `modules/home/agents/litellm/default.nix` with a global Headroom enable option and package selection/wiring
- [x] 4.3 Replace the callback-based Headroom proxy integration with a LiteLLM ASGI middleware launcher when enabled
- [x] 4.4 Enable global Headroom for the host-level LiteLLM gateway on this coding machine

## 5. Verification And Cleanup

- [x] 5.1 Verify `nix eval .#homeConfigurations.saurabhj.activationPackage.drvPath`
- [x] 5.2 Verify `nix build .#homeConfigurations.saurabhj.activationPackage --no-link`
- [x] 5.3 Verify the generated LiteLLM config, env template, and OpenCode provider overlay render to the expected paths and values
- [x] 5.4 Verify parity aliases (`coder`, `main`, `summariser`, `budget`, `explorer`, `embedding`) resolve through LiteLLM as expected
