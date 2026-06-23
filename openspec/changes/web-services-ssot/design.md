## Context

This repo defines several localhost web services via Home Manager modules (litellm, docs-mcp, qmd, agentmemory). Each module hardcodes its port and endpoint paths independently. A previous ad-hoc `homepage.nix` file duplicated those ports to produce a homepage widget config, creating a drift risk. The homelab flake imports this repo as a flake input and consumes the homepage output for its cloud-hosted homepage dashboard (gethomepage.dev), accessed over tailnet.

The current state:
- `homepage.nix` at repo root hardcodes 4 services with ports and icons
- Service modules (`modules/home/agents/*.nix`) independently define the same ports via `mkOption` defaults
- No machine-readable catalog exists for other consumers

## Goals / Non-Goals

**Goals:**
- Establish a single source of truth for localhost web service metadata (ports, scheme, endpoint paths, display info)
- Derive homepage output, JSON catalog, and module port references from one catalog
- Keep the catalog scoped to service-local facts only (no Cloudflare, TLS, OIDC, reverse proxy config)
- Only services with a `ui.path` appear on the homepage
- Maintain backward-compatible flake outputs (`homepageServices`, `homepageServicesYAML`)

**Non-Goals:**
- Public internet routing, TLS, or access policy (belongs in homelab repo's `web-services.nix`)
- Runtime service discovery or a daemon/API
- Tailnet hostname derivation (services are localhost-only)
- Non-web services (CLI tools, daemons without HTTP endpoints)

## Decisions

### 1. Catalog as pure data, not a module
**Decision**: Place the catalog at `lib/web-services.nix` as a pure Nix data file with a normalization function, not a Home Manager module.

**Rationale**: The catalog is data (ports, paths, icons), not configuration that needs `mkEnableOption` or `config` blocks. Keeping it in `lib/` makes it importable by both the flake outputs and service modules without module system overhead.

**Alternatives considered**:
- A Home Manager module with `programs.webServices` options — rejected as over-engineering for a static data file.
- Putting it under `modules/` — rejected because it's data, not a feature module.

### 2. `ui.path` presence drives homepage inclusion
**Decision**: A service appears on the homepage if and only if it has a `ui.path` attribute. No separate `includeInHomepage` boolean.

**Rationale**: Presence-based is simpler and self-documenting. Services without a browser UI (e.g., API-only endpoints) stay in the catalog for port/config reuse but are naturally excluded from homepage rendering.

**Alternatives considered**:
- `includeInHomepage = true/false` boolean — rejected as redundant with `ui.path` presence.
- Inferring from `health.path` — rejected because health endpoints don't imply a useful browser UI.

### 3. URL derivation, not storage
**Decision**: Store only `port`, `scheme`, `host`, and endpoint paths. Derive `baseUrl`, `uiUrl`, `healthUrl`, `openapiUrl` via a normalization function.

**Rationale**: Avoids duplicating full URLs. If `host` or `scheme` changes, only one field updates. Derived URLs are computed consistently.

### 4. Defaults with per-service overrides
**Decision**: Top-level `defaults` attrset provides `scheme`, `host`, `group`. Each service can override any field.

**Rationale**: All services share `scheme = "http"` and `host = "localhost"`. Defaults avoid repetition while allowing future per-service overrides (e.g., a service on a different host).

### 5. Backward-compatible flake outputs
**Decision**: Keep existing `homepageServices` and `homepageServicesYAML` outputs. Add new `webServices`, `webServiceCatalog`, `webServiceCatalogJSON` outputs.

**Rationale**: The homelab flake already consumes `homepageServices` and `homepageServicesYAML`. Keeping them avoids breaking the downstream consumer while adding new outputs for other use cases.

### 6. JSON is valid YAML for homepage
**Decision**: Use `builtins.toJSON` for the rendered homepage YAML file. JSON is a subset of YAML and homepage's parser accepts it.

**Rationale**: nixpkgs' `lib.generators.toYAML` produces identical JSON output for list structures. Using `builtins.toJSON` is simpler and equally valid.

## Risks / Trade-offs

- **[Port drift between catalog and modules]** → Mitigate by wiring modules to reference catalog ports where practical. Full wiring is optional; partial wiring still reduces drift.
- **[Catalog grows beyond scope]** → Mitigate by keeping the schema minimal. Cloud/routing fields belong in the homelab repo, not here.
- **[Homepage JSON format limitation]** → JSON output is less human-readable than indented YAML. Trade-off is acceptable since the file is machine-consumed.
- **[New `lib/` directory]** → Introduces a new top-level directory. Acceptable since it follows the repo's pattern of concern-separated directories.
