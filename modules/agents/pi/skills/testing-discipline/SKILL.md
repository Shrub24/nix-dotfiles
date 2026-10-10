---
name: testing-discipline
description: Choose tests that catch plausible regressions in repo-owned behaviour without mirroring implementation. Use when selecting validation for a code change, writing or changing tests, fixtures or mocks, reviewing test value, or simplifying brittle or expanding suites. Covers features, bug fixes and refactors; does not require adding tests to every change.
---

# Testing discipline

Tests are maintained code, not proof of diligence. A test earns its place by
catching a plausible regression in behaviour this repository owns that existing,
cheaper evidence would miss. Zero new tests is a valid outcome when existing
checks provide sufficient evidence for the change. Trust, security and data-loss
claims need evidence proportionate to their impact; minimality is not a reason
to leave them unverified. If faithful validation is unavailable, report the gap
to the owner rather than treating the change as verified.

## Establish the claim

Before adding or retaining a test, identify:

1. **Ownership.** What does this repository implement or promise? Focus on
   transformations, selection and routing, lifecycle and recovery, public
   contracts, security and data-loss boundaries, and integration joins we own.
   Leave dependency algorithms and language or framework semantics to their
   owners; test our use of them where our wiring can be wrong.
2. **Observable invariant.** State what must remain true after an internal
   refactor: inputs and outputs, state transitions, effective configuration, or
   externally reached behaviour. Filenames, imports, private helpers and call
   sequences matter only when they are themselves part of the contract.
3. **Plausible failure.** Name a realistic wrong implementation that could pass
   compilation, typing, linting, evaluation or build checks but violate the
   invariant. Historical regressions are strong evidence; an imaginable edge
   case is not automatically a requirement.
4. **Existing evidence.** Check types, assertions, validators, native framework
   checks, builds and existing tests. Evidence across layers can establish a
   claim without repeating it at every layer. Format acceptance and semantic
   correctness are different claims.
5. **Independent oracle.** Derive expected results from the contract. Use small,
   concrete examples whose answer is known independently of the production
   transformation. Importing the production table as the expected result, or
   copying it into the fixture, does not establish that the table is correct.

Keep this reasoning proportional: a short explanation is enough, not a new
artifact or checklist per test.

## Choose the smallest faithful boundary

Start with existing static, type, evaluation or build checks. If they cannot
catch the plausible failure, move to a direct pure-function or module test, a
component or adapter test, a composed integration test, or a live end-to-end
check. Choose by what the claim needs, not by a fixed quota for each layer.

Exercise the real code path at the boundary under test. Stub external services
and nondeterministic edges, not the behaviour being claimed. A helper test does
not establish that the real handler reaches it or can execute successfully.

Upstream acceptance can establish syntax or format validity while our
transformation still chooses the wrong destination or omits required state.
Test that owned meaning where it can go wrong; rely on the upstream validator
for what it already establishes. Deployment visibility is useful but does not
automatically replace pre-merge evidence for high-impact failures.

For declarative code, evaluated or rendered configuration can be the contract.
Assert relationships that our composition could break, such as selection,
isolation or lifecycle wiring, rather than repeating literal option assignments.
Place real-machine claims with the consumer that owns deployment or persistence.

## Select cases and make failures attributable

Keep cases for distinct owned decision branches, historical regressions, and
important trust or data-loss boundaries. Collapse cases that only vary spelling
or repeat a condition already established. A wider security matrix earns its
place when the cases have distinct consequences.

Group cheap related cases by contract, with failures naming the specific
invariant. For negative paths, assert the intended rejection or failure result;
an unrelated exception must fail the test, not count as successful rejection.

Vary inputs when it establishes real behaviour. For a bug fix, demonstrate that
the focused behavioural test fails on the broken version when practical, then
passes with the fix. A separate mutation harness or substrate comparison is not
a mandatory proof of diligence; it needs its own distinct risk to justify it.

## Keep the suite robust

Use minimal realistic stimuli, not fixtures that reconstruct every production
field. Assert salient effects. Whole-object snapshots, source greps, exact call
ordering and framework defaults need a contract-level reason; prefer assertions
on behaviour or effective output. Deterministic clocks and controlled edges are
better than real networks, arbitrary sleeps and retrying until green.

When a harmless refactor forces widespread fixture rewrites, inspect the
boundary and oracle before preserving the tests' shape. Simplify or remove
coupled checks. Retire migration scaffolds, historical structure checks and
duplicate evidence when their purpose ends. Tests of test machinery belong only
where that machinery itself is a maintained product with an owned contract.

## Use during development and review

Identify the owned invariant and existing evidence as the slice takes shape.
Load `tdd` when test-first development is requested or a failing behavioural
example would clarify the design; it owns the red–green–refactor workflow.
Test-first ceremony is not a reason to invent a test. Implement through the real seam, run
targeted validation, and add only missing evidence for meaningful risk.

Review what can now be deleted. Stop when further tests would not catch a
distinct plausible regression. Report what was validated and any important
claim left unverified; do not present a passing check as evidence beyond its
boundary. `lean-implementation` governs implementation scope and completion;
this skill governs test value and validation choice.

## Quick contrasts

- **Source presence → handling:** instead of grepping a helper import, dispatch
  a representative event through the real extension and assert the result.
- **Literal assignment → isolation:** instead of checking `enable = true` stays
  true, disable one related unit and check its hook or secret registration
  disappears while the others remain.
- **Table copy → routing:** instead of mirroring every generated field,
  exercise destination selection and check the effective output identity.
- **Dependency semantics → owned translation:** rely on an upstream parser's
  checks; test the distinct validation or translation rule we implement.
- **Upstream daemon → owned wiring:** check our queue and state-directory
  wiring; test machine-level persistence where deployment is owned.

**Decision rule:** if a test fails after a harmless refactor, or passes after the
owned behaviour breaks, its boundary or oracle is probably wrong.
