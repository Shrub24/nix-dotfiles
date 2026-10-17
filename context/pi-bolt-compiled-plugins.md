# Pi-Bolt compiled plugins

## Compiled extensions resolve Pi's dist modules, not the repository's src

**Id:** 1f9cb424-2f01-4008-826c-5d3c644adb7a
**Type:** constraint
**Status:** superseded
**Superseded by:** bab64056-2adc-4770-b947-712b957f2bc3
**Evidence:** confirmed
**Source:** measurement in this repository — a headless tmux pane A/B across three launcher arms, with an in-process probe logging whether the patched method was reached
**Verification:** contradicted — the payload is now built from the release source, where a plugin's imports resolve to the coding agent the executable runs (Pi-Bolt 0.9.5), so neither this repository's staged tsconfig nor the compile kit's `dist` layout is what binds a compiled plugin
**Revisit when:** the payload stops being built by `scripts/build-pi.sh --plugins`

Pi-Bolt's lead build showed the tool output its renderer styles while user
messages, intercom output and other chrome stayed at Pi's default. The
renderer was not broken: loaded at runtime by upstream pi or by the child
build, it rendered everything. Its compiled copy had installed its prototype
patch — an instrumented build logged the install — but the patched method was
never called, because it had patched a second copy of the host's classes.

**Reason:** The build copies each plugin's files under
`packages/coding-agent/.pibolt-plugins/src/`, where the nearest tsconfig is the
Pi repository root's, whose `paths` map every host package to
`packages/*/src`. The executable is bundled from `packages/*/dist`, so a
compiled plugin resolves a different copy of the host modules than the app
runs, and a class-shaped patch lands on a class nothing renders with. Staging a
`plugins/tsconfig.json` beside the plugin files — mirroring the root's
mappings, with the coding-agent entry moved to `../../dist/index.js` — binds
the compiled copy to the modules the binary actually contains.

**Rejected alternative:** Rule that compiled plugins cannot patch host classes
and keep each such plugin as a runtime `-e` row, which is how the renderer
worked in every build before this one. It costs a transpile and a runtime row
per plugin, and leaves the same trap armed for every other compiled extension
that patches a host class, because the failure is silent — API-level
registrations work while class-shaped patches do nothing.

**Consequence:** A compiled extension and a runtime-loaded one now behave the
same way, so a plugin can move between the two without changing what it can do.
The staged tsconfig is a copy of Pi's own mappings and has to move when they
do; the recipe's AOT ceiling is the largest single module's top-level bytecode
and is re-measured whenever the compiled plugin set changes.

## Compiled extensions bind the modules the executable runs

**Id:** bab64056-2adc-4770-b947-712b957f2bc3
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** Pi-Bolt 0.9.5's release notes for the fix — a from-source build resolves a plugin against the coding agent the executable runs (#52, PR #51) — and the payload package's install check, which runs `doctor`
**Verification:** corroborated — the install check of the payload this repository builds requires `doctor` to name every compiled row's id as `builtin:<id>`
**Revisit when:** a build pins a source older than 0.9.5, or the payload stops being built through `scripts/build-pi.sh --plugins`

A compiled plugin's classes have to be the classes the executable runs, and that
is a property of the build rather than of the plugin. The step that stages
plugins into the tree has to leave each plugin's imports resolving to the
compiled agent the executable contains; a plugin bound to a second copy of the
host's modules installs its patch on a class nothing renders with.

**Reason:** the failure is silent. API-level registrations work from the wrong
copy too, so the extension loads, the CLI reports no error and its tools are
found; only a class-shaped patch — the tool renderer's user-message component —
quietly does nothing. Pi-Bolt 0.9.5 made a from-source build resolve plugins
against the executable's own agent, which is the build this repository consumes,
so the binding is owned upstream and the acceptance test belongs to the package:
the install check runs `doctor` and requires each compiled plugin to be named.

**Rejected alternatives:** staging a `plugins/tsconfig.json` that remaps the
host packages to `dist` — the workaround the superseded entry prescribed — fixes
the symptom for one build path while leaving the trap armed for the next. A
class-identity fixture here, a plugin that imports a host class and reports
whether its patch is visible from the app's own instance, was declined: this
repository contributed the upstream fix rather than owning the behaviour, so a
regression should fail upstream's own check instead of being mirrored here.

**Consequence:** a plugin can move between compiled and runtime-loaded without
changing what it can do, and no repository-side build step has to know Pi's
module layout. What stays here is the AOT ceiling
(`maxAotCandidateBytecodeSize`), re-measured when the compiled set changes, and
the `doctor` assertion naming that set.
