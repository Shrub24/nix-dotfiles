# Pi-Bolt build ownership

## The payload is built by Pi-Bolt's own flake; this repository owns the launchers

**Id:** 17f83595-c9d6-4aa7-93a5-5b9c52d6a137
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** Pi-Bolt.nix's flake and `nix/pi-bolt.nix` at the revision the `pi-bolt-nix` input locks
**Verification:** corroborated — `nix build .#pi-bolt` compiles the module's 22 lead plugins into a payload built from the release source (`plugins from /build/plugins/plugins.ts`, Pi 1.3.0, Pi-Bolt 0.9.5, JIT on), whose `doctor` reports `(this Pi-Bolt)`, the 22 rows among its `builtin:<id>` entries and no problems, and whose install check registers a compiled provider through both launchers with discovery disabled; `nix flake check` passes for both hosts
**Revisit when:** the plugin interface merges upstream and the flake is retired, or a recipe needs a build step the flake's plugin builder does not expose

Pi-Bolt compiled ahead of time, with the plugins a Nix expression selects, is
built by the `pi-bolt-nix` flake: it builds Pi from the release source, stages
the plugins into the tree, and compiles them with Pi-Bolt's own
`scripts/build-pi.sh --plugins`. It also owns the release and runtime pins.
This repository consumes it as an input, and keeps the plugin recipes, the
selection, and the launchers with what they enable. `pkgs/default.nix` reads the
flake's package and plugin scope from the base package set extended with the
flake's overlay, because the `pi-bolt` this repository publishes is the
launchers and would shadow the payload the recipes compile into.

**Reason:** the interface under review should live with its mechanism, and the
step that binds a plugin's imports to the executable's own modules is the one
that has to be maintained — an arrangement that kept the compile step here left
the release pin, the kit fetch and a tsconfig workaround here while the
interface they compiled against lived in the other repository, and its kit path
re-armed the class-binding trap in silence. One author for the release and the
runtime keeps the verification chain in one place, where a release's signed
checksums can be checked against a pinned key once instead of per consumer.

**Rejected alternatives:** keeping this repository's own compile step over the
release kit and runtime — the previous arrangement, whose release pin had to
move by hand and whose plugin binding depended on a staged tsconfig. Vendoring
the flake's builder into `pkgs/` — the repository would then carry a copy of the
interface under review, free to drift from the thing it exists to test.

**Consequence:** bumping Pi-Bolt is `nix flake update pi-bolt-nix`, and no
package here carries a Pi-Bolt updater. A source bump rebuilds Pi's workspace
before the payload, since the flake publishes no binary cache; the payload
derivation stays shared, so a launcher or row change reuses its AOT build. The
package asserts the outcome rather than the mechanism: its install check runs
`doctor` and requires each row to be named among the compiled builtins.
