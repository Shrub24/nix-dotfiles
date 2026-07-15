## Context

LiteLLM currently runs from a patched `litellm-database` OCI image because its PostgreSQL/Prisma runtime was impractical to package reliably as a Nix Python environment. The image is pinned at a pre-v1.92 release, while Headroom's current native LiteLLM guardrail requires LiteLLM v1.92 or newer. A legacy Nix ASGI wrapper and wheel package remain from an abandoned integration path. The enabled Headroom sidecar instead installs Python dependencies at container startup, which is neither reproducible nor offline-startable.

The upgraded LiteLLM database image runs its own tracked Prisma migrations. The old custom entrypoint's `prisma db push` bypasses migration history and causes avoidable idempotent migration recovery, so it must be removed.

Headroom's official `:code` image contains the proxy and tree-sitter code compression. Its proxy exposes a streamable HTTP MCP endpoint at `/mcp`; that endpoint shares Headroom's compression store, allowing OpenCode to retrieve original content compressed by the LiteLLM guardrail.

## Goals / Non-Goals

**Goals:**
- Keep LiteLLM database support and local endpoint compatibility while upgrading to a Headroom-guardrail-capable pinned OCI release.
- Use a pinned official Headroom code-aware OCI image, persistent Headroom state, native LiteLLM pre-call guardrails, and a single shared remote MCP endpoint.
- Centralize OCI references and automate update proposals for OCI refs and flake inputs with Renovate.
- Remove superseded ASGI/Python/NVFetcher wiring.

**Non-Goals:**
- Add Headroom's ML/LLMLingua stack; its large Torch runtime has no demonstrated value for this coding workflow.
- Run a second stdio MCP server or configure Headroom as an upstream LLM proxy.
- Automate application of Renovate PRs, image archive hash regeneration, or deploy Renovate infrastructure.

## Decisions

### Pinned official `:code` Headroom image

Use `ghcr.io/chopratejas/headroom:code` at a version tag and immutable digest. It supplies `proxy` and `code`, including tree-sitter compression and MCP support, without rebuilding Python dependencies when the service starts. `mcp` need not be installed separately because the proxy image exposes `/mcp`. A custom `proxy,code,ml,mcp` image was rejected: ML adds substantial Torch startup and memory cost, while MCP is already available from the proxy.

### Native guardrail rather than ASGI middleware

Render LiteLLM's `headroom` pre-call guardrail with `default_on = true` and the local sidecar base URL only when `programs.litellm.headroom.enable` is true. Native guardrails preserve LiteLLM lifecycle, audit, spend-log, virtual-key, bypass, and per-request semantics. The old ASGI path is incompatible as a concurrent integration because it can double-compress requests and bypasses guardrail observability. The host remains Headroom-disabled until the Renovate policy is present and the LiteLLM OCI base image has been upgraded to v1.92.0 or newer.

### One Headroom proxy, remote OpenCode MCP

Expose `http://127.0.0.1:<headroom-port>/mcp` to OpenCode as a remote MCP server. Do not spawn `headroom mcp serve`: proxy `/mcp` shares the same CompressionStore as guardrail compression, so `headroom_retrieve` can recover the canonical original. Provide a thin host `headroom` command wrapper that delegates supported operational commands, including `learn`, to the persistent container. Mount Headroom's state directory; mount only documented agent-state directories needed by selected CLI workflows.

### OCI policy file plus Renovate

Keep immutable upstream image refs in `policy/oci-images.nix` as `repository:tag@sha256:digest` strings. Renovate's Nix manager updates flake inputs; its custom regex manager opens OCI digest/tag update PRs for this policy file. LiteLLM's patched `dockerTools.pullImage` additionally needs Nix's content hash, which cannot be inferred from an OCI digest; image-update PR validation must regenerate that hash before merge.

### Native Prisma migration lifecycle

Let the v1.92.0-or-newer LiteLLM database image run its built-in tracked migration lifecycle. The local image entrypoint continues to apply compatibility patches but does not run `prisma generate` or `prisma db push`.

### OCI-only LiteLLM runtime

Remove `programs.litellm.oci.enable` and the unused non-OCI `package` fallback. The gateway depends on the OCI image for its supported database/Prisma runtime, so retaining a switch that selects an unvalidated path only creates dead configuration surface.

## Risks / Trade-offs

- [New LiteLLM image changes proxy/Prisma behavior] → Pin version and digest; validate database startup, virtual-key authorization, routing fallbacks, and rollback by restoring the prior policy ref.
- [Headroom service unavailable] → LiteLLM native guardrail behavior must be tested for fail-open compatibility; dependency ordering starts Headroom before LiteLLM.
- [Compressed original expires] → Document Headroom's proxy-store TTL and preserve state for durable statistics; agents must retrieve before the upstream retention window expires.
- [Renovate changes OCI ref without Nix archive hash] → Require a build check that reports the replacement `dockerTools.pullImage` hash.
- [CLI wrapper has a stopped container] → Return a clear service-start instruction rather than implicitly launching a mutable container.

## Migration Plan

1. Add the OCI policy and Renovate configuration, then pin Headroom `:code` and a LiteLLM image at v1.92 or newer.
2. Consolidate OCI derivations under `pkgs/litellm/`; preserve only the two active LiteLLM compatibility patches.
3. Replace the runtime pip sidecar with the pinned image, mount Headroom state, and expose its health/MCP endpoints locally while retaining `headroom.enable = false`.
4. Render the conditionally gated native guardrail and OpenCode remote MCP entry, then enable Headroom only after the v1.92.0-or-newer LiteLLM image has passed evaluation.
5. Evaluate, build, switch, and verify the guardrail header, MCP tool discovery/retrieval, code-aware compression, routing, and database behavior.
6. Roll back by restoring the previous LiteLLM policy reference and disabling the Headroom toggle; no database schema rollback is expected from this change.

## Open Questions

- Which exact LiteLLM v1.92-or-newer database image release and digest passes the current Prisma/database smoke checks?
- Does the selected Headroom `:code` release expose all required operational commands under the non-root container user without extra host-state mounts?
