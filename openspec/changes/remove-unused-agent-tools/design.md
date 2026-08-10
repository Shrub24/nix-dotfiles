## Context

Agentmemory is disabled in the host configuration but remains wired through a local derivation, package overlay, Home Manager module, Hermes integration, web-service catalog, and documentation. Its derivation also depends on III Engine, which otherwise has no active consumer.

## Goals / Non-Goals

**Goals:**
- Remove both tools atomically from active configuration and maintained documentation.
- Preserve existing historical change records without treating them as maintained documentation.
- Leave the flake evaluable without either package.

**Non-Goals:**
- Replace Agentmemory with another memory service.
- Alter ByteRover or the remaining agent stack.
- Rewrite historical archived change records.

## Decisions

### Delete complete inactive ownership boundaries

Delete the local derivations and Agentmemory module rather than retaining disabled options or overlays. These are unused and have no supported compatibility contract; keeping them would preserve stale closure and documentation surface.

### Remove all active consumers in one change

Remove the flake overlay, module import, dormant host block, Hermes conditional integration, unfree allowlist entry, and catalog entry together. This keeps evaluation valid at every completed revision and prevents a hidden consumer from retaining the packages.

### Treat historical change records as history, not current documentation

Update maintained docs only. Do not rewrite existing OpenSpec change records, archived records, or ByteRover's generated context cache.

## Risks / Trade-offs

- [A hidden active reference remains] → Run exhaustive reference checks plus flake evaluation.
- [A user still depends on the retired command or service] → Revert the removal; the configuration has no persisted service-state migration.
- [Documentation retains stale current claims] → Sweep maintained docs in the same change and review the rendered diff.

## Migration Plan

1. Remove active derivations, modules, overlays, host wiring, and catalog entries.
2. Update maintained documentation.
3. Evaluate the flake and Home Manager activation package.
4. Apply the Home Manager generation; rollback by restoring the prior generation if an undiscovered dependency exists.
