---
name: lean-implementation
description: Implementation discipline — smallest coherent change, working behaviour before hardening, validation at real boundaries, tests that catch plausible regressions, comments only for what code cannot say, and a firm definition of done. Use before writing or changing code, when deciding what to validate or test, and when deciding whether a slice is finished.
---

# Lean implementation

An implementation task exists to deliver working behaviour. Deliver it as the
smallest coherent change that satisfies the real requirement. Volume, defensive
completeness and exhaustive coverage are costs that need a reason, not signs of
quality.

## Order of work

Build a _vertical slice_:

1. **Find the seam.** Read the code the change touches and trace the real flow
   to where the behaviour enters the production path. The smallest diff in the
   wrong place is a second bug. Search the repository's `context/` for entries
   on what you touch: a recorded workaround or rejected alternative decides
   whether the obvious change is safe.
2. **Make it work.** Get the smallest production behaviour running end to end
   through that seam.
3. **Verify it** with the cheapest check that would fail if the behaviour broke.
4. **Simplify the diff.** Remove scaffolding, debug output, dead branches and
   anything the final shape no longer needs.
5. **Harden** only where a concrete risk calls for it.

Infrastructure follows a consumer. A codec, schema, abstraction, helper or
option earns its place when production code in this change uses it, so build it
inside the slice that needs it rather than ahead of it.

Messiness while solving the problem is fine. The delivered diff is clean.

## Code

- Write modern, idiomatic, concise code with flat structure. Let types and names
  carry the meaning, and give each concept one name.
- Reuse before writing, in this order: what the repository already has, the
  standard library, the platform's native feature, an installed dependency.
  A new dependency needs a reason none of these meets.
- Prefer deletion to addition and boring to clever.
- Fix a bug at its cause, once, where the callers converge, after checking who
  else calls what you change. Patching only the reported path leaves siblings
  broken.
- Write for the consumers that exist. Abstractions without a second user, unused
  parameters, options for values that never vary and extension points for
  hypothetical callers are scope the task did not ask for.
- Follow the repository's good patterns. When the local pattern is clearly poor,
  keep the change coherent: use the better shape where it stays local, or match
  the pattern where diverging would split the codebase. Either way, report the
  debt as a follow-up rather than refactoring the wider pattern.

## Validation and failure

- Validate at boundaries: external or untrusted input, persistence and wire
  formats, public APIs, security boundaries, and places where invalid state does
  real damage.
- Inside typed or internal flows, state an invariant once, where it is
  established (a type, a constructor, one assertion), and let a broken invariant
  fail loudly. A guard at every use site hides the bug it suspects.
- Let programming errors surface. A fallback belongs only where recovery is part
  of the contract.
- Trust boundaries, data-loss handling and security are never what gets
  trimmed.
- Scale robustness to real risk, not to the number of invalid states you can
  imagine.

## Tests

A test earns its place when a plausible wrong implementation would fail it.
Aim tests at observable contracts, important invariants, plausible regressions,
meaningful state transitions and real failure or recovery boundaries.

Spend tests on behaviour, once: one test per invariant at the layer that owns
it, rather than every permutation, implementation details, structurally
impossible states, or the same invariant again at each layer.

The main behaviour exists end to end before the suite grows. Exhaustive
matrices belong where exhaustiveness is itself the requirement — parsers, wire
formats, security checks.

## Comments

Code carries control flow and obvious choices. Comments carry what code cannot:
non-obvious invariants, structural constraints, compatibility footguns,
surprising lifecycle behaviour, API docstrings, and the known ceiling of a
deliberate shortcut, written as a `HACK:` (the limit and the upgrade path).
Deferred work is a `TODO:` and known-wrong behaviour a `FIXME:`, each naming
what retires it. Longer rationale belongs in
the repository's docs, design records or OpenSpec artifacts.

## The why

Lean comments move rationale out of the source, so it needs a home. When a
change makes a non-obvious choice, rejects a plausible alternative, or adds a
workaround, write the reason where the repository keeps durable decisions
(a `context/` directory when keep-the-why is set up, otherwise ARCHITECTURE.md or the change's design document), and put
the change-level reason in the commit message. An entry states the decision,
the reason, the rejected alternative, and what would make it worth revisiting.

Propose these entries in the report; the owner lands them. Choices with no
rejected alternative and no surprise need no entry.

## Scope

- The requested behaviour is the scope. Cleanups, hardening and adjacent fixes
  found along the way are follow-ups: list them in the report.
- When an edge case does not block the main path, note it, finish the main
  path, then judge whether it matters.
- When the owner asks for the fuller version, build it.
- A new architecture or product decision goes to whoever owns the task, not into
  the implementation.

## Done

A slice is done when:

- the requested behaviour works through the production path;
- a check that would fail if it broke has passed;
- everything left in the diff has a current consumer;
- worthwhile follow-ups are listed, not implemented.

Done is not the absence of any further conceivable test, guard or improvement.
When these four hold, stop and report in a few lines: what changed, what was
verified, what was skipped and when it would be worth adding.
