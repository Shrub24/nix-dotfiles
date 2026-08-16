## MODIFIED Requirements

### Requirement: OpenCode plugin registration

This capability is superseded. The repository no longer ships the `snip` CLI or registers the `opencode-snip` plugin; the standardize-dendritic-nix-architecture change retired both. Reintroduce from nixpkgs together if filtering is wanted again.

#### Scenario: OpenCode config rendered

- **WHEN** the managed OpenCode configuration is materialized
- **THEN** the plugin list SHALL NOT include `opencode-snip` while the capability remains superseded

## REMOVED Requirements

### Requirement: snip-backed shell filtering

**Reason**: Snip is not part of the active Home Manager environment.
**Migration**: Use ordinary shell execution; reintroduce the nixpkgs Snip package and plugin together if filtering is wanted again.

### Requirement: Unsupported commands passthrough

**Reason**: This behavior belonged solely to the removed OpenCode plugin integration.
**Migration**: No repository-local fallback is required after removing the plugin.
