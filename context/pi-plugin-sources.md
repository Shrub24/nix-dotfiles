# Pi plugin sources

## Pi extension sources are pins, not a live checkout

**Id:** 520469d0-b788-4d5b-8689-567521a95cd3
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** measurement in this repository — the built generation's rendered `settings.json` and child-extension list, the deployed launcher script, and the two Pi-Bolt binaries
**Verification:** corroborated — every local plugin in the rendered settings is a store path from the `pi-extensions` input, OmniRoute's is a pinned checkout, no row references `~/Projects`, and the out-of-store symlink is gone from the generation
**Revisit when:** a plugin needs live-edit iteration badly enough to outweigh reproducibility, or its source moves outside the `pi-extensions` input and the package pins

Rows in `modules/agents/_pi-extensions.nix` named
`~/Projects/dev/custom/pi-extensions/<plugin>` for every plugin kept in a local
checkout, and OmniRoute was an out-of-store symlink into its fork, so the
running configuration loaded whatever was on disk. The compiled Pi-Bolt builds
read the same plugins from the pinned `pi-extensions` input, which meant the two
paths could disagree about the same plugin — a fix landed locally was live for
one and absent from the other. Rows now carry a placeholder resolved by
`rowPath`: `@extensions@` for the pinned input, `@recipe@<id>` for the source a
`pkgs/pi-plugins` recipe resolves (which is how OmniRoute reaches its
pinned `deploy/edge` checkout), and `@home@` only for the npm and git
installs that genuinely live in the home tree.

**Reason:** the same commit has to produce the same running configuration. With
a checkout in the path, the deployed plugins depended on uncommitted local
state, and the compiled and runtime halves of the same plugin set could sit on
different revisions without anything failing.

**Rejected alternative:** keep the live checkout for the runtime rows so a
plugin edit shows up without a rebuild. That is the asymmetry the change exists
to remove, and iteration does not need it — a local build can point the input at
the working copy with `--override-input pi-extensions
git+file:///home/saurabhj/Projects/dev/custom/pi-extensions`, and a normal
deployment moves the pin with `nix flake update pi-extensions`.

**Consequence:** editing a plugin no longer reaches a running session by itself;
it takes a pin bump and a switch, or an override-input build for a trial.
OmniRoute keeps its own literal checkout pin, so a source that is not an npm
tarball and not in the `pi-extensions` input still has a home.
