## ADDED Requirements

### Requirement: Fetch iii-engine release binary
The derivation SHALL fetch the prebuilt static `iii` binary from GitHub releases for `x86_64-unknown-linux-gnu`.

- **Source**: `https://github.com/iii-hq/iii/releases/download/iii/v{VERSION}/iii-{TARGET}.tar.gz`
- **Version**: `0.11.2` (locked to match agentmemory's docker-compose.yml pin)
- **Target**: `x86_64-unknown-linux-gnu` (musl target for fully static binary)

#### Scenario: Fetch succeeds
- **WHEN** the derivation is built with default parameters
- **THEN** the tarball is fetched from GitHub releases with verified hash

#### Scenario: Binary is executable
- **WHEN** the derivation is installed
- **THEN** `$out/bin/iii` exists and is executable

### Requirement: Static binary, no runtime deps
The derivation SHALL install the binary as-is without wrapper scripts, patchelf, or runtime library dependencies.

#### Scenario: No shared library dependencies
- **WHEN** `ldd $out/bin/iii` is run
- **THEN** it reports "not a dynamic executable" or static linking

### Requirement: Version passthru
The derivation SHALL expose a `version` passthru for easy version bumps when agentmemory updates its engine pin.

#### Scenario: Version is accessible
- **WHEN** `pkgs.iii-engine.version` is evaluated
- **THEN** it returns the pinned version string

### Requirement: License metadata
The derivation SHALL set `meta.license` to reflect the ELv2 license.

#### Scenario: License is documented
- **WHEN** `pkgs.iii-engine.meta.license` is inspected
- **THEN** it indicates ELv2 or similar source-available license
