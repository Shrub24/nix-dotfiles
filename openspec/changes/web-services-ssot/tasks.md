## 1. Catalog Data File

- [x] 1.1 Create `lib/web-services.nix` with `defaults` attrset (`scheme = "http"`, `host = "localhost"`, `group = "AI Services"`) and `services` attrset containing 4 services (litellm, docs-mcp, qmd, agentmemory) with `name`, `port`, `icon`, `description`, and endpoint paths (`ui.path`, `health.path`, `openapi.path` where applicable)
- [x] 1.2 Add `normalize` function to `lib/web-services.nix` that merges defaults per-service and derives `baseUrl`, `uiUrl`, `healthUrl`, `openapiUrl`
- [x] 1.3 Add `toHomepage` function to `lib/web-services.nix` that filters to services with `ui.path` and renders homepage-compatible grouped output with `href`, `icon`, `description`, and `siteMonitor` (when health URL exists)
- [x] 1.4 Add `toCatalogJSON` function to `lib/web-services.nix` that produces a normalized JSON-serializable catalog with `version` and `services` list

## 2. Flake Outputs

- [x] 2.1 Update `flake.nix` to import `lib/web-services.nix` (replacing the `homepage.nix` import)
- [x] 2.2 Expose `webServices` output (raw SSOT attrset)
- [x] 2.3 Expose `webServiceCatalog` output (normalized list with derived URLs)
- [x] 2.4 Expose `webServiceCatalogJSON` output (Nix store path to JSON file)
- [x] 2.5 Remove `homepageServices` and `homepageServicesYAML` outputs (homepage rendering is a consumer concern)
- [x] 2.6 Remove `mkHomepageServices` output (superseded by catalog approach)

## 3. Cleanup

- [x] 3.1 Delete `homepage.nix` (replaced by `lib/web-services.nix`)
- [x] 3.2 Remove `git add` tracking for `homepage.nix` if staged

## 4. Module Port Wiring (Optional)

- [x] 4.1 Wire `modules/home/agents/litellm/default.nix` port default to reference `webServices.services.litellm.port`
- [x] 4.2 Wire `modules/home/agents/docs-mcp.nix` port default to reference `webServices.services.docs-mcp.port`
- [x] 4.3 Wire `modules/home/agents/qmd.nix` port default to reference `webServices.services.qmd.port`
- [x] 4.4 Wire `modules/home/agents/agentmemory.nix` viewer URL to reference `webServices.services.agentmemory.port`

## 5. Validation

- [x] 5.1 Run `nix eval .#webServices --json` and verify 4 services are present
- [x] 5.2 Run `nix eval .#webServiceCatalog --json` and verify derived URLs are correct
- [x] 5.3 Run `nix build .#webServiceCatalogJSON` and verify JSON catalog contents
- [x] 5.4 Run `nix flake check` and verify all checks pass
- [x] 5.5 Run `nix fmt` on all modified files
