## Why

Service ports, endpoint paths, and display metadata are currently duplicated across Home Manager modules and the ad-hoc `homepage.nix` file. There is no single source of truth for "what web services exist, what ports they listen on, and what endpoints they expose." This makes it easy for the homepage widget, module configs, and future consumers to drift out of sync. A lightweight, localhost-scoped service catalog eliminates that duplication and gives a clean derivation point for homepage output, JSON catalogs, and module port references.

## What Changes

- Introduce a `lib/web-services.nix` data file as the canonical SSOT for localhost web service metadata (ports, scheme, endpoint paths, display info).
- Add a normalization function that merges defaults and derives `baseUrl`, `uiUrl`, `healthUrl`, and `openapiUrl` per service.
- Replace the current `homepage.nix` with derived homepage output from the catalog.
- Expose flake outputs: `webServices` (raw), `webServiceCatalog` (normalized), `webServiceCatalogJSON` (JSON file), `homepageServices` (homepage format), `homepageServicesYAML` (rendered file).
- Wire service modules to reference catalog ports where practical (litellm, docs-mcp, qmd, agentmemory).
- Homepage rendering rule: only services with a `ui.path` appear on the homepage.

## Capabilities

### New Capabilities
- `web-service-catalog`: A localhost-scoped service catalog that authoritatively defines web service ports, endpoint paths, and display metadata, with derived outputs for homepage consumption, JSON catalogs, and module port references.

### Modified Capabilities
<!-- No existing spec-level requirement changes. -->

## Impact

- **New files**: `lib/web-services.nix` (catalog data + normalization logic).
- **Removed files**: `homepage.nix` (replaced by derived output from catalog).
- **Modified files**: `flake.nix` (new flake outputs, import catalog), service modules under `modules/home/agents/` (port references where practical).
- **Flake outputs**: `homepageServices`, `homepageServicesYAML` (existing, now derived), plus new `webServices`, `webServiceCatalog`, `webServiceCatalogJSON`.
- **Consumers**: homelab flake imports this repo as a flake input and consumes `homepageServices` / `homepageServicesYAML` for its cloud homepage dashboard.
