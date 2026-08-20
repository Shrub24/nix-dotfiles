# Tasks — Add Muse Spark 1.2 via the LA OpenCode-Go Relay

## Group A — Relay-routed model entry (executable in this change)

- [x] `A1.` In `modules/agents/litellm/_aliases.nix`, add the `opencode-go-relay`
  upstream to `upstreams`:
  `providerFamily = "openai"; apiBase = "http://la-admin-1.tail0fe19b.ts.net:8787/opencode-go"; apiKeyEnv = "OPENCODE_API_KEY";`
  - refs: `modules/agents/litellm/_aliases.nix` (upstreams block, `opencode-go` entry)
  - criteria: reuses the existing `OPENCODE_API_KEY` env (already in the litellm env template); the direct `opencode-go` upstream entry and all other upstreams remain unchanged.
- [x] `A2.` Add the `muse-spark-1.2` route to `routes`:
  `mode = "chat"; registryModel = "meta/muse-spark-1.2"; chain = [ "opencode-go-relay" ];`
  - criteria: single-entry chain (no direct `opencode-go` fallback — not reachable from Aus for this model); the new model is the only route using the relay upstream.
- [x] `A3.` Add the `muse-spark-1.2` self-alias to `aliases` and a client-model
  entry to `clientModels` (`name = "Muse Spark 1.2"; autogenerateVariants = true;`).
  - criteria: mirrors the `glm-5.2`/`glm-5.3` alias+clientModel pattern.
- [x] `A4.` Bump the `models.dev` `builtins.fetchurl` pin in
  `modules/agents/litellm/_generated.nix` to the current snapshot so
  `meta/muse-spark-1.2` resolves its real context limit (1048576 / 131072).
  - refs: `modules/agents/litellm/_generated.nix` (`modelRegistry` fetchurl, `sha256-mQY…` → `sha256-scyv…`)
  - criteria: `mkHeadroomModel` resolves `meta/muse-spark-1.2` from the registry snapshot (no default-limit fallback); eval still passes.
- [x] `A5.` Verify: `nix fmt` and `nix flake check --no-build --no-write-lock-file`
  pass (nixfmt + statix + deadnix over `modules/`, full HM activation eval).
  - criteria: the generated `model_list` includes a `muse-spark-1.2` entry whose `api_base` is the relay URL; no other model entry's routing changes.
  - verify: `openspec validate --strict add-muse-spark-relay-route`
