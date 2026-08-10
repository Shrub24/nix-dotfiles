## Context

This repo defines several localhost web services via Home Manager modules (litellm, docs-mcp, qmd, agentmemory). Each module hardcodes its port and endpoint paths independently. A previous ad-hoc `homepage.nix` file duplicated those ports to produce a homepage widget config, creating a drift risk. The homelab flake imports this repo as a flake input and consumes the homepage output for its cloud-hosted homepage dashboard (gethomepage.dev), accessed over tailnet.

The current state:
- `homepage.nix` at repo root hardcodes 4 services with ports and icons
- Service modules (`modules/home/agents/*.nix`) independently define the same ports via `mkOption` defaults
- No machine-readable catalog exists for other consumers

## Goals / Non-Goals

**Goals:**
- Establish a single source of truth for localhost web service metadata (ports, scheme, endpoint paths, display info)
- Derive JSON catalog and module port references from one catalog
- Keep the catalog scoped to service-local facts only (no Cloudflare, TLS, OIDC, reverse proxy config)
- Only services with a `ui.path` have a derived `uiUrl` (consumers use this to filter for homepage inclusion)
- Expose catalog-only flake outputs (`webServices`, `webServiceCatalog`, `webServiceCatalogJSON`); homepage rendering is a consumer concern
- Serve the catalog JSON over HTTP on `0.0.0.0:8123` so remote consumers (homelab flake) can fetch it over tailnet without importing the dotfiles flake

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

### 2. `ui.path` presence drives derived `uiUrl`
**Decision**: A service has a derived `uiUrl` if and only if it has a `ui.path` attribute. No separate `includeInHomepage` boolean.

**Rationale**: Presence-based is simpler and self-documenting. Services without a browser UI (e.g., API-only endpoints) stay in the catalog for port/config reuse but have `uiUrl = null`. Consumers use `uiUrl != null` to filter for homepage inclusion.

**Alternatives considered**:
- `includeInHomepage = true/false` boolean — rejected as redundant with `ui.path` presence.
- Inferring from `health.path` — rejected because health endpoints don't imply a useful browser UI.

### 3. URL derivation, not storage
**Decision**: Store only `port`, `scheme`, `host`, and endpoint paths. Derive `baseUrl`, `uiUrl`, `healthUrl`, `openapiUrl` via a normalization function.

**Rationale**: Avoids duplicating full URLs. If `host` or `scheme` changes, only one field updates. Derived URLs are computed consistently.

### 4. Defaults with per-service overrides
**Decision**: Top-level `defaults` attrset provides `scheme`, `host`, `group`. Each service can override any field.

**Rationale**: All services share `scheme = "http"` and `host = "localhost"`. Defaults avoid repetition while allowing future per-service overrides (e.g., a service on a different host).

### 5. Catalog-only flake outputs
**Decision**: Expose only `webServices` (raw catalog), `webServiceCatalog` (normalized list), and `webServiceCatalogJSON` (JSON file). Do not expose rendered homepage output.

**Rationale**: This repo is a SSOT catalog. Homepage rendering is a consumer concern — the homelab flake can filter the catalog by `uiUrl != null` and render its own homepage format. Exposing rendered homepage output would couple this repo to a specific consumer's format.

**Alternatives considered**:
- Also expose `homepageServices` / `homepageServicesYAML` — rejected because it couples this repo to gethomepage.dev's format and blurs the SSOT boundary.

### 6. JSON is valid YAML for homepage
**Decision**: The `webServiceCatalogJSON` output uses `builtins.toJSON`. Consumers that need YAML can convert from JSON (JSON is a subset of YAML).

**Rationale**: Keeps the repo format-agnostic. The catalog is JSON; consumers render to whatever format they need.

### 7. Serve catalog over HTTP on 0.0.0.0
**Decision**: Run a `python3 -m http.server` systemd user service on `0.0.0.0:8123` that serves the catalog JSON file. The server binds 0.0.0.0 so it's automatically reachable on the tailnet IP without extra configuration.

**Rationale**: Importing the dotfiles flake as a flake input drags in nixpkgs, home-manager, flake-parts, sops-nix, and 10+ other inputs — all to read 4 port numbers. Serving the catalog JSON over HTTP lets the homelab fetch it with `builtins.fetchurl` at build time or a runtime HTTP call, with zero flake dependencies. The services are already running on tailnet; serving the catalog alongside them is natural.

**Alternatives considered**:
- Separate minimal catalog flake repo — rejected because it decouples the catalog from the services it describes, creating drift risk.
- Piggyback on an existing service (qmd, agentmemory) — rejected because it couples the catalog's availability to another service's health and adds routing complexity.

### 8. Catalog server is self-referential
**Decision**: The `web-catalog` service is itself an entry in the catalog (`services.web-catalog`), with `port = 8123`, `ui.path = "/"`, and `health.path = "/"`.

**Rationale**: Makes the catalog self-discoverable — a consumer that knows the catalog URL can learn the catalog server's own metadata (port, description) from the catalog itself. The python http.server directory listing at `/` serves as both the UI and health endpoint (200 = healthy).

**Trade-off**: Slightly circular (the catalog describes the server that serves the catalog), but the port is statically defined in the data file, so there's no runtime dependency loop.

## Risks / Trade-offs

- **[Port drift between catalog and modules]** → Mitigate by wiring modules to reference catalog ports where practical. Full wiring is optional; partial wiring still reduces drift.
- **[Catalog grows beyond scope]** → Mitigate by keeping the schema minimal. Cloud/routing fields belong in the homelab repo, not here.
- **[Homepage JSON format limitation]** → JSON output is less human-readable than indented YAML. Trade-off is acceptable since the file is machine-consumed.
- **[New `lib/` directory]** → Introduces a new top-level directory. Acceptable since it follows the repo's pattern of concern-separated directories.
- **[HTTP server security]** → The catalog server binds 0.0.0.0, making it reachable on all interfaces including tailnet. The catalog contains only localhost service metadata (ports, paths) — no secrets, no routing info. Acceptable risk; tailnet itself provides network-level access control.
- **[Self-referential catalog entry]** → The catalog server describes itself. No runtime dependency loop since the port is statically defined in the data file, not derived from the running server.
