## Why

LiteLLM is pinned to a pre-Headroom-guardrail OCI release, while the current Headroom sidecar installs a mutable Python image and dependencies on every start. The legacy ASGI and Python-package paths no longer match the chosen native LiteLLM guardrail architecture.

## What Changes

- Upgrade the patched LiteLLM database OCI base image to a pinned release that supports native Headroom guardrails.
- Replace the runtime `python:slim` + `pip install` Headroom sidecar with the pinned official Headroom code-aware OCI image.
- Bound Headroom's local compression workers and disable its unselected Kompress fallback to prevent host CPU oversubscription.
- Enable Headroom as LiteLLM's default pre-call guardrail and persist its compression state.
- Expose the Headroom proxy's shared MCP endpoint to OpenCode for compression, retrieval, and statistics tools.
- Provide a declarative host CLI wrapper for operational Headroom commands such as `learn`.
- Add `policy/oci-images.nix` and Renovate configuration to update flake inputs and pinned OCI image references.
- Remove obsolete Headroom ASGI/Python derivations and their stale nvfetcher metadata.
- Remove the obsolete non-OCI LiteLLM runtime option and package fallback.
- Generate a Headroom context-limit catalog from the existing client model metadata without duplicating pricing configuration.
- Simplify declarative LiteLLM route definitions: routes own one explicit models.dev registry identifier, while simple upstream fallback entries inherit the route's logical model identifier.
- Run Headroom's stdio MCP bridge against the shared proxy from OpenCode instead of registering the proxy's HTTP MCP endpoint directly.

## Capabilities

### New Capabilities

- `oci-image-management`: Canonical OCI image references and Renovate-based dependency update automation.
- `headroom-context-management`: Code-aware Headroom proxy, persistent context state, and shared MCP retrieval for OpenCode.

### Modified Capabilities

- `litellm-gateway`: The local gateway uses a current pinned OCI image and applies Headroom through LiteLLM's native guardrail lifecycle.
- `litellm-client-integration`: OpenCode receives Headroom's remote MCP tools alongside its existing LiteLLM provider integration.

## Impact

- Affects `flake.nix`, `nvfetcher.toml`, `pkgs/litellm*/`, `modules/home/agents/litellm/`, `modules/home/sops.nix`, `modules/home/opencode.nix`, and the mutable OpenCode configuration.
- Adds a `policy/oci-images.nix` image-reference policy and root `renovate.json`.
- Removes unused Python/ASGI Headroom packaging and stale generated nvfetcher data.
- Requires one-time validation of the upgraded LiteLLM image, Headroom proxy/MCP endpoint, and OpenCode tool registration.
