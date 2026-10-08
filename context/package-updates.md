# Package updates

## Package pins have one registered owner

**Id:** 25f7be20-c2fc-4aeb-a4f4-752506978f72
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** approved `adopt-fleet-package-updates` design and package update implementation
**Verification:** corroborated — package pins are literal in their owning files, the four owners are registered, and recorded-target runs completed
**Revisit when:** nix-update locator behavior or the fleet package-update contract changes

The repository uses nix-fleet's package-update app with one registered owner per
pin set: Pi-Bolt, Pi plugins, xberg-cli and codexbar. Derived outputs are not
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
Pi-Bolt updates its tag-keyed runtime asset and refreshes `npmDepsHash` as a
unit; Pi plugins update exact npm versions and two branch-head commits; xberg
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
