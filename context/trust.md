# Trust

## Trust is its own door

**Id:** 59bd9fcd-ed22-4f73-a341-d4d3863d82ad
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

Which machines this one talks to is a separate selection from which may build for it. It is resolved through the contract's `resolveHosts`, not through a build profile. Trust never implies use, and use never implies trust, so naming a host for one cannot silently grant the other. Host keys land in the system known-hosts file rather than the user's, because ssh appends to the latter.

**Alternatives:** unknown.
**Reason:** unknown; the source states only that naming a host for one use cannot silently grant the other.
