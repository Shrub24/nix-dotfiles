# Pi-herdsman

## Long-lived sessions re-read session transcripts on every refresh pass

**Id:** b7cc744e-4189-46bf-9db0-9119a7700b19
**Type:** incident
**Status:** active
**Evidence:** confirmed
**Source:** measurement in this repository — /proc I/O deltas, a parent-side strace, and an agent-directory A/B, read against the extension's own source
**Verification:** corroborated — with the shared agent-directory state present, a fresh session now reads about 0.25 MB/s with 1.5% CPU and flat RSS, where the same setup read 16.8 MB/s and burned 0.2–0.9 of a core before the fix
**Revisit when:** herdsman's managed-agent state or its refresh timers change again, or a long-lived session starts reading I/O while nothing is streaming

Every session holding the herdsman extension sat at 0.2–0.9 of a core, read
tens of megabytes a second from page cache, and sawtoothed its RSS by a
gigabyte. `read_bytes` stayed at zero throughout, which is why disk counters,
file atimes (misleading under `relatime`) and machine-wide writer counts all
came back clean, and why a streamed socket was ruled out early — no process on
the machine wrote at that rate. It was not Pi-Bolt either: stock pi sessions
showed the same numbers.

The reads were Pi session transcripts — the lead's own and other workspaces'
children — re-read in bursts on the main thread. A refresh pass enumerates every
persisted managed-agent record, and for each record without a cached definition
opens that agent's session file and parses it end to end to recover a header
entry herdsman had written at the start; a second full read follows for
transcript targets. The mailbox archive is global and never pruned, so the work
grew with every agent the lead had ever spawned, while the timers that call the
pass keep running in an idle session.

**Reason:** the state is what the pass reads, so an agent directory with fresh
state was quiet and the shared one burned — that A/B is what identified the
pass rather than any single extension or the runtime. The fix belongs in
herdsman: stop re-reading transcripts on a recurring refresh and cache what the
pass needs. It landed upstream, and it is what this repository runs, since
herdsman loads from the pinned extension sources at runtime rather than from a
compiled binary.

**Rejected alternative:** clear the persisted agent state as the workaround, or
restart sessions on a timer. Both remove the history along with the symptom —
those records are what a lead needs to supervise the agents it spawned — and
neither survives the next long session.

**Consequence:** a session's idle cost no longer grows with the number of agents
it has ever spawned. The pass still walks that state, so a future change to its
timers, or to what it caches, can bring the same shape back; the measured
baseline above is what to compare against.
