# Proposal: Add Muse Spark 1.2 via the LA OpenCode-Go Relay

## Summary

Adds the `muse-spark-1.2` (Meta) model to the LiteLLM gateway, routed through a
Tailscale-only Caddy relay on the `la-admin-1` homelab node (US-West) rather than
the existing direct `opencode-go` upstream. The relay maps `/opencode-go/*` →
`https://opencode.ai/zen/go/v1/*` and preserves the `Authorization` header, so
LiteLLM's standard OpenAI calls land on the right upstream path automatically.
Only this model entry routes through LA; every other model keeps its existing
(direct) routing.

## Motivation

Muse Spark 1.2 is geo-restricted from Australia, but is reachable via the US
egress the operator already deployed as a Caddy reverse proxy on `la-admin-1`
over the tailnet. The relay accepts only `tailscale0` reach on port 8787 and
fails closed (`404`) on any non-`/opencode-go/*` path, so no public listener or
extra auth layer is involved. LiteLLM (podman, `--network host`) resolves the
relays MagicDNS name directly through the host's Tailscale.

## Design

A single new upstream — `opencode-go-relay` — is added to
`modules/agents/litellm/_aliases.nix`, alongside a `muse-spark-1.2` route (chat,
`registryModel = "meta/muse-spark-1.2"`), a self alias, and a client-model entry
(`name = "Muse Spark 1.2"`, `autogenerateVariants = true`). The new upstream
reuses the existing `OPENCODE_API_KEY` env var (already in the LiteLLM env
template): the relay forwards the `Authorization` header verbatim to
`opencode.ai`.

`api_base` is the relay MagicDNS URL
(`http://la-admin-1.tail0fe19b.ts.net:8787/opencode-go`), referenced as a plain
string — consistent with the existing external-endpoint precedents
(`PHOENIX_COLLECTOR_ENDPOINT = http://oci-melb-1:4317`, the crof/openrouter/
volcengine apiBase literals). `la-admin-1` is already a `topology.hosts.arch`
remoteHosts entry; no topology schema change is warranted for a single upstream
endpoint string.

### Non-goals / follow-ups

- **No fallback to direct `opencode-go`.** The direct upstream is not reachable
  from Aus for this model (the reason the relay exists), so a fallback chain
  entry would be dead. The chain is a single relay entry; the direct
  `opencode-go` upstream and all routes using it are left untouched.
- **`models.dev` pin bumped.** The pinned `builtins.fetchurl` sha in
  `_generated.nix` predates `meta/muse-spark-1.2`; without a refresh,
  `mkHeadroomModel` falls back to default context limits (128000) for the new
  model. The pin is bumped to the current snapshot so the new model resolves its
  real limits (1048576 / 131072); as a side effect the other models' metadata
  refreshes to current values (registry updates are additive/accurate, low risk).
- **No `litellm-gateway` spec delta.** That spec contracts the service lifecycle
  (enable, secrets, restarts, Headroom), not the model/routing list, which is
  implementation data in `_aliases.nix`.
