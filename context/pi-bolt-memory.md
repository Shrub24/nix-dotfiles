# Pi-Bolt memory diagnostics

## Every session samples its own memory until the growth is explained

**Id:** 0fb249f5-6212-4b91-838a-db77d7275dfd
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** the RSS growth has an owner, or the samples themselves cost more than they
are worth — then `PI_MEMTRACE_EVERY=0` in the extension restores an off-by-default profiler

Pi-Bolt sessions sample RSS, anonymous memory, swap and heap figures once per turn into
`~/.local/share/pi-memtrace/<session>.jsonl`, and object-type counts every 25 samples. The
`/memtrace` menu turns it off per process.

**Reason:** sessions reach 2–4 GiB resident with transcripts under 2 MiB, so transcript size
does not explain them, and outside the process every candidate allocation looks identical in
`smaps`. The one heap snapshot taken so far reports a 67 MB JS heap across 497,041 nodes —
`ModuleRecord` alone is 25.9 MB — which is the kind of split that can only be read from inside
the runtime. A per-turn curve also separates a startup spike from accumulation, which no
external measurement can.

The path is cheap enough to leave on: a `/proc/self/status` and `smaps_rollup` read plus one
appended line of about 200 bytes per turn, wrapped so a diagnostic failure cannot break a turn.
Heap walks, forced GC and snapshots stay manual, since each pauses the process and a snapshot
writes tens of megabytes.

**Rejected alternative:** ship it off by default and enable it by hand in the session under
investigation. That was the original behaviour and it produced no samples at all — the sessions
that grew were the ones nobody had turned it on in.
