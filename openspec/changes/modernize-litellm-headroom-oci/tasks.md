## 1. OCI source policy and update automation

- [x] 1.1 Add `policy/oci-images.nix` with version-and-digest pins for a LiteLLM database image supporting native Headroom guardrails and the official Headroom `:code` image.
  - refs: `policy/oci-images.nix`, `pkgs/litellm/oci.nix`
  - criteria: each ref has an explicit tag and immutable manifest digest
  - verify: evaluate the policy file
- [x] 1.2 Add `renovate.json` to update flake inputs and the OCI references in `policy/oci-images.nix`.
  - refs: `renovate.json`, `flake.nix`
  - criteria: Nix and custom-regex OCI managers are enabled and OCI updates are grouped separately
  - verify: validate JSON and inspect matching regex against both policy refs

## 2. Consolidate LiteLLM OCI packaging

- [x] 2.1 Move the active LiteLLM OCI derivation to the canonical `pkgs/litellm/oci.nix` location and update the overlay reference.
  - refs: `pkgs/litellm/oci.nix`, `flake.nix`
  - criteria: the derivation consumes the LiteLLM policy ref and retains both active compatibility patches
  - verify: evaluate `pkgs.litellm-oci`
- [x] 2.2 Regenerate the `dockerTools.pullImage` content hash for the selected upgraded LiteLLM image, record it in the canonical OCI derivation, and remove the redundant local Prisma bootstrap.
  - refs: `pkgs/litellm/oci.nix`, `policy/oci-images.nix`
  - criteria: the derived image is v1.92.0 or newer, builds without a fixed-output hash mismatch, and delegates database migrations to LiteLLM's native lifecycle
  - verify: build `.#homeConfigurations.saurabhj.activationPackage` or the OCI derivation
- [x] 2.3 Delete obsolete ASGI Headroom and Python-wheel derivations, the old `litellm-oci` package directory, and unused Headroom nvfetcher metadata.
  - refs: `pkgs/litellm/default.nix`, `pkgs/headroom-ai/`, `pkgs/litellm-oci/`, `nvfetcher.toml`, `pkgs/_sources/`
  - criteria: no overlay or module references deleted legacy paths; active LiteLLM patches remain under `pkgs/litellm/patches/`
  - verify: exact-reference search and Nix evaluation
- [x] 2.4 Remove the obsolete non-OCI LiteLLM runtime option and package fallback.
  - refs: `modules/home/agents/litellm/default.nix`, `hosts/arch/home.nix`
  - criteria: enabling LiteLLM always runs the pinned OCI image; no `oci.enable` or unused non-OCI package path remains
  - verify: evaluate the Home Manager activation package

## 3. Headroom proxy, guardrail, and MCP integration

- [x] 3.1 Replace the runtime Python/pip Headroom sidecar with the pinned official Headroom `:code` OCI image and persistent Headroom state mount.
  - refs: `modules/home/agents/litellm/default.nix`, `policy/oci-images.nix`
  - criteria: startup needs no runtime package installation; proxy is local-only and code-aware
  - verify: inspect generated user unit and query the proxy health endpoint after switch
- [x] 3.2 After tasks 1.1, 1.2, and 2.2 are verified, render LiteLLM's native `headroom` pre-call guardrail and order LiteLLM after the enabled Headroom proxy.
  - refs: `modules/home/agents/litellm/generated.nix`, `modules/home/sops.nix`, `modules/home/agents/litellm/default.nix`
  - depends: 1.1, 1.2, 2.2
  - criteria: the guardrail defaults on and is rendered only when `headroom.enable` is true, targets the local sidecar, and no ASGI middleware path remains
  - verify: inspect rendered LiteLLM config and response guardrail header/log entry
- [ ] 3.3 Add the declarative host Headroom CLI wrapper for managed-container operational commands, including `learn`.
  - refs: `modules/home/agents/litellm/default.nix`
  - criteria: the wrapper delegates to the managed container through its `python3 -m headroom.cli` entrypoint and uses its persistent state rather than starting an ad-hoc image
  - verify: inspect wrapper command and run its harmless status/help path after switch
- [x] 3.4 Add the Headroom proxy `/mcp` endpoint as an enabled remote MCP server in the generated OpenCode configuration, gated on `headroom.enable`.
  - refs: `modules/home/opencode.nix`, `modules/home/agents/litellm/generated.nix`
  - criteria: OpenCode uses the single shared proxy endpoint only when Headroom is enabled; no parallel Headroom stdio MCP service is configured
  - verify: inspect rendered OpenCode config and list Headroom MCP tools after switch
- [x] 3.5 Generate Headroom's 0.27-compatible context-limit catalog from existing client model metadata and select lean-ctx for explicit managed CLI wrapping.
  - refs: `modules/home/agents/litellm/generated.nix`, `modules/home/agents/litellm/default.nix`
  - criteria: all configured LiteLLM aliases have generated context limits; pricing is omitted; `HEADROOM_CONTEXT_TOOL=lean-ctx` is passed only for CLI wrapping
  - verify: inspect the rendered `models.json` and managed wrapper
- [x] 3.6 Remove obsolete self-published Headroom image wiring now that the official upstream `:code` image is used.
  - refs: `renovate.json`, `policy/oci-images.nix`
  - criteria: no publisher workflow or publisher-specific Renovate manager/rule remains; the upstream tag-and-digest policy pin and its Renovate manager remain
  - verify: validate `renovate.json` and inspect the policy manager
- [x] 3.7 Replace OpenCode's remote Headroom MCP configuration with the `headroom mcp serve --proxy-url` stdio bridge, gated on `headroom.enable`.
  - refs: `modules/home/agents/litellm/generated.nix`
  - criteria: the bridge invokes `headroom` from `PATH`, targets the local proxy, and no remote `/mcp` entry remains
  - verify: inspect the generated OpenCode configuration; runtime discovery is deferred to the user
- [x] 3.8 Pin the official Headroom `:code` image by digest and select Headroom's coding savings profile.
  - refs: `policy/oci-images.nix`, `modules/home/agents/litellm/default.nix`
  - criteria: the service uses the official upstream `:code` image and explicitly selects `HEADROOM_SAVINGS_PROFILE=coding` (which selects cache mode)
  - verify: user deploys and smoke-tests the upstream image
- [x] 3.9 Simplify LiteLLM route registry metadata and common fallback-chain declarations.
  - refs: `modules/home/agents/litellm/aliases.nix`, `modules/home/agents/litellm/generated.nix`
  - criteria: each client-consumed route owns one explicit opaque `registryModel` string; each client model resolves to a generated LiteLLM route; `clientModels` has no registry metadata; string chain entries use the route key as their target model; structured entries retain exact upstream/model overrides
  - verify: evaluate the generated LiteLLM and Headroom configuration, confirming unchanged targets and context limits for existing client aliases

## 4. Validation and reconciliation

- [x] 4.1 Run Nix formatting and evaluate the Home Manager activation package.
  - verify: `nixfmt` on changed Nix files and `nix eval .#homeConfigurations.saurabhj.activationPackage`
- [ ] 4.2 Switch the Home Manager generation and smoke-test LiteLLM, Headroom health, Headroom MCP retrieval, OpenCode MCP discovery, database startup, and a guarded completion request.
  - verify: `nh home switch` plus scoped HTTP/OpenCode checks
  - notes: the prior Kreuzberg build blocker is resolved. As of 2026-08-06, runtime smoke tests are blocked because PostgreSQL at `oci-melb-1:5432` remains in recovery and rejects connections; LiteLLM's native migration step fails, then the container exits before binding port 8765.
- [x] 4.3 Reconcile the implementation with proposal, design, and specs; run strict OpenSpec validation.
  - verify: `openspec validate --strict`
