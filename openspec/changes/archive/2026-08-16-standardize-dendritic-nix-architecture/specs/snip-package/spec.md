## MODIFIED Requirements

### Requirement: tokf removal from active tooling

This capability is superseded. The repository no longer ships a custom `snip` derivation; `tokf` remains absent. The standardize-dendritic-nix-architecture change removed `pkgs.snip` (local 0.18.0 superseded by nixpkgs 0.24.1). Reintroduce `snip` from nixpkgs only if an active consumer requires it.

#### Scenario: Agent tools package set migrated

- **WHEN** the agent tools module is enabled after the retirement
- **THEN** the package set SHALL NOT include a custom `pkgs.snip` entry and SHALL NOT include `tokf`

## REMOVED Requirements

### Requirement: Pinned snip derivation

**Reason**: The custom package is unused and its original nixpkgs version-lag justification no longer holds.
**Migration**: Reintroduce `pkgs.snip` from nixpkgs only if an active consumer requires it.

### Requirement: snip CLI exposure

**Reason**: The active agent tools bundle does not install or consume Snip.
**Migration**: Add the nixpkgs package to the consuming feature if Snip is deliberately re-enabled.

### Requirement: Direct CLI verification

**Reason**: The repository no longer owns a custom Snip derivation to verify.
**Migration**: Use nixpkgs package checks if Snip is reintroduced.
