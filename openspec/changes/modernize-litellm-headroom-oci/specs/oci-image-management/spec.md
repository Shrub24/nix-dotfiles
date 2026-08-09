## ADDED Requirements

### Requirement: OCI image references have a canonical pinned policy
The system SHALL define each externally sourced OCI image reference used by Home Manager services in one repo-managed policy file as a version tag and immutable digest.

#### Scenario: Service consumes a managed OCI image
- **WHEN** a service needs an externally sourced OCI image
- **THEN** its derivation or service wiring SHALL consume the image reference from the canonical policy file
- **AND** the policy reference SHALL include both an explicit tag and `sha256` manifest digest

### Requirement: Renovate proposes flake and OCI image updates
The repository SHALL configure Renovate to detect flake input updates and version/digest updates to canonical OCI image references.

#### Scenario: A tracked upstream releases an update
- **WHEN** Renovate detects a newer supported flake input or OCI image version
- **THEN** it SHALL create an update proposal using the appropriate Nix or OCI dependency manager

### Requirement: Derived image source changes preserve Nix content verification
The system SHALL retain the Nix content hash required by `dockerTools.pullImage` when a patched local image derives from a managed upstream OCI reference.

#### Scenario: LiteLLM upstream reference is updated
- **WHEN** the pinned LiteLLM upstream OCI reference changes
- **THEN** the corresponding `dockerTools.pullImage` content hash SHALL be regenerated and validated before the derived image is accepted
