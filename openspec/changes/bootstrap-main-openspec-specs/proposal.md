## Why

`openspec/specs/` is empty even though several completed changes already define the repo's active capabilities. That leaves no canonical spec registry for future changes to check against before proposing new or modified behavior.

## What Changes

- Populate `openspec/specs/` with canonical specs distilled from completed changes whose delivered capabilities are still active.
- Add a small canonical registry index so maintainers can see which main specs exist and which change introduced each one.
- Establish a lifecycle convention for canonical specs so future changes can mark capabilities active or superseded without losing provenance.

## Capabilities

### New Capabilities
- `canonical-spec-registry`: Maintain a populated `openspec/specs/` tree with canonical specs for active capabilities derived from completed changes.
- `spec-lifecycle-convention`: Define how canonical specs record provenance and lifecycle state such as active or superseded.

### Modified Capabilities
- None.

## Impact

- Creates canonical spec files under `openspec/specs/` for active capabilities from completed changes.
- Adds an index file under `openspec/specs/` for discoverability and provenance.
- Does not change runtime behavior, package outputs, or service configuration.
