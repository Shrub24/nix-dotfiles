# Host package licensing

## Zotero's pinned Firefox ESR stays explicitly permitted

**Id:** eb173046-a2d2-407c-93fa-8de6009f3175
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** maintainer decision; locked Nixpkgs Zotero and Firefox ESR package definitions
**Revisit when:** Zotero stops pinning Firefox ESR 140 or moves to a supported runtime

Both hosts permit exactly `firefox-esr-140-bin-unwrapped-140.17.0esr` through
`permittedInsecurePackages`; each host-owned unfree predicate allows the ESR
package family required by Zotero. The shared `util-apps` aspect installs Zotero
on both hosts.

**Reason:** Zotero 10.0.4 hardcodes Nixpkgs's Firefox ESR 140 runtime, which
Nixpkgs marks insecure after its 2026-10-13 end of life. The exact-version
exception allows the selected Zotero package on both hosts while keeping Nix's
insecure gate active for other packages and future ESR builds.

**Rejected alternative:** keep ESR 140 blocked and remove or replace Zotero's
runtime. The maintainer chose to permit this exact package despite the known
lack of security updates.
