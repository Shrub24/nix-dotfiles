# Pi-Bolt fork source

## The compiled agent source follows a fork branch, not the release tag

**Id:** 8697e715-8a99-450f-ad5d-5b30576aaec5
**Type:** decision
**Status:** superseded
**Superseded by:** eac14512-df45-40f3-a76c-7176dce7f391
**Evidence:** confirmed
**Source:** `modules/flake/inputs.nix` (`pi-bolt-fork`, and `pi-bolt-nix.inputs.pi-bolt-source.follows`), Pi-Bolt.nix `docs/guides/plugins.md`, Pi-Bolt fork branch `fix/weak-render-owners` at `1c30560b`
**Verification:** contradicted — the fix landed upstream as Pi-Bolt 1.0.9 ("Memory after `/new`", #220 by @Shrub24), so `pi-bolt-source` follows the release tag again and the `pi-bolt-fork` input and its follow are removed
**Revisit when:** never as a follow — a fix that has not reached a release is carried by a tag bump, not by redirecting the source

Pi-Bolt.nix compiles `pi-bolt-source` into the payload and consumes the released engine for the runtime. The follow redirects that source to the fork, so a fix that has not reached a release still reaches the compiled agent. The released runtime is kept, which is why the source has to share the release's engine stamp: `nix/pi-bolt.nix` computes the source's stamp and throws when it differs from the runtime's, rather than building code against an engine it did not expect. Moving a fork branch therefore moves the runtime too — `fix/weak-render-owners` is built on 1.0.7 and could only be followed once Pi-Bolt.nix's release and runtime reached 1.0.7.

The branch is one commit on top of that release: `fix(tui): keep render owner subscriptions weak`, which stops render owners holding the rendered thinking-gutter strings alive after the session they belong to is gone.

The branch it replaced, `fix/compaction-system-snapshot-dedupe` (d6cde31e), stored each repeated compaction snapshot once per session file. That commit has no successor on the 1.0.7 line and was dropped rather than rebased, so a session with many compactions again repeats the full system prompt and tool state in each one.

**Resolution:** Pi-Bolt 1.0.9 released the fix (#220), so the follow was removed and the fork input dropped; the flake's `pi-bolt-source` is the release tag Pi-Bolt.nix pins. Recorded because the constraint it names outlives the branch: the source has to share the runtime's engine stamp, which is why a fork follow also forced a runtime move.
