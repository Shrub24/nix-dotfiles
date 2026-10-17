# Pi Dashboard

Disabled on legion: the extension row and the `piDashboard` service are off, and the tailnet port is closed, until the dashboard is revisited. The module stays in place.

## The bridge cannot spawn its own server, so a service owns it

**Id:** 35394368-e616-4da9-8fcf-bfe2de33af25
**Type:** workaround
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** inspection of `@blackbelt-technology/pi-agent-dashboard` 0.9.0 and probes run against the installed copy
**Verification:** corroborated — the seeded standalone server answered `/api/health` with `{"ok":true}` on `127.0.0.1:8100` under node 22, and the failure it replaces reproduces on demand under the Bun-hosted launcher
**Revisit when:** upstream resolves the interpreter and the loader separately from the host process, or Pi-Bolt stops being a Bun-compiled payload

Installing the dashboard extension made a session print `Dashboard server failed to
start: Cannot find pi's TypeScript loader (jiti)`. Three upstream assumptions, each
that the process hosting the bridge is a Node, produce it:

- **The loader is chosen from the host runtime.** `nativeTransformSupported()`
  probes `node:module.stripTypeScriptTypes` in the current process. Bun does not
  implement it, so jiti is selected — even though the server itself would run under
  a Node where transform mode is supported and jiti is unnecessary. Measured: Bun
  1.4.2 → `false`, node 22.23.3 → `true`.
- **jiti is then looked for at an anchor the bridge never passes.**
  `launchDashboardServer` resolves it with `{ anchor: opts.anchor }` while the
  bridge holds `cliPath`, inside the npm tree where jiti sits, and passes it as
  `cliPath` only. The remaining anchors — the managed `~/.pi-dashboard` install,
  `realpath(which pi)`, `process.argv[1]` — hold no `node_modules` in a Nix
  install, so nothing resolves.
- **The child's interpreter would be `process.execPath`.** `opts.nodeBin` is never
  passed, so under a compiled Pi-Bolt the spawn target is the pi binary itself.
  Given the launcher's argv it answers `Error: Unknown options: --import, --port,
--pi-port`.

**Reason:** The third assumption is decisive, not incidental: the spawn needs a host
that is both the bridge and a Node, and a Bun-compiled payload never is. No setting
or environment fixes it. The server does run correctly outside the bridge — started
from Pi's own package tree under node 22 it bound `127.0.0.1:8100` with its gateway on
9999 — and with `autoStart = false` the bridge skips the loader path entirely and
attaches to whatever is already listening. A systemd user service therefore owns the
server and the module that declares it seeds the bridge's config to match.

**Rejected alternative:** Carry the three fixes as a patch in a `pkgs/pi-plugins`
recipe, passing `cliPath` as the anchor and resolving node through the dashboard's own
tool registry. It preserves the one-process launch and is upstreamable, but it means
patching a package that moves quickly, and putting node on the PATH of a Bun host for
a defect that is upstream's to fix. Session-time autostart is not worth either cost.

**Consequence:** The dashboard joins the local service tier: port 8100 in
`lib/web-services.nix`, loopback only, tunnel off, owned by
`modules/agents/pi-dashboard.nix`, which also seeds `~/.pi/dashboard/config.json`
with `autoStart = false`. That key is load-bearing — a bridge that spawns again
reintroduces the failure. Service and bridge must agree on 8100 and 9999. The
extension row is host-independent while the service is not, so a host that selects
the row without the service (the laptop) keeps the defaults and would try to spawn
its own server.

## Mobile access stays on the tailnet

**Id:** c2499d2a-3c31-4c88-9fc2-44033c00d9ad
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** dashboard 0.9.0 network guard; Tailscale Serve documentation; host firewall policy
**Verification:** corroborated — dashboard source rejects relayed loopback, and the declarations bind and allow the service only through Legion's tailnet firewall; Nix evaluation remains pending
**Revisit when:** the dashboard supports Tailscale identity headers or the tailnet access policy changes

The dashboard binds to `0.0.0.0:8100`, but Legion allows that port only on
`tailscale0`. Its `trustedNetworks` contains the Tailscale IPv4 range
`100.64.0.0/10`; traffic remains inside the tailnet and is subject to Tailscale
access controls. Mobile clients connect directly to Legion on port 8100.

**Reason:** Tailscale Serve proxies to a loopback backend. The dashboard rejects
loopback peers carrying proxy-forwarding headers as relayed traffic, and its
current config has no OAuth provider. Adding the tailnet CIDR to
`trustedNetworks` cannot bypass that guard. Direct tailnet binding preserves the
client's Tailscale source address, which the app can trust; the host firewall
prevents the listener from being reached through other interfaces.

**Rejected alternatives:** Funnel or another public relay would expose a
sensitive session-control dashboard outside the tailnet. Tailscale Serve over
the loopback backend does not pass the dashboard's network guard without
configuring application authentication.
