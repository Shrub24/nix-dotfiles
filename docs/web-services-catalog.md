# Web Services Catalog

A single source of truth (SSOT) for localhost web service metadata — ports,
schemes, endpoint paths, and display info. Defined in
[`lib/web-services.nix`](../lib/web-services.nix) and exposed as flake outputs
for downstream consumers (e.g., the homelab flake's homepage dashboard).

## Why a catalog?

Before the catalog, service ports and endpoint paths were duplicated across
Home Manager modules and an ad-hoc `homepage.nix` file. There was no
machine-readable source of truth for "what web services exist, what ports do
they listen on, and what endpoints do they expose." The catalog eliminates that
duplication and gives a clean derivation point for JSON output, module port
references, and consumer-side rendering.

## Scope

**In scope:** service-local facts only — ports, scheme, host, endpoint paths,
display metadata (name, icon, description, group).

**Out of scope:** public internet routing, TLS, Cloudflare, OIDC, reverse
proxy config. Those belong in the homelab repo's `web-services.nix`, not here.
This catalog describes localhost services; it does not describe how they're
exposed externally.

## Catalog shape

The catalog is a pure Nix data file. It returns an attrset with two keys:

```nix
{
  defaults = {
    scheme = "http";
    host = "localhost";
    group = "AI Services";
  };

  services = {
    <service-id> = { ... };  # see "Service entry shape" below
  };
}
```

- `defaults` — applied to every service unless overridden
- `services` — keyed by service id (e.g., `litellm`, `docs-mcp`)

### Service entry shape

Each service entry is an attrset. Required fields: `name`, `port`. Optional
fields inherit from `defaults` or are omitted entirely.

| Field           | Type     | Required | Description                                      |
| --------------- | -------- | -------- | ------------------------------------------------ |
| `name`          | string   | yes      | Display name                                     |
| `port`          | int      | yes      | Listen port                                      |
| `description`   | string   | no       | Short description                                |
| `icon`          | string   | no       | Homepage icon id (see gethomepage.dev icon set) |
| `scheme`        | string   | no       | URL scheme (default: `"http"`)                   |
| `host`          | string   | no       | Hostname (default: `"localhost"`)                |
| `group`         | string   | no       | Homepage group label (default: `"AI Services"`) |
| `ui.path`       | string   | no       | Browser UI path (e.g., `"/"`)                    |
| `health.path`   | string   | no       | Health endpoint path (e.g., `"/health"`)         |
| `openapi.path`  | string   | no       | OpenAPI spec path (e.g., `"/openapi.json"`)      |

**Endpoint presence encodes capability.** A service with `ui.path` has a
browser UI; a service without it doesn't. Consumers use `uiUrl != null` to
filter for homepage inclusion.

### Current services

| Service       | Port | UI | Health   | OpenAPI       |
| ------------- | ---- | -- | -------- | ------------- |
| `litellm`     | 8765 | `/` | `/health` | `/openapi.json` |
| `docs-mcp`    | 6280 | `/` | —        | —             |
| `qmd`         | 8181 | `/` | —        | —             |
| `agentmemory` | 3113 | `/` | `/`      | —             |

## URL derivation

URLs are derived, not stored. The normalization function computes:

```
baseUrl    = "${scheme}://${host}:${toString port}"
uiUrl      = baseUrl + ui.path       (null if no ui.path)
healthUrl  = baseUrl + health.path   (null if no health.path)
openapiUrl = baseUrl + openapi.path  (null if no openapi.path)
```

If `scheme`, `host`, or `group` changes, only one field updates.

## Flake outputs

Three outputs are exposed. **Homepage rendering is NOT exposed** — this repo is
a catalog only. Consumers filter and render their own format.

| Output                  | Type          | Description                                              |
| ----------------------- | ------------- | -------------------------------------------------------- |
| `.#webServices`         | attrset       | Raw SSOT catalog: `{ defaults, services }`               |
| `.#webServiceCatalog`   | list          | Normalized entries with derived URLs (`baseUrl`, `uiUrl`, `healthUrl`, `openapiUrl`) |
| `.#webServiceCatalogJSON` | store path  | JSON file containing `{ version, services }`             |

### Normalized entry shape

Each entry in `.#webServiceCatalog` has:

```nix
{
  id = "litellm";
  name = "LiteLLM";
  group = "AI Services";
  port = 8765;
  scheme = "http";
  host = "localhost";
  baseUrl = "http://localhost:8765";
  uiUrl = "http://localhost:8765/";
  healthUrl = "http://localhost:8765/health";
  openapiUrl = "http://localhost:8765/openapi.json";
  icon = "litellm";
  description = "LLM API gateway";
}
```

Fields with no corresponding endpoint path are `null` (e.g., `healthUrl = null`
for docs-mcp).

## Consuming from another flake

Add this repo as a flake input, then access the outputs:

```nix
# flake.nix (consumer — e.g., homelab)
inputs.dotfiles-nix.url = "github:Shrub24/nix-dotfiles";

outputs = { self, dotfiles-nix, ... }:
  let
    catalog = dotfiles-nix.webServiceCatalog;
    jsonFile = dotfiles-nix.webServiceCatalogJSON;
  in
  {
    # Example: render homepage services from the catalog
    homepageServices = builtins.map
      (s: {
        ${s.name} = {
          href = s.uiUrl;
          icon = s.icon;
          description = s.description;
        } // (if s.healthUrl != null then { siteMonitor = s.healthUrl; } else { });
      })
      (builtins.filter (s: s.uiUrl != null) catalog);
  };
```

The `webServiceCatalogJSON` output is a Nix store path — useful for
non-Nix consumers or scripts that want to read the catalog at runtime.

## Module port wiring

Service modules under `modules/home/agents/` reference catalog ports instead of
hardcoding them. This keeps module defaults in sync with the catalog:

```nix
# modules/home/agents/litellm/default.nix
let
  webServices = (import ../../../lib/web-services.nix { inherit lib pkgs; }).services;
in
{
  options.programs.litellm.port = mkOption {
    default = webServices.litellm.port;
    # ...
  };
}
```

Wired modules: `litellm`, `docs-mcp`, `qmd`, `agentmemory`.

## Adding a new service

1. Add an entry to `services` in [`lib/web-services.nix`](../lib/web-services.nix):

   ```nix
   services = {
     # ...existing services...

     my-service = {
       name = "My Service";
       port = 9000;
       icon = "my-icon";
       description = "Does the thing";
       ui.path = "/";
       health.path = "/health";
     };
   };
   ```

2. If the service has a Home Manager module, wire its port default to the
   catalog (see "Module port wiring" above).

3. Validate:

   ```sh
   nix eval .#webServices --json | jq '.services."my-service"'
   nix eval .#webServiceCatalog --json | jq '.[] | select(.id == "my-service")'
   nix flake check
   ```

## Design decisions

1. **Pure data file, not a module** — lives in `lib/`, not `modules/`. No
   `mkEnableOption` or `config` blocks. Importable by both flake outputs and
   service modules without module system overhead.

2. **`ui.path` presence drives `uiUrl`** — no separate `includeInHomepage`
   boolean. Services without a browser UI stay in the catalog for port/config
   reuse but have `uiUrl = null`.

3. **URLs are derived, not stored** — avoids duplicating full URLs. One field
   change propagates correctly.

4. **Defaults with per-service overrides** — all services share
   `scheme = "http"` and `host = "localhost"`. Defaults avoid repetition while
   allowing future per-service overrides.

5. **Catalog-only flake outputs** — no rendered homepage output. Homepage
   rendering is a consumer concern. This keeps the repo format-agnostic and
   avoids coupling to gethomepage.dev's schema.

6. **JSON is valid YAML** — `webServiceCatalogJSON` uses `builtins.toJSON`.
   Consumers that need YAML can convert (JSON is a YAML subset).

## Reference

- Catalog source: [`lib/web-services.nix`](../lib/web-services.nix)
- OpenSpec change: [`openspec/changes/web-services-ssot/`](../openspec/changes/web-services-ssot/)
- Spec: [`openspec/changes/web-services-ssot/specs/web-service-catalog/spec.md`](../openspec/changes/web-services-ssot/specs/web-service-catalog/spec.md)
