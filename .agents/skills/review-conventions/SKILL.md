---
name: review-conventions
description: Review a diff, a path, or the whole tree of this Nix repository against its own conventions and durable decisions — dendritic structure, aspect purity, validation placement, native-module use, comment hygiene, privilege split. Use when reviewing changes here, before committing, or when asked to audit the repo for convention drift.
---

# Review against this repository's conventions

Rules live in `CONVENTIONS.md` (pattern rules and its Review Checklist) and
`ARCHITECTURE.md` (boundaries and Durable Decisions). Read both first; this
skill adds only how to hunt and how to report. The generic standard for
minimality and test value is the `lean-implementation` skill.

## Target

Default to the working-copy change: `jj --no-pager diff` (this repo is
jj-managed). Review a named path or the whole `modules/` tree when asked, and
rank findings biggest cut first.

## Hunt

Run these over the target, then read each hit in context. A hit is a finding
only when the rule applies there.

| Tag        | Hunt                                                                                                                                                                                                                 | Rule                                                                                                                                                   |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `guard:`   | `assert`, `throw`, `abort`, `tryEval`, `or false`/`or default`, `test -f`, `mkIf` on a value the aspect computes                                                                                                     | CONVENTIONS → Validation. Boundaries listed there are exempt, as are `programs.<other>.enable or false` probes and `or` on pinned external registries. |
| `native:`  | hand-written unit, timer, config file, activation script or env var                                                                                                                                                  | CONVENTIONS → Prefer the Native Module. Name the native option.                                                                                        |
| `struct:`  | `specialArgs`/`extraSpecialArgs`, a registry key read inside an aspect, a hardcoded hostname or user, import-order semantics, an inline derivation, a hand-edited `flake.nix`, a non-`_` raw module under `modules/` | CONVENTIONS → Dendritic Structure; ARCHITECTURE → Composition.                                                                                         |
| `style:`   | `with lib;`, `pkgs.system`, `builtins` where `lib` has it, a single-use `let`, an option with one consumer                                                                                                           | CONVENTIONS → Module Style.                                                                                                                            |
| `scope:`   | daemon or root-owned state in a Home Manager aspect; a system secret rendered into user state; a store symlink for a file an application rewrites; GC owned twice                                                    | ARCHITECTURE → Secrets & Privilege, Service Lifecycle, Durable Decisions.                                                                              |
| `comment:` | restated option, change narration, task ids, a decision re-argued at its use site                                                                                                                                    | CONVENTIONS → Comments.                                                                                                                                |
| `dup:`     | a value in two files; a second statement of a recorded decision                                                                                                                                                      | CONVENTIONS → Review Checklist.                                                                                                                        |
| `agent:`   | a `tools` entry the child runtime does not register at launch; a skill named in agent frontmatter with no directory                                                                                                  | CONVENTIONS → Module Style.                                                                                                                            |

Finish with the Review Checklist's last item: `nix flake check --no-build --no-write-lock-file`. Report it as a command for the
owner to run unless you were asked to run it.

## Report

One line per finding: `<path>:L<line>: <tag> <what>. <fix>. (<rule section>)`.
End with `net: -<N> lines possible.`; when nothing qualifies, `No convention
drift found.` and stop.

Scope is convention drift. Correctness, security and performance findings go to
a normal review pass, and pre-existing drift outside the target is listed once
at the end as debt, separate from findings. This skill lists findings and
applies none.
