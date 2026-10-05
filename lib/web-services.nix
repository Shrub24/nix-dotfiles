# Localhost web service catalog: service-local facts only. Public routing, TLS,
# Cloudflare and OIDC config live in the homelab repo's web-services.nix.
{
  lib,
}:

let
  inherit (lib)
    optionalAttrs
    mapAttrsToList
    filter
    groupBy
    ;

  # ── Catalog data (SSOT) ──────────────────────────────────────────────

  defaults = {
    scheme = "http";
    host = "localhost";
    group = "AI Services";
  };

  services = {
    grist = {
      name = "Grist";
      port = 8484;
      group = "Productivity";
      icon = "si-grist";
      description = "Local spreadsheet database";
      ui.path = "/";
      health.path = "/status";
    };

    qmd = {
      name = "QMD";
      port = 8181;
      icon = "si-markdown";
      description = "Local markdown search engine";
      ui.path = "/";
    };

    mcp-nixos = {
      name = "NixOS MCP";
      port = 8000;
      icon = "si-nixos";
      description = "NixOS options, packages and channels (MCP HTTP)";
      mcp.path = "/mcp";
    };

    web-catalog = {
      name = "Web Catalog";
      port = 8123;
      icon = "mdi-code-json";
      description = "Service catalog JSON endpoint";
      ui.path = "/";
      health.path = "/";
    };
  };

  # ── Normalization ───────────────────────────────────────────────────

  normalizeService =
    id: svc:
    let
      scheme = svc.scheme or defaults.scheme;
      host = svc.host or defaults.host;
      inherit (svc) port;
      baseUrl = "${scheme}://${host}:${toString port}";
      uiPath = svc.ui.path or null;
      healthPath = svc.health.path or null;
      openapiPath = svc.openapi.path or null;
      mcpPath = svc.mcp.path or null;
    in
    {
      inherit id;
      inherit (svc) name port;
      group = svc.group or defaults.group;
      inherit scheme host baseUrl;
      uiUrl = if uiPath != null then "${baseUrl}${uiPath}" else null;
      healthUrl = if healthPath != null then "${baseUrl}${healthPath}" else null;
      openapiUrl = if openapiPath != null then "${baseUrl}${openapiPath}" else null;
      # MCP is a protocol endpoint a client POSTs to, not a page: kept out of
      # uiUrl, and with it out of the homepage block that would render it.
      mcpUrl = if mcpPath != null then "${baseUrl}${mcpPath}" else null;
      icon = svc.icon or null;
      description = svc.description or null;
    };

  normalize = catalog: mapAttrsToList normalizeService catalog.services;

  # ── Homepage adapter ────────────────────────────────────────────────

  toHomepage =
    catalog:
    let
      normalized = normalize catalog;
      withUi = filter (s: s.uiUrl != null) normalized;
      grouped = groupBy (s: s.group) withUi;
    in
    mapAttrsToList (group: svcs: {
      ${group} = map (s: {
        ${s.name} = {
          href = s.uiUrl;
          inherit (s) icon description;
        }
        // optionalAttrs (s.healthUrl != null) { siteMonitor = s.healthUrl; };
      }) svcs;
    }) grouped;

  # ── JSON catalog ────────────────────────────────────────────────────

  toCatalogJSON =
    catalog:
    let
      normalized = normalize catalog;
    in
    {
      version = 1;
      services = normalized;
    };

  # ── Exported API ─────────────────────────────────────────────────────

  catalog = {
    inherit defaults services;
  };
in
{
  inherit
    catalog
    normalize
    toHomepage
    toCatalogJSON
    ;
  inherit (catalog) services defaults;
}
