# Conventions

Shared implementation and review rules for these repositories. The general rules
apply across languages; the Nix sections describe the dendritic configuration
pattern. Repository-specific paths, commands and policies belong in the final
section, not in the shared rules.

Formatters and linters own mechanical style. This document covers choices they
cannot settle. Architecture documents describe boundaries; decision records
explain non-obvious choices and rejected alternatives.

## Scope and Simplicity

- Deliver the smallest coherent change through the real production path, not
  the smallest diff at an arbitrary call site.
- Reuse existing repository code, standard libraries and native platform features
  before adding a dependency or another implementation.
- Give each fact one authoritative owner. Derive consumer representations from
  that source rather than maintaining parallel lists or configuration tables.
- Extract genuine repeated behaviour, not merely similar-looking syntax. A small
  helper should remove duplication without hiding ownership or control flow.
- Add options, abstractions and extension points for current consumers, not
  hypothetical callers. A value that never varies rarely needs a public option.
- Remove solving scaffolds, debug output and unused parameters from the finished
  change. List unrelated improvements separately rather than expanding scope.

## Comments

Comment only where the code cannot carry the meaning. Judge necessity before
length: a shorter redundant comment is still redundant.

Remove comments that:

- restate an option name, assignment or operation;
- teach ordinary language, module-system or dendritic mechanics at a use site;
- narrate edits, migrations, past mistakes or what the file used to contain;
- describe an absence with no current consequence, such as an override not made;
- embed task numbers, completed plans, stale directives or session history;
- repeat architecture or re-argue a decision already recorded elsewhere.

Keep comments that identify a non-obvious invariant, dangerous operation,
compatibility constraint, load-order requirement or silent failure mode. A
negative statement earns its place only when the absence is load-bearing.

File headers and section dividers are welcome when they help navigate a long or
mixed-purpose file. Do not label every assignment or repeat obvious option names.
There is no comment-count or line-reduction target.

Use debt markers precisely:

- `TODO:` deferred work;
- `FIXME:` known-wrong behaviour;
- `HACK:` a deliberate workaround or limited shortcut.

State the constraint and what would retire the marker. An upstream issue or PR
can identify that trigger; a task identifier alone cannot. Keep the local warning
short and put extended reasoning in the decision record. Link only where the
reader needs that context, not at every use of an established pattern.

## Validation

Validate where data enters a contract or invalid state has a meaningful
consequence: external input, persistence and wire formats, public module options,
host composition, security and destructive operations.

Establish internal invariants once, through types, construction or a focused
assertion at their source. Do not repeatedly defend against impossible states in
values the repository constructs itself.

- Let native errors report missing required attributes, type mismatches and failed
  commands. Do not wrap them in a second guard that adds no useful contract.
- Keep assertions for relationships the type system cannot express, such as
  mutually exclusive selections or missing members of a required set.
- Do not turn programming errors into apparent success with fallback values,
  `tryEval`, ignored exit codes or catch-and-continue handling.
- Recover only when absence or failure is expected and the contract defines the
  fallback. External data does not automatically justify a default.
- Keep trust, secret-handling and data-loss checks proportionate to their risk.
  Minimalism is not a reason to remove them.

In Nix, `assert`, `throw`, `or`, `mkIf` and shell `test -f` are review prompts,
not forbidden syntax. Ask what boundary or invariant each one serves.

A sibling-aspect probe such as `config.programs.<other>.enable or false` can be
valid when the sibling is genuinely optional. A fallback on an external registry
key can be valid when that field's absence is supported. Neither should conceal
an input that is actually required.

## Tests and Verification

- Name the behaviour this repository owns and a plausible regression before
  adding a test. Test our selection, translation and integration, not a
  dependency's algorithms or the language's semantics.
- Use the cheapest faithful evidence: types and static checks, evaluated or
  rendered configuration, build checks, then runtime tests where needed.
- Exercise the production path. A helper test does not prove its caller reaches
  it; a source grep does not prove the configured behaviour works.
- Derive expected results independently of the implementation. Copying the
  production table into a fixture does not verify that table.
- Prefer observable relationships and effects over literal assignments,
  whole-object snapshots and incidental call order.
- Keep distinct regressions and meaningful security cases. Remove duplicate
  evidence, obsolete migration tests and fixtures coupled to harmless refactors.
- Zero new tests is acceptable when existing checks cover the change. A missing
  faithful check is a reported gap, not permission to claim verification.

State exactly what passed and what it establishes. Formatting, evaluation,
building and runtime behaviour are different claims. Record the revision and
relevant environment when reproducing a failure; a warm-store pass does not
establish cold-store behaviour. Local and CI validation should enforce the same
contract.

## Dead Code and Legacy Code

Remove code with no current consumer once its ownership and reachability are
established: dead branches, unused options, duplicate implementations, abandoned
helpers and obsolete compatibility layers.

- A search with no matches is not sufficient proof of dead code. Check discovery,
  generated references, runtime loading and external consumers where relevant.
- Read existing decision records before removing a surprising workaround.
- Do not keep an old implementation commented out or maintain two paths after a
  completed migration. Version control preserves the old source.
- Keep compatibility code only for a supported consumer or a concrete upstream
  limitation. Identify the condition that permits its removal.
- Retain an active migration inventory or provenance record while it still serves
  its purpose. Age or the word "legacy" alone is not grounds for deletion.
- Remove superseded documentation and tests with the implementation, or mark
  historical decision records as superseded. Do not leave contradictory guidance.
- Do not sweep unrelated working-copy changes into a cleanup or delete them as
  clutter. Establish ownership and keep them separate.

## Documentation

Give each kind of information one home:

| Location                           | Owns                                                                |
| ---------------------------------- | ------------------------------------------------------------------- |
| `README.md`, runbooks              | Setup, operation and recovery procedures                            |
| `CONVENTIONS.md`                   | Implementation and review rules                                     |
| `ARCHITECTURE.md`                  | Current structure, ownership and boundaries                         |
| Specs                              | Behavioural contracts                                               |
| Decision records (`context/` here) | Non-obvious choices, alternatives, constraints and revisit triggers |
| Source comments                    | Local constraints needed to read or safely change nearby code       |

Link rather than copy. Commit messages explain a change, but are not the sole home
of durable rationale. Record only reasoning that needs preserving, not an account
of every edit. Mark inference and unknown rationale rather than inventing it.

Verify factual descriptions against authoritative sources. Do not infer hardware
roles, ownership or upstream behaviour from convenient labels. When code and docs
disagree, establish which is wrong before changing either.

## Prefer the Native Module

Before writing a unit, timer, configuration file, activation script, shell hook or
environment bridge, check the native NixOS, Home Manager or upstream module.
Verify its semantics at the pinned version, not just its option name.

Use native lifecycle and restart mechanisms rather than activation orchestration
when they express the requirement. Hand-written machinery needs a concrete gap in
the native interface; record the rejected option and reason when non-obvious.

Respect privilege and state ownership. Root daemons and root-owned state belong
in the system layer; user programs and user services belong in the user layer.
Give each lifecycle operation one owner. Do not declare immutable store ownership
for logs or application-rewritten state.

## Dendritic Structure

- Organize by feature, not configuration class. A feature contributes its NixOS,
  Home Manager or nix-darwin aspects together where applicable.
- Every auto-discovered Nix file is a flake-parts module. Keep raw class modules
  and private Nix helpers under discovery-excluded underscore-prefixed segments.
- Publish named aspects through `flake.modules.<class>.<aspect>`. Discovery
  registers them; host composition selects them. Registration must not activate
  the feature on every host.
- Keep aspects host-agnostic. Resolve host identity and project host-specific
  policy at the composition boundary; do not read a named machine's registry
  entry inside a reusable feature.
- Share local values with `let` bindings and cross-file policy through typed
  module options. Do not use `specialArgs` or `extraSpecialArgs` as a facts bus,
  or add empty argument sets merely to advertise their absence.
- Keep the flake entrypoint plumbing-only. When using flake-file, declare inputs
  beside their owner and regenerate `flake.nix`; never edit generated content.
- Give shared pins an explicit authority and declare `follows` beside the input
  it redirects. Do not duplicate another repository's canonical inventory.
- Keep package recipes in the package layer, not inline in configuration aspects.
- Do not let incidental import-list order express feature policy. Use module
  merging, priorities and explicit dependencies for their intended purposes.

### Enables and Gates

Selecting an aspect is normally its feature gate. The aspect can directly set
`programs.<name>.enable = true` or `services.<name>.enable = true` using the native
module's interface. That assignment needs no comment explaining dendritic Nix.

Do not add a second custom `enable` option and wrap the whole aspect in `mkIf`
when omitting the aspect already provides the same choice. Remove both the
redundant declaration and its callers when simplifying such a gate.

Keep an option when it represents a real independent choice inside a selected
aspect, a supported reusable interface or host policy that composition alone does
not express. `mkIf` remains appropriate for those choices and genuine optional
integrations. Do not replace every custom option mechanically or remove native
upstream enable assignments.

### Feature Layout

- One contributor with assets: `feature.nix` beside `feature/`.
- Several real contributors: `feature/core.nix`, `feature/integrations.nix`, etc.,
  each contributing through normal module merging.
- Private Nix implementation: underscore-excluded files or directories.
- `default.nix`: an actual directory-import entrypoint, not a compulsory name for
  every feature directory.

Do not turn a flat feature into a directory hierarchy merely because it gained
assets. Non-Nix assets do not need discovery exclusions.

## Module Style

- Use `pkgs.stdenv.hostPlatform.system`, not `pkgs.system`.
- Avoid `with lib;`. `with pkgs;` in a package list is fine; do not then repeat
  `pkgs.` on its entries.
- Prefer established `lib` helpers to rebuilding their behaviour manually.
- Use a binding to share a value or name a meaningful concept. Inline single-use
  aliases that add neither clarity nor structure; do not optimise for use count.
- Name custom options for their owning feature, without colliding with upstream
  options. Keep implementation details out of the public option surface.

## Repository Application

In this repository:

- `modules/` is the only discovery root; raw modules use underscore exclusions.
- `pkgs/` owns package recipes; `context/` owns durable decisions.
- nix-fleet owns the shared platform pins and fleet inventory. This repository
  owns workstation composition and its repository-specific inputs and policy.
- Formatting is `nix fmt`; statix and deadnix provide mechanical Nix lint.
- The declared no-build validation command is
  `nix flake check --no-build --no-write-lock-file`. Its known cold-store limitation
  and a possible writable evaluation replacement are under investigation; neither
  should be reported as resolved without evidence.
- VM tests remain manual build/run tools, not CI build targets.
- Agent tool allowlists must name tools registered in the child runtime at launch,
  including any required extension flags. An installed extension alone does not
  establish that its tools are available.

## Review Checklist

1. Does every addition serve current behaviour, through the production path?
1. Is each fact owned once, with consumers deriving rather than copying it?
1. Does every comment add information, a useful warning or genuine navigation?
1. Does every guard enforce a real boundary or invariant without hiding failure?
1. Is any enable gate redundant with aspect selection?
1. Can native modules or lifecycle mechanisms replace custom machinery?
1. Is removed code actually unused, and is retained compatibility still needed?
1. Are docs current, non-duplicated and in the right place?
1. Does validation cover the owned behaviour, with important gaps stated?
1. Is the change free of unrelated work, debug scaffolding and speculative APIs?
