## Why

The host has no locally managed spreadsheet/database service for private,
single-user work. Grist provides this without adding a database daemon or
external service dependency.

## What Changes

- Add a Home Manager-managed, rootless Podman service for a pinned Grist OCI
  image.
- Persist Grist's bundled SQLite state under the user's local state directory.
- Keep the service local to the host, require login, and store its session
  secret with the existing user-scoped SOPS setup.
- Publish Grist in the web-service catalog and document the local service
  boundary.

## Capabilities

### New Capabilities

- `grist-oci-service`: Run a durable, single-user Grist instance as a
  localhost-only Home Manager user service.

### Modified Capabilities

None.

## Impact

- Affected configuration: `policy/oci-images.nix`, `lib/web-services.nix`,
  `modules/home/sops.nix`, a new Grist Home Manager module,
  `flake-modules/agents/services.nix`, and `hosts/arch/home.nix`.
- Affected encrypted data: `secrets/agents.yaml` gains the Grist session
  secret.
- Affected documentation: `docs/web-services-catalog.md` and
  `ARCHITECTURE.md`.
- No new flake inputs, custom derivations, system-manager modules, external
  databases, or reverse proxies are introduced.
