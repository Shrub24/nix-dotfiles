## Why

Service ports, endpoint paths, and display metadata are currently duplicated across Home Manager modules and the ad-hoc `homepage.nix` file. There is no single source of truth for "what web services exist, what ports they listen on, and what endpoints they expose." This makes it easy for the homepage widget, module configs, and future consumers to drift out of sync. A lightweight, localhost-scoped service catalog eliminates that duplication and gives a clean derivation point for homepage output, JSON catalogs, and module port references.

## What Changes

- Introduce a `lib/web-services.nix` data file as the canonical SSOT for localhost web service metadata (ports, scheme, endpoint paths, display info).
- Add a normalization function that merges defaults and derives `baseUrl`, `uiUrl`, `healthUrl`, and `openapiUrl` per service.
- Replace the current `homepage.nix` with derived homepage output from the catalog.
- Expose flake outputs: `webServices` (raw), `webServiceCatalog` (normalized), `webServiceCatalogJSON` (JSON file).
- Wire service modules to reference catalog ports where practical (litellm, docs-mcp, qmd, agentmemory).
- Serve the catalog JSON over HTTP on `0.0.0.0:8123` via a systemd user service, making it accessible on tailnet without importing the flake.
- The catalog server is itself a catalog entry (`web-catalog`), making the catalog self-discoverable.
- Homepage rendering is a consumer concern — this repo exposes the catalog only, not rendered homepage output.

## Capabilities

### New Capabilities

- `web-service-catalog`: A localhost-scoped service catalog that authoritatively defines web service ports, endpoint paths, and display metadata, with derived outputs for homepage consumption, JSON catalogs, and module port references.

### Modified Capabilities

<!-- No existing spec-level requirement changes. -->

## Impact

- **New files**: `lib/web-services.nix` (catalog data + normalization logic), `modules/home/agents/web-catalog.nix` (HTTP server module).
- **Removed files**: `homepage.nix` (replaced by derived output from catalog).
- **Modified files**: `flake.nix` (new flake outputs, import catalog), service modules under `modules/home/agents/` (port references where practical), `modules/home/agents/default.nix` (import web-catalog module).
- **Flake outputs**: `webServices`, `webServiceCatalog`, `webServiceCatalogJSON` (new).
- **HTTP endpoint**: Catalog JSON served at `http://<tailnet-ip>:8123/homelab-services.json` — primary consumption path for remote consumers.
- **Consumers**: homelab flake fetches the catalog JSON over HTTP (tailnet) for its cloud homepage dashboard. No flake input import required. Homepage rendering is performed by the consumer, not this repo.
