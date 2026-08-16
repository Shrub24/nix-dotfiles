# Design: dendritic-single-tree

## Source of truth

Layout validated claim-by-claim against mightyiam/dendritic README, Dendrix
guide + conventions, denful/import-tree source (`nixFilter = andNot (hasInfix "/_") (hasSuffix ".nix")`, relative to scan root), and flake-parts `flake.modules`
docs. Key rulings:

- One scanned root named `modules/`; every `.nix` file in it is a flake-parts
  module. Raw class modules may only exist at `/_`-infixed paths (ignored).
  `_`-prefixed files directly at the scan root are NOT ignored — only paths
  containing `/_` after the root.
- One file per feature across ALL classes it applies to. Splitting by class
  (`home.nix`/`system.nix`) is a deviation; splitting by capability is the
  sanctioned growth axis.
- Host composition belongs in-tree (guide form); flake.nix stays a manifest.
- Bare `flake.modules.<class>.<name>` publication is the sanctioned default.

## Mechanical transform

Each raw class module (a function `{ config, lib, pkgs, ... }: { ... }`) becomes
the aspect value directly — no wrapper indirection:

```nix
# modules/desktop/niri.nix
_: { flake.modules.homeManager.niri = { config, lib, pkgs, ... }: { /* unchanged body */ }; }
```

Multi-file features keep their closure in one directory: the aspect file is
scanned, sibling raw files are `/_`-prefixed (import-tree ignores them).

## Mapping (old → new)

| Old | New | Aspect(s) |
| --- | --- | --- |
| `flake-modules/scaffold.nix` | `modules/flake/scaffold.nix` | — (declares `flake.modules` option) |
| `flake.nix` perSystem (treefmt, checks, devshell, nvfetcher app) | `modules/flake/tooling.nix` | — |
| `flake.nix` host composition + aspect lists | `modules/hosts/arch.nix` | builds both host outputs |
| `hosts/arch/facts.nix` | `modules/hosts/arch/_facts.nix` | raw (ignored) |
| `hosts/arch/home.nix` | `modules/hosts/arch/_home.nix` | raw (ignored) |
| `hosts/arch/system.nix` | `modules/hosts/arch/_system.nix` | raw (ignored) |
| `modules/home/agents/pi.nix` | `modules/agents/pi.nix` | homeManager.pi |
| `modules/home/agents/hermes.nix` | `modules/agents/hermes.nix` | homeManager.hermes |
| `modules/home/agents/tools.nix` | `modules/agents/tools.nix` | homeManager.tools |
| `modules/home/opencode.nix` | `modules/agents/opencode.nix` | homeManager.opencode |
| `modules/home/agents/docs-mcp.nix` | `modules/agents/docs-mcp.nix` | homeManager.docs-mcp |
| `modules/home/agents/grist.nix` | `modules/agents/grist.nix` | homeManager.grist |
| `modules/home/agents/qmd.nix` | `modules/agents/qmd.nix` | homeManager.qmd |
| `modules/home/agents/web-catalog.nix` | `modules/agents/web-catalog.nix` | homeManager.web-catalog |
| `modules/home/agents/litellm/` | `modules/agents/litellm/` (default.nix = aspect; siblings `/_`-prefixed) | homeManager.litellm |
| `modules/home/desktop/{niri,noctalia,monique}.nix` | `modules/desktop/{niri,noctalia,monique}.nix` | homeManager.{niri,noctalia,monique} |
| `modules/system/greeter.nix` | `modules/desktop/greeter.nix` | systemManager.greeter |
| `modules/home/dev-tools/{languages,lazyjournal,mise,navi}.nix` | `modules/dev-tools/{languages,lazyjournal,mise,navi}.nix` | homeManager.{languages,lazyjournal,mise,navi} |
| `modules/home/nix.nix` + `modules/system/nix.nix` | `modules/nix.nix` (ONE file, both classes) | homeManager.nix + systemManager.nix |
| `modules/system/nixbuild.nix` | `modules/nixbuild.nix` | systemManager.nixbuild |
| `modules/home/remote/ssh.nix` + `modules/system/ssh.nix` | `modules/ssh.nix` (ONE file, both classes) | homeManager.ssh + systemManager.ssh |
| `modules/home/remote/{mutagen,mosh}.nix` | `modules/{mutagen,mosh}.nix` | homeManager.{mutagen,mosh} |
| `modules/home/remote/tailscale.nix` + `modules/system/tailscale.nix` | `modules/tailscale.nix` (ONE file, both classes) | homeManager.tailscale + systemManager.tailscale |
| `modules/home/shell/{fish,zsh,abbr}.nix` | `modules/shell/{fish,zsh,abbr}.nix` | homeManager.{fish,zsh,abbr} |
| `modules/home/{direnv,tmux,wezterm}.nix` | `modules/shell/{direnv,tmux,wezterm}.nix` | homeManager.{direnv,tmux,wezterm} |
| `modules/home/sops.nix` | `modules/secrets.nix` | homeManager.secrets |
| `modules/home/niks3.nix` | `modules/niks3.nix` | homeManager.niks3 |
| `modules/system/{network,boot}.nix` | `modules/foundation/{network,boot}.nix` | systemManager.{network,boot} |
| `flake-modules/**`, `modules/home/**`, `modules/system/**` (remainder) | deleted | — |

The `programs.pi.package` override currently in flake.nix moves into
`modules/agents/pi.nix` (flake-parts modules receive `inputs`).

## Constraints

- **niri extraConfig ordering (must preserve):** `types.lines` merges in reverse
  of module import order — niri's base `extraConfig` must render before
  Noctalia/Monique extensions, so niri must be imported AFTER them (later
  import renders first). Today the desktop facade lists niri last; in the new
  host composition the aspect list must keep niri later than noctalia/monique.
  Verify post-migration by comparing the rendered niri config before/after.
- `hosts/arch/home.nix` host toggles (`programs.*.enable`) move verbatim to
  `_home.nix`; `specialArgs` (`inputs`, `hostFacts`) continue to be passed by
  the host composition module.
- Lint fileset in tooling: drop `./flake-modules` and `./hosts`, keep `./modules`
  (now the whole tree). treefmt excludes unchanged.
- `/_`-ignored files under `modules/` are still formatted and linted by path
  (filesets are path-based, not import-based) — no exclusion changes expected.

## Risks

- Every module file moves at once → mitigated by full eval checks
  (`checks.home-manager-activation`, `checks.system-manager-config`) and
  build of both host outputs.
- import-tree evaluates every scanned file: any leftover raw module file
  without `/_` fails evaluation loudly (fail-fast, not silent).
