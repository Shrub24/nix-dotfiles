# Pi-Bolt fork release

## A tag supplies the source; the runtime is a separate asset keyed to the engine stamp

**Id:** 8cd16a96-d846-4e6c-b4aa-1e95c3d510fe
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Verification:** corroborated — the runtime archive's hash is unchanged across `bolt-v0.7.2` and the previous tag, and the engine stamp computed from both trees matches
**Revisit when:** the fork publishes its own runtime asset, or upstream changes what the runtime stamp covers

The pin consumes `Shrub24/Pi-Bolt` at `bolt-v0.7.2`, which bundles Pi
coding-agent 1.1.0. A tag supplies the source tree; the compiled engine the AOT
step builds against is a separate release asset,
`pi-bolt-runtime-linux-x64.tar.gz`. A tag whose engine stamp equals the previous
release's reuses that release's runtime, and the stamp covers the webkit and bun
pins, both patches and both runtime build scripts — so the archive's bytes, and
its hash, do not move with the version.

**Reason:** the fork's releases carry no assets of their own. Actions does not
run there, and `release.yml` will not build a runtime for an unchanged engine
anyway — it asks for one built by hand on Linux and on a Mac and uploaded to the
tag's draft.

**Rejected alternatives:** pointing the runtime URL at the upstream release that
carries the archive splits one owner's two pins across repositories, and the
owner's own update step writes both from one root, so it would undo itself.
Building a fresh runtime would diverge from upstream's artifact for no gain.

**Consequence:** a fork release needs the runtime archive uploaded before the pin
can move:

```sh
gh release download bolt-v<previous> --repo opensec-git/Pi-Bolt \
  --pattern 'pi-bolt-runtime-linux-x64.tar.gz' --dir /tmp/rt
gh release upload bolt-v<tag> /tmp/rt/pi-bolt-runtime-linux-x64.tar.gz \
  --repo Shrub24/Pi-Bolt
```
