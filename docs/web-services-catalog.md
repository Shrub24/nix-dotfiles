# Web Services Catalog

A single source of truth (SSOT) for localhost web service metadata — ports,
schemes, endpoint paths, and display info. Defined in
[`lib/web-services.nix`](../lib/web-services.nix), exposed as flake outputs for
local inspection, and **served over HTTP on `0.0.0.0:8123`** for remote
consumers (e.g., the homelab flake's homepage dashboard) to fetch over tailnet
without importing the dotfiles flake.

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
| `web-catalog` | 8123 | `/` | `/`      | —             |

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

## HTTP serving (primary consumption path)

The catalog JSON is served over HTTP by a systemd user service
(`modules/home/agents/web-catalog.nix`). The server binds `0.0.0.0:8123`,
making it automatically reachable on tailnet without extra configuration.

**Endpoint:** `http://<tailnet-ip>:8123/homelab-services.json`

The server is a `python3 -m http.server` serving a Nix store path containing
the rendered `homelab-services.json` file. The catalog server is itself a
catalog entry (`web-catalog`), making the catalog self-discoverable.

### Consuming over HTTP (recommended)

Fetch the catalog JSON at build time or runtime — no flake import required:

```nix
# homelab flake.nix — build-time fetch
let
  catalogJson = builtins.readFile (builtins.fetchurl
    "http://100.x.y.z:8123/homelab-services.json");
  catalog = (builtins.fromJSON catalogJson).services;
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
}
```

### Consuming via flake input (alternative)

If you prefer a build-time Nix dependency (proper pinning via lock), add this
repo as a flake input. Note this imports the full dotfiles flake with all its
inputs:

```nix
inputs.dotfiles-nix.url = "github:Shrub24/nix-dotfiles";

# Access: inputs.dotfiles-nix.webServiceCatalog
# Access: inputs.dotfiles-nix.webServiceCatalogJSON
```

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

Wired modules: `litellm`, `docs-mcp`, `qmd`, `agentmemory`, `web-catalog`.

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

7. **Serve over HTTP on 0.0.0.0** — the catalog JSON is served by a
   `python3 -m http.server` systemd user service on `0.0.0.0:8123`. Binding
   0.0.0.0 makes it reachable on tailnet automatically. This avoids forcing
   consumers to import the dotfiles flake (with 10+ inputs) just to read port
   numbers.

8. **Catalog server is self-referential** — the `web-catalog` service is itself
   a catalog entry. A consumer that knows the catalog URL can discover the
   server's own metadata from the catalog itself. No runtime dependency loop —
   the port is statically defined in the data file.

## Reference

- Catalog source: [`lib/web-services.nix`](../lib/web-services.nix)
- HTTP server module: [`modules/home/agents/web-catalog.nix`](../modules/home/agents/web-catalog.nix)
- OpenSpec change: [`openspec/changes/web-services-ssot/`](../openspec/changes/web-services-ssot/)
- Spec: [`openspec/changes/web-services-ssot/specs/web-service-catalog/spec.md`](../openspec/changes/web-services-ssot/specs/web-service-catalog/spec.md)
