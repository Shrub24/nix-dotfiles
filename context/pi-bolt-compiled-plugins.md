# Pi-Bolt compiled plugins

## Compiled extensions resolve Pi's dist modules, not the repository's src

**Id:** 1f9cb424-2f01-4008-826c-5d3c644adb7a
**Type:** decision
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** measurement in this repository — a headless tmux pane A/B across three launcher arms, with an in-process probe logging whether the patched method was reached
**Verification:** corroborated — before the fix the compiled copy installed its patch and never reached it, rendering a plain indented user message; the artifact built after the fix renders the compact bordered block in the same pane test and starts with no extension-load failures
**Revisit when:** Pi-Bolt's bundling or plugin-copy layout changes upstream, or the staged tsconfig's mirrored `paths` no longer match the Pi release being built against

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
