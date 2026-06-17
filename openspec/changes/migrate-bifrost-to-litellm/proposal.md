## Why

The current local LLM gateway is built on Bifrost, which is sufficient for static alias-and-fallback routing but is a poor fit for the more programmable routing policy the repo is moving toward. Migrating to LiteLLM gets the repo onto a better-supported OpenAI-compatible proxy with built-in model-group routing, simpler parity configuration for today, and a clear path to custom Python routing, middleware, and quota-aware policy later.

## What Changes

- **Gateway migration**: replace the Home Manager Bifrost user service with a LiteLLM proxy service while preserving the current localhost gateway role
- **Native LiteLLM routing config**: define the existing `coder`, `main`, `summariser`, `budget`, `explorer`, and `embedding` aliases in a LiteLLM-native declarative schema with explicit provider-aware deployments and fallbacks
- **Downstream integration update**: switch OpenCode, aichat, agentmemory, and related local clients from Bifrost-generated provider config to LiteLLM-generated provider config
- **Secrets + runtime wiring**: replace the Bifrost runtime env template and config generation with LiteLLM equivalents using the existing sops-nix pattern
- **Global Headroom middleware**: optionally augment the LiteLLM runtime with globally enabled Headroom ASGI middleware for request compression on this coding machine
- **Cleanup**: remove or retire Bifrost-specific module/config paths once LiteLLM parity is verified

## Capabilities

### New Capabilities
- `litellm-gateway`: Provide a declarative LiteLLM Home Manager gateway service with generated config, sops-managed runtime secrets, stable localhost access, and optional global Headroom ASGI middleware support
- `litellm-model-routing`: Generate LiteLLM model-group and fallback configuration from a LiteLLM-native alias/deployment schema while preserving the current logical model behavior at parity
- `litellm-client-integration`: Expose LiteLLM to OpenCode and local AI clients through generated provider/client config while preserving existing logical model names and converging downstream naming on `litellm`

### Modified Capabilities
- *(none — no existing spec capabilities are being modified)*

## Impact

| Area | Affected |
|------|----------|
| Home Manager agents | Replace `modules/home/agents/bifrost/*` service/config generation with LiteLLM equivalents |
| Secrets | Replace `bifrost.env` runtime template with LiteLLM runtime env/config wiring in `modules/home/sops.nix` |
| OpenCode integration | Update `modules/home/opencode.nix` generated provider overlay to target LiteLLM and use LiteLLM-native provider naming |
| Local AI clients | Update `hosts/arch/home.nix` wiring for aichat, agentmemory, and any other localhost gateway consumers |
| Gateway runtime | Replace Bifrost process management with LiteLLM proxy startup and restart behavior |
| Cleanup | Remove or retire stale Bifrost-specific config/docs after parity migration |
