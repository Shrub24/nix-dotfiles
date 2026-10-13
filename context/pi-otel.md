# Pi OpenTelemetry

## The run-trace fork stays pinned with the other extensions

**Id:** 8c2c6ad7-7ab4-4efd-9d20-bcf6ce6ba16b
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** the run-trace model reaches upstream, or the fork changes its dependency layout

Pi uses the `pi-otel` subtree from the `pi-extensions` input, not the npm
package of the same name. That npm name belongs to a different project. The
fork also differs from upstream `stnly/pi-otel`: it roots a trace at each
user-driven run rather than at a session that can remain open for hours. This
keeps the Langfuse/Latitude trace unit aligned with an interaction.

The pinned subtree carries source and a lockfile, but no `node_modules`.
`pkgs/pi-otel` supplies a runtime package directory using `importNpmLock`.
The dev-only Pi host entries are filtered out: they lack integrity hashes and
must not supply a second host beside the one Pi's loader provides. The matching
`importNpmLock.npmConfigHook` installs the lock-derived store sources; the usual
cache hook expects a different dependency-cache format.

**Alternative:** install upstream or the similarly named npm package, which
would change the trace model or the extension entirely. A live checkout would
also undo the repository's pinned-source boundary.

## Backend routing and credentials stay at the gateway

**Id:** 22abca36-5777-4b46-85d4-e3d9726bf888
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** the fleet changes OTLP admission or the producer needs another signal

Pi exports HTTP/protobuf traces to the NixOS collector's loopback producer
endpoint. That collector forwards only to the canonical fleet gateway; the
homelab owns Langfuse/Latitude fanout and their ingest credentials. Giving Pi
those credentials would split backend enrollment across every workstation and
managed child.

The user explicitly selected full capture, including prompts, completions and
tool arguments/results. Traces and metrics are enabled; logs and self-logs stay
off. Metrics cannot reach the LLM backends: the metrics pipeline names only the
remote-write destination, and Langfuse and Latitude accept traces alone, so the
signal is confined to the metrics store by construction. Per-generation
token/cost attributes remain in traces; the extension's session-end totals are
logs-only and therefore absent. Journal admission is unchanged by this choice.

**Alternative:** export directly to the backends from each Pi process, with
backend-specific endpoints and credentials on every producer.

## AOT keeps the runtime package as its source of dependencies

**Id:** a37c94e7-3183-458c-90d8-63921fed719c
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** a plugin update breaks AOT, or its build cost outweighs the launch benefit

The Pi-Bolt executable compiles the extension rather than parsing its TypeScript
and dependency closure at launch. The recipe stages `pkgs/pi-otel`, so stock
loads and compiled loads use the same source and lock-derived dependencies.
The runtime package stays in stock Pi's catalogue and the child extension
list; the compiled child filters that path as a duplicate.

Compilation removes the source-relative `package.json` path used for the
extension version. The recipe embeds the pinned manifest version instead;
without that patch the extension silently reports `0.0.0`. The runtime package
keeps its original file-based version lookup. Both compiled variants exported
synthetic traces carrying the correct `0.3.1` extension version. The merged
executable keeps both launchers on that one compiled copy.

**Alternative:** keep runtime loading for Pi-Bolt too. It works, but leaves this
extension outside the compiled launch path the user requested.

## The SDK closure exceeds the previous AOT bytecode limit

**Id:** 14a7cbdd-1cb1-4dbc-aee6-84c20a025d59
**Type:** workaround
**Status:** active
**Evidence:** confirmed
**Revisit when:** the plugin set or pinned source changes

The compiler rejected the previous `400000` ceiling and reported `410146`
bytes for the largest module after adding the OTel dependencies. The recipe
uses that measured limit; it is not the extension's total bytecode size.
Leaving the old ceiling would prevent either binary from building.
