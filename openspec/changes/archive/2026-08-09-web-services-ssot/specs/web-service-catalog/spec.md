## ADDED Requirements

### Requirement: Catalog defines web service metadata
The system SHALL provide a canonical Nix data file (`lib/web-services.nix`) that defines all localhost web services with their ports, scheme, endpoint paths, and display metadata.

#### Scenario: Catalog contains service entries
- **WHEN** the catalog file is imported
- **THEN** it returns an attrset with `defaults` and `services` keys
- **AND** each service entry contains at minimum `name`, `port`, and `description`

#### Scenario: Defaults are applied to all services
- **WHEN** a service does not specify `scheme`, `host`, or `group`
- **THEN** the normalization function applies the top-level `defaults` values for those fields

#### Scenario: Per-service overrides take precedence
- **WHEN** a service specifies `scheme`, `host`, or `group`
- **THEN** the service-level value overrides the top-level `defaults` value

### Requirement: URL derivation from catalog fields
The system SHALL derive `baseUrl`, `uiUrl`, `healthUrl`, and `openapiUrl` from stored fields rather than storing full URLs.

#### Scenario: Base URL is derived
- **WHEN** a service has `scheme = "http"`, `host = "localhost"`, `port = 8765`
- **THEN** the normalized catalog entry has `baseUrl = "http://localhost:8765"`

#### Scenario: UI URL is derived when ui.path exists
- **WHEN** a service has `ui.path = "/"` and `baseUrl = "http://localhost:8765"`
- **THEN** the normalized catalog entry has `uiUrl = "http://localhost:8765/"`

#### Scenario: UI URL is null when ui.path is absent
- **WHEN** a service does not have a `ui.path` attribute
- **THEN** the normalized catalog entry has `uiUrl = null`

#### Scenario: Health URL is derived when health.path exists
- **WHEN** a service has `health.path = "/health"` and `baseUrl = "http://localhost:8765"`
- **THEN** the normalized catalog entry has `healthUrl = "http://localhost:8765/health"`

#### Scenario: OpenAPI URL is derived when openapi.path exists
- **WHEN** a service has `openapi.path = "/openapi.json"` and `baseUrl = "http://localhost:8765"`
- **THEN** the normalized catalog entry has `openapiUrl = "http://localhost:8765/openapi.json"`

### Requirement: Flake outputs expose catalog and derived formats
The system SHALL expose flake outputs for the raw catalog, normalized catalog, and JSON catalog. Homepage rendering is a consumer concern and is NOT exposed as a flake output.

#### Scenario: Raw catalog output
- **WHEN** a consumer accesses `.#webServices`
- **THEN** it returns the raw SSOT attrset with `defaults` and `services`

#### Scenario: Normalized catalog output
- **WHEN** a consumer accesses `.#webServiceCatalog`
- **THEN** it returns a list of normalized service entries with derived URLs

#### Scenario: JSON catalog output
- **WHEN** a consumer accesses `.#webServiceCatalogJSON`
- **THEN** it returns a Nix store path to a JSON file containing the normalized catalog

#### Scenario: No homepage output is exposed
- **WHEN** a consumer inspects the flake outputs
- **THEN** there is no `homepageServices` or `homepageServicesYAML` output

### Requirement: Catalog is scoped to service-local facts
The system SHALL NOT include public internet routing, TLS, Cloudflare, OIDC, or reverse proxy configuration in the catalog.

#### Scenario: No routing fields in catalog
- **WHEN** the catalog is inspected
- **THEN** it contains no fields for `subdomain`, `primaryDomain`, `cloudflare`, `oidc`, `access`, or `tls`

### Requirement: Catalog is served over HTTP
The system SHALL serve the normalized catalog JSON over HTTP on `0.0.0.0` at the catalog server's port, making it accessible on tailnet without importing the flake.

#### Scenario: Catalog JSON is served at a known path
- **WHEN** a consumer sends an HTTP GET request to `http://<host>:<port>/homelab-services.json`
- **THEN** the response is a JSON document containing `{ version, services }` with normalized service entries

#### Scenario: Catalog server binds all interfaces
- **WHEN** the catalog server module is enabled
- **THEN** the HTTP server binds to `0.0.0.0` (all interfaces), making it reachable on tailnet

#### Scenario: Catalog server is a catalog entry
- **WHEN** the catalog is inspected
- **THEN** it contains a `web-catalog` service entry with `port`, `ui.path`, and `health.path` matching the catalog server's configuration
