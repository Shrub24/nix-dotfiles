# Package updates

## Package pins have one registered owner

**Id:** 25f7be20-c2fc-4aeb-a4f4-752506978f72
**Type:** decision
**Status:** needs-review
**Evidence:** confirmed
**Source:** approved `adopt-fleet-package-updates` design and package update implementation
**Verification:** contradicted — the `pi-bolt-nix` flake now owns the Pi-Bolt release, its runtime and the pin, and `pkgs/pi-bolt` carries no `src`/`npmDepsHash`/updater, so the tree registers three owners (Pi plugins, xberg-cli, codexbar), not four
**Revisit when:** nix-update locator behavior or the fleet package-update contract changes

The repository uses nix-fleet's package-update app with one registered owner per
pin set: Pi plugins, xberg-cli and codexbar. Derived outputs are not
separate owners. Each source pin is a literal in its owning file so nix-update
can identify where to write it.

**Reason:** nix-update locates package sources from the `src` attribute's
source position and reads release discovery from `pkg.src.urls`. A source
passed in from a different file or hidden behind a helper cannot be reliably
updated in place. One owner per related pin set keeps updates local and avoids
multiple packages writing one shared generated-source file.

**Rejected alternative:** retain generated pins in a shared file and direct
nix-update there. The shared file has multiple writers and nix-update's
multi-package-file support is a known weak spot, so each package instead owns
its pin literals.

**Consequence:** package-specific scripts preserve upstream pin semantics:
Pi plugins update exact npm versions and two branch-head commits; xberg
selects its stable release-tag family rather than component tags. Codexbar's
thin wrapper defaults to standard stable-release discovery and accepts
`CODEXBAR_UPDATE_VERSION` because the fleet app has no flag passthrough and
acceptance needs a reproducible exact target.

**Rejected alternative:** put every pin under one owner or register each npm
archive separately. A single Pi-Bolt owner would couple unrelated plugin
updates to its cadence; 24 individual npm owners would add unnecessary outputs
and split a set refreshed together.

## Update scripts edit tracked files in place

**Id:** 6a03e344-7e8a-4c76-9a81-50dafed4b2ac
**Type:** constraint
**Type:** workaround
**Status:** active
**Evidence:** confirmed
**Source:** nix-update behavior documented in the approved design; package-update candidate runs
**Verification:** corroborated — update scripts edit existing package files and recorded-target reruns completed without pin changes
**Revisit when:** nix-update evaluates the live working tree instead of its tracked-file flake metadata snapshot

The updater evaluates a `nix flake metadata` copy of tracked files while the
script edits the working tree. Existing tracked files with local modifications
are visible to the next evaluation, but a newly created file is not visible
until staged. This repository is jj-colocated, so update scripts must edit
existing package files rather than introduce a new file during an update.

**Reason:** otherwise an updater could report or evaluate a candidate against a
stale source snapshot, hiding the package edit from subsequent evaluation.

**Rejected alternative:** create a new pin file from the script and rely on
immediate re-evaluation. The metadata snapshot does not include it until the
file is staged, adding a staging-dependent update procedure and a failure mode.

**Consequence:** update scripts keep pin edits inside their already tracked
package expressions; partial edits remain reviewable if a run fails.

## A source URL has to carry the version attribute

**Id:** f5fa2f86-3658-4d0a-9536-909771fd1ad2
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** a partial pin left by a repo-wide update run, and the nix-update rewrite it exercised
**Verification:** corroborated — a real update after templating moved version, URL and hash together, and the built package reports the version it declares
**Revisit when:** nix-update changes how it retargets a source, or the fleet app gains flag passthrough

nix-update retargets a source by substituting the version inside its URL, so a
URL written as a version-less literal cannot be moved: the version attribute
changes, the URL and its hash do not, and the run still reports success.

**Reason:** a tag or release URL that names the version literally is the
ordinary shape for a prebuilt release, and it yields a package whose declared
version disagrees with the artifact it fetches. Nothing reads that version at
build time, so the disagreement only surfaces when something asks the binary
for its version.

**Consequence:** release-fetching recipes interpolate the version into the URL
(`finalAttrs.version`, or a `let`-bound `version` for a recipe that also keys
other attributes off it). Acceptance for these owners is a real round-trip:
varying the target and letting the updater move the pin. A recorded-target
rerun is idempotent and passes without exercising the rewrite at all, which is
how the defect survived the first acceptance pass here.

Two further nix-update details follow from the same code path and are worth
keeping at hand: `--version-regex` values need at least one capture group,
because the extracted version is the joined groups, and with no group every tag
is filtered out as unmatched; and a tag family that shares a repository with
component tags needs an anchored, grouped pattern so only the release tags pass.

## An update only adopts a release that carries the archive

**Id:** 21b55157-4327-4918-badd-a0c430cfd40c
**Type:** workaround
**Status:** active
**Evidence:** confirmed
**Source:** failed package-update runs for xberg-cli and codexbar after upstream tags/releases lacked the required Linux archive
**Verification:** corroborated — xberg-cli waits for release settling; CodexBar selects the newest release with its exact Linux archive; explicit unusable targets refuse before nix-update runs
**Revisit when:** upstream stops publishing releases before their assets, or another owner shows the same failure

xberg publishes a release before its build assets finish uploading — one release
exists with zero assets — and a release can be left that way entirely. CodexBar
has a related failure mode: its `v0.74.0` tag exists, but the release record is
absent and the expected `CodexBarCLI-v0.74.0-linux-x86_64.tar.gz` returns 404.
nix-update rewrites the version attribute before it prefetches the source, so
following such a tag leaves the pin on a URL that does not resolve, with a
version and hash that disagree. Both owners require their exact Linux CLI
archive before calling nix-update and fall back to the previous eligible
release when it is missing. Xberg additionally waits a day for release assets
to settle; CodexBar now selects the newest asset-backed release immediately.

**Reason:** the newest version is not evidence that a release is usable, and the
failure lands after the pin file has already been rewritten. The asset guard
prevents that failure without delaying CodexBar updates.

**Rejected alternative:** let the run fail and repeat it later. That leaves a
mismatched version and hash in the tree, so the next evaluation or build fails
for a reason unrelated to the pin's content.

**Consequence:** `XBERG_UPDATE_VERSION=vX.Y.Z` and
`CODEXBAR_UPDATE_VERSION=vX.Y.Z` select exact recorded targets, but refuse a tag
without its archive. `XBERG_UPDATE_SETTLING_HOURS` controls only xberg's
settling window; CodexBar has no settling delay. Pi-Bolt keeps its separate
policy: it prefetches its coupled runtime asset before rewriting anything, so it
cannot half-write.
