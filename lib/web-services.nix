# Web service catalog — single source of truth for localhost web service metadata.
#
# This file defines service-local facts only: ports, scheme, endpoint paths,
# and display metadata. Public routing, TLS, Cloudflare, and OIDC config belong
# in the homelab repo's web-services.nix, not here.
#
# Derivation rules:
#   baseUrl    = "${scheme}://${host}:${toString port}"
#   uiUrl      = baseUrl + ui.path      (null if no ui.path)
#   healthUrl  = baseUrl + health.path   (null if no health.path)
#   openapiUrl = baseUrl + openapi.path  (null if no openapi.path)
#
# Homepage rule: only services with a ui.path appear in homepage output.
{
  lib,
  pkgs,
}:

let
  inherit (lib)
    optionalAttrs
    mapAttrs
    mapAttrsToList
    filter
    hasAttr
    groupBy
    listToAttrs
    ;

  # ── Catalog data (SSOT) ──────────────────────────────────────────────

  defaults = {
    scheme = "http";
    host = "localhost";
    group = "AI Services";
  };

  services = {
    litellm = {
      name = "LiteLLM";
      port = 8765;
      icon = "litellm";
      description = "LLM API gateway";
      ui.path = "/";
      health.path = "/health";
      openapi.path = "/openapi.json";
    };

    docs-mcp = {
      name = "Docs MCP";
      port = 6280;
      icon = "openai";
      description = "Grounded docs MCP server";
      ui.path = "/";
    };

    qmd = {
      name = "QMD";
      port = 8181;
      icon = "si-markdown";
      description = "Local markdown search engine";
      ui.path = "/";
    };

    agentmemory = {
      name = "Agentmemory";
      port = 3113;
      icon = "si-n8n";
      description = "Persistent memory viewer";
      ui.path = "/";
      health.path = "/";
    };
  };

  # ── Normalization ───────────────────────────────────────────────────

  # Merge a service entry with defaults and derive URLs.
  normalizeService =
    id: svc:
    let
      scheme = svc.scheme or defaults.scheme;
      host = svc.host or defaults.host;
      port = svc.port;
      baseUrl = "${scheme}://${host}:${toString port}";
      uiPath = svc.ui.path or null;
      healthPath = svc.health.path or null;
      openapiPath = svc.openapi.path or null;
    in
    {
      inherit id;
      name = svc.name;
      group = svc.group or defaults.group;
      port = svc.port;
      inherit scheme host baseUrl;
      uiUrl = if uiPath != null then "${baseUrl}${uiPath}" else null;
      healthUrl = if healthPath != null then "${baseUrl}${healthPath}" else null;
      openapiUrl = if openapiPath != null then "${baseUrl}${openapiPath}" else null;
      icon = svc.icon or null;
      description = svc.description or null;
    };

  # Normalize all services into a list.
  normalize = catalog: mapAttrsToList normalizeService catalog.services;

  # ── Homepage adapter ────────────────────────────────────────────────

  # Render homepage-compatible grouped output.
  # Only services with a uiUrl (i.e., ui.path exists) are included.
  toHomepage =
    catalog:
    let
      normalized = normalize catalog;
      withUi = filter (s: s.uiUrl != null) normalized;
      grouped = groupBy (s: s.group) withUi;
    in
    mapAttrsToList (group: svcs: {
      ${group} = map (s: {
        ${s.name} = (
          {
            href = s.uiUrl;
            icon = s.icon;
            description = s.description;
          }
          // optionalAttrs (s.healthUrl != null) { siteMonitor = s.healthUrl; }
        );
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
  services = catalog.services;
  defaults = catalog.defaults;
}
