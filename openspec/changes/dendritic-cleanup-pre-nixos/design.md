# Design — Dendritic Cleanup Before NixOS

## 1. Why the anti-patterns are removed now

The repo-local dialect (`.skills/dendritic-nix/SKILL.md`) gates several current
patterns behind explicit approval. The canonical sources
([`mightyiam/dendritic`](https://github.com/mightyiam/dendritic) →
*Anti-patterns* → *`### specialArgs pass-thru`*; and
[`dendrix.denful.dev/Dendritic.html`](https://dendrix.denful.dev/Dendritic.html)
→ *"No need to use `specialArgs` for communicating values"*) are unambiguous:
lower-level modules must not receive `inputs` or host inventories through a
dependency-injection bus. The skill's own tenets restate this:

- **Tenet 7** — "Share data through lexical scope or normal typed options, not
  ambient argument buses." Prefer `config.home.username`, `config.home.homeDirectory`,
  `pkgs.stdenv.hostPlatform.system` over duplicate custom facts.
- **Tenet 8** — "Capture flake inputs lexically at the top-level feature
  boundary." Top-level modules may take `inputs`; lower-level HM/System Manager
  modules must not need the whole input set through `specialArgs`.
- **Tenet 9** — "Host/user identity belongs to host/user configuration; topology
  belongs to its owning domain." Do not build an ambient record mixing username,
  uid, hostname, architecture, remoteHosts, databaseHost, service URLs and
  derived home paths.
- **Tenet 10** — "Features own their implementation details end-to-end." A
  service feature owns its service-specific secret declarations/templates. A
  shared secrets foundation owns SOPS infrastructure, not a registry of every
  consumer's templates.
- **Tenet 11** — "One owner per package/config datum." No duplicate
  `home.packages` entries; one canonical owner per port/socket/username/path.
- **Tenet 12** — "Host import-list ordering must not encode feature semantics."
- **Tenet 14** — "Treat System Manager compatibility code as transitional" and
  mark Arch-specific paths with `COMPAT(arch):` / `TODO(nixos):`.

Because these are approval-gated, the review + user approval already happened;
this change executes the approved cleanup before adding a NixOS class to the
same feature tree, so new modules inherit the canonical shape rather than the
anti-patterns.

## 2. Topology shape rationale (broad first, refactor later)

`hostFacts` currently mixes two genuinely different kinds of data:

1. **Service topology** that several features consume: `databaseHost`,
   `niks3ServerUrl`, `remoteHosts` (for ssh/wezterm), `appsDir`.
2. **Host identity** that mostly has native equivalents already:
   `username`/`homeDirectory` (`config.home.*`), `architecture`
   (`pkgs.stdenv.hostPlatform.system`), `uid`, `hostname`.

Per user decision the first is modeled as a **typed `topology` option**, broad
in shape now with the option to refactor to granular named options later:

```nix
# modules/policy/topology.nix  (owned by the "Shared typed top-level data"
# pattern, SKILL.md §"Shared typed top-level data")
{ lib, ... }:
{
  options.topology.hosts.<name>.system = lib.mkOption { type = lib.types.str; ... };
  options.topology.hosts.<name>.primaryUser = lib.mkOption { type = lib.types.str; ... };
  options.topology.services.<name>.host = lib.mkOption { type = lib.types.str; ... };
  # covers databaseHost, niks3ServerUrl, remoteHosts, phoenixCollectorEndpoint, ...
}
```

It is **populated only at the host composition layer**
(`modules/hosts/arch.nix`), from the now-shrunk `_facts.nix` literals, and read
by consumers via the normal module system — **never injected via specialArgs**.
This matches the skill's "Shared typed top-level data" pattern and its
explicit warning: "Do not expose the entire top-level `config` into lower-level
module arguments"; consumers capture the specific value from the outer
flake-parts config.

Broad-first is deliberately lazy: a granular option lattice per service is
premature for a single-host repo, and the shape is thin enough to refine
without churn when multi-host/NixOS lands.

## 3. Secrets hybrid split mechanism (sops.placeholder mechanics)

The split relies on a verified sops-nix behavior: `sops.placeholder.X` is built
from the **fully-merged** module config. In sops-nix source
(`modules/home-manager/templates.nix`), placeholders are derived via a
`mapAttrs` over `hmConfig.sops.secrets` — that is, the merged view across every
module that declares `sops.secrets`, not the local module slice. Consequently:

- `sops.secrets.X` may be declared in **any** module;
- `config.sops.placeholder.X` may be referenced from **any** module;
- the whole set is decrypted/rendered once by the sops-nix activation, with no
  behavioral change to ordering or decryption.

This makes the ownership split safe: a service feature declares its own secret
(`sops.secrets."NIKS3_AUTH_TOKEN"`, `sops.secrets."GRIST_SESSION_SECRET"`, …)
and its own rendered template (`sops.templates."grist.env"`, `"litellm.env"`, …),
all the way down to per-secret `sopsFile` where needed (niks3 already uses its
own `secrets/niks3-secrets.yaml`, which per-secret `sopsFile` supports).

Shared, genuinely cross-feature credentials (the ~20 LLM/provider API keys plus
the shell-wide `zsh-secrets.env`) stay together in a dedicated
`modules/security/credentials/agents.nix` aspect because they are not owned by
one feature. Everything service-specific leaves the monolith for its owning
feature.

## 4. Niri includes approach (no upstream `includes` option)

The upstream niri Home Manager module has **no `includes` option** — only
`settings`, `extraConfigEarly`, and `extraConfig` (the latter being
`types.lines`, appended after `settings`). Today monique and noctalia each
contribute to niri's `extraConfig` via `lib.mkIf`; because `types.lines` merges
in **reverse module order**, the rendered `config.kdl` depends on the relative
ordering of `monique`, `niri`, and `noctalia` in `hmAspects`
(`modules/hosts/arch.nix:19-21`). That is tenet-12 coupling through the host
import list.

The fix moves each contribution into its own `.kdl` file written via
`xdg.configFile` (`~/.config/niri/monique.kdl`, `~/.config/niri/noctalia.kdl`),
and niri's own `extraConfig` — now a **single author-controlled string with no
Nix merge semantics** — ends with two plain `include optional=true` lines.
The KDL parser supports `include optional=true` for any root-node type,
including `spawn-at-startup`, `window-rule`, `layer-rule`, and `binds`, so
monique's `monitors.kdl` include and noctalia's spawn/layer/window rules +
`include optional=true "noctalia-binds.kdl"` transfer unchanged.

This is strictly cleaner than `lib.mkOrder`/`mkBefore` surgery at merge sites:
the order is authored once, inline, and deterministic; host composition becomes
pure membership/selection. `noctalia-binds.kdl` itself is already a separate
file and stays as-is.

## 5. Explicit non-goals (deferred to NixOS day)

These are consciously excluded so this change stays cleanup-scoped:

- **Niks3 migration.** The post-build-hook + socket path consolidation is
  deferred; niks3 is being replaced by a native NixOS module on migration day.
  Its current code still gets the `topology` fix so it does not keep the
  anti-pattern while it lives.
- **Secret ciphertext reorg** into shared/users/hosts/services dirs — single
  age key + single host today; reorg is relevant only when multi-host age
  identities land on NixOS day.
- **Formal `session-credentials` three-scope infrastructure** — the principle is
  applied (shared → `credentials`; service-only → feature); no new aspect until
  a real consumer exists.
- **`shrub.primaryUser` namespace** — system-manager is transitional; a
  minimal local option / direct literal with a `COMPAT(arch):` marker serves
  until NixOS's native `config.users.users.saurabhj` owns this.
- **`cli.nix` split and `workstation-home` composition extraction** — not part
  of this cleanup.

## 6. Spec / durable-doc rewrites

The following canonical artifacts document the patterns being removed and are
rewritten as part of this change:

- `openspec/specs/dendritic-module-composition/spec.md` — Requirement *"Host
  facts remain host-owned"* (the `hostFacts` pass-thru pattern) is replaced by
  the typed-topology + native-option model.
- `openspec/specs/system-manager-foundation/spec.md` — if it references
  `hostFacts`/`specialArgs`, align with the new model.
- `ARCHITECTURE.md` — durable decision *"Hosts own facts"* and the
  `hostFacts` specialArgs description are rewritten.
- A new canonical spec (or changes to the above) describing the secrets
  ownership model once the monolith split lands.
