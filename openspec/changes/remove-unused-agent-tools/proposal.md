## Why

Agentmemory and III Engine are inactive but still add packages, Home Manager options, service/catalog entries, and stale documentation. Removing them reduces the deployed closure and restores the repository's configuration and documentation to its actual operating posture.

## What Changes

- **BREAKING** Remove the local `agentmemory` and `iii-engine` derivations, their overlay registrations, and Agentmemory's Home Manager module, service, Hermes integration, and web-service catalog entry.
- Remove dormant host configuration and obsolete unfree policy for those tools.
- Update active documentation to describe the remaining agent stack accurately.

## Capabilities

### New Capabilities
- `agent-tool-retirement`: Retire inactive agent tools without leaving runtime, package, catalog, or documentation references.

### Modified Capabilities

## Impact

- Affects `flake.nix`, `pkgs/`, `modules/home/agents/`, `modules/home/nix.nix`, `lib/web-services.nix`, the Arch host composition, and active documentation.
- Removes the `agentmemory` command, its user service/viewer catalog entry, and III Engine from the Home Manager configuration.
