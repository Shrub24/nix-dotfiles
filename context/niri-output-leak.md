# niri output-layer leak

## Layer surfaces are unlinked before the output is dropped

**Id:** 8e0046e8-0171-4242-9dab-4b9cbfacab32
**Type:** workaround
**Status:** superseded
**Superseded by:** none — the patch was withdrawn from `pkgs/` with no replacement
**Evidence:** confirmed
**Source:** upstream pull request niri-wm/niri#4485; upstream issue niri-wm/niri#1457
**Revisit when:** niri is the working compositor again, or the fix lands in a release

niri _was_ built from `pkgs/niri/` with upstream's unmerged fix for layer
surfaces outliving the output they were mapped on. The override is gone and
nixpkgs' own niri is what the hosts select; the analysis below still describes
the bug the withdrawn patch addressed.

**Reason:** niri is not the working compositor while Umbriel is evaluated, and a
patched build is its own store hash — it matches no upstream cache, so every
nixpkgs move rebuilds niri instead of substituting it.

**Reason:** `Niri::remove_output` sends `close` to an output's layer surfaces but never
clears `mapped_layer_surfaces`, so a client that destroys such a layer after the output
is gone leaves its `MappedLayer` — and the dma-buf it holds — in the map for the rest of
the process's life. Every display disconnect retains that output's layer buffers. It is
the reported cause of niri reaching about 2 GB, 1.9 GB of it shared memory, when
monitors are cycled.

**Rejected alternative:** wait for the release and restart the compositor after each
monitor change. A restart is the only runtime remedy, since the retained layers are
reachable from no IPC, and it costs the session every time a cable moves.

**Unknown:** the patch covers layer surfaces only. A separate retention of output-sized
buffers was measured on the unpatched build — 23 buffers, 735 MiB, against one 4K
output — and is not explained by this diff.
