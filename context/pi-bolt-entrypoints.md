# Pi-Bolt entrypoints

## Launch behaviour belongs to the installed package

**Id:** eac14512-df45-40f3-a76c-7176dce7f391
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Verification:** corroborated — each published launcher resolves beside the executable in this output, and the install check verifies the package identity; launcher-only changes reuse the payload
**Revisit when:** Radar changes its installation-identity model, or Pi-Bolt changes its launcher contract

One output carries upstream's lead and orchestrator launchers beside the copied
executable and adds the local `pi-bolt-child` wrapper; `bin/` links to them, and
`pi` links to the lead. Stock Pi owns the shared `packages` list in
`~/.pi/agent/settings.json`. Each Pi-Bolt role has a separate agent directory
and settings rendered by the payload's `select` from its plugin selection. Managed-child definitions
name compiled plugins as `builtin:<id>` and keep paths only for runtime
extensions. The child wrapper remains because Herdsman passes
`--no-extensions`; it filters duplicate builtin arguments and supplies the
child's compiled set for that launch.

**Reason:** upstream launchers pass arguments through unchanged, avoiding the
subcommand bug caused by prepending flags. Separating the stock package list
from Pi-Bolt overlays lets `pi-stock` keep its source-based fallback without
making each Pi-Bolt role's settings serve both loaders. The builtin allowlist
keeps new compiled plugins opt-in. Keeping launchers beside the executable
makes Radar and `doctor` identify this output as one installation.

**Rejected alternatives:** prepending extension flags breaks positional CLI
commands. Sharing Pi-Bolt sources through `packages` makes stock Pi consume the
same package list and forces one settings file to serve both loaders. Separate
Home Manager launcher derivations split command ownership from the package;
launchers in a different store root fail the installation identity check.

**Consequence:** launcher and role-setting changes do not repeat the AOT build.
Direct `process.execPath` launches still bypass shell launchers and retain their
existing extension contract.

## Operator roles use separate agent dirs and a shared session root

**Id:** a351bc70-32af-490b-b585-6de0a73270f5
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** maintainer direction, 2026-10-19 and 2026-10-20
**Revisit when:** agent-directory mirroring, MCP ownership or Pi session discovery
changes, or operator-session reconciliation becomes a migration goal

Pi-Bolt's lead and `pio` use `~/.pi/roles/lead` and
`~/.pi/roles/orchestrator`; Herdsman children use `~/.pi/roles/child`.
Home Manager declares each role's files: every store-managed entry of the
default agent directory is linked into the role unless the role overrides it
(`settings.json` always; `mcp.json` only when the role declares MCP servers).
Runtime state the roles must share (`auth.json`, `trust.json`, `mcp-auth.json`,
`npm`, themes, router, freeflow and extension state) is an explicit out-of-store
link list. Projects are trusted by default (`defaultProjectTrust = "always"`). Role settings
are writable activation snapshots; global and role `mcp.json` files are separate
store-managed configs. Lead and orchestrator sessions use the default
`~/.pi/agent/sessions`; child sessions stay role-local. Magic Context's hidden
children remain unchanged.

**Reason:** separate settings give each role an explicit compiled-plugin set
without changing the stock Pi configuration. Sharing the operator session root
keeps `/resume`, continuation and existing history together. Managed children
remain outside that shared history. Herdsman mailbox/config/results
are coordination state, not agent preferences, so Herdsman accepts an explicit
absolute `PI_HERDSMAN_DATA_DIR` shared across agent directories and forwards it
to children. The default root stays under `~/.pi/agent/pi-herdsman` so existing
state and the Home Manager seed remain in place. MCP server definitions are
durable user configuration and stay Nix-owned; a temporary project-scoped
server belongs in that project's `.pi/mcp.json`. Each role gets a separate
rendered MCP config so a role-specific change cannot leak across roles.

**Rejected alternative:** give each operator role a private session root. It
would isolate `/resume` but fragment history and require selecting or migrating
sessions later. Pointing operator roles at the shared root through `sessionDir` was
also rejected: an explicit `sessionDir` is a flat, non-recursive directory, so
it hides the per-project `--cwd--` folders and writes new sessions beside them.
The role's `sessions` entry links to the shared directory instead, keeping
Pi's default layout. Recursive mirroring of app-written state was also rejected: it
recreated thousands of links and let rename-writers fork files silently, so only
store links follow the default automatically and shared runtime state is named.
New store-managed entries appear at the next activation. Keeping MCP files writable and activation-seeded
was rejected: durable global server changes belong in Nix rather than in runtime
`pi mcp add/remove` or plugin-owned writes.

**Consequence:** role settings are activation snapshots, and role-local runtime
settings changes are replaced on the next switch. `auth.json` remains a shared
symlink; Pi's lock directory is created beside the role-specific symlink path,
so simultaneous refreshes can race. The low-frequency re-auth risk is accepted
for now. Magic Context role isolation and broader session reconciliation remain
deferred.

## Pi-Bolt's own `herdr` builtin is compiled in and never enabled

**Id:** 7dad112c-0d51-4410-a100-d71921feeeea
**Type:** decision
**Status:** open
**Evidence:** confirmed
**Verification:** corroborated — the compiled payload's `doctor` names
`builtin:herdr`, but no role's generated builtin allowlist includes it
**Revisit when:** Pi-Bolt's herdr integration gains something the shim below does
not provide, or it disappears from the payload

The payload this repository builds contains Pi-Bolt's own `herdr` integration as
a compiled builtin. The operator-role allowlists omit it; pane state is published
by the `herdr-pi-state.ts` shim the `herdr` module installs instead.

**Reason:** the conflict question is now documented upstream: Pi-Bolt's own
`herdr` builtin loads only inside a Herdr pane (`HERDR_ENV=1` with a pane id)
and then reports pane state in place of Herdr's own Pi integration, and the
docs say not to run two publishers of pane state at once. What is still open is
our choice — whether that builtin replaces the `herdr-pi-state.ts` shim, which
would drop the shim's conditional entry from the lead role's settings.

**Consequence:** if the builtin is wanted, add it to the lead role's builtin
allowlist; first reconcile the two pane-metadata publishers, since only one may
run at a time.
