# Agent discipline

## Each discipline has one source

**Id:** dce72346-3050-4a45-9281-43b1fa732e5b
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

`lean-implementation` owns implementation scope, robustness and completion. `testing-discipline` owns validation choice and test value. Agent definitions and the global `AGENTS.md` point to those skills rather than repeating their rules. `CONVENTIONS.md` applies them to this repository's boundaries, and role definitions keep role mechanics such as escalation and report shape. Each rule therefore changes in one place.

**Alternatives:** unknown.
**Reason:** unknown; the source states the consequence, that each rule changes in one place.
