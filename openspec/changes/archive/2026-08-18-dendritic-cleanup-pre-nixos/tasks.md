# Tasks — Dendritic Cleanup Before NixOS

> **Verify (canonical, run at each stage):**
>
> - `nix flake check --no-build --no-write-lock-file` (fast eval gate; MUST stay green)
> - `openspec validate --strict` (MUST pass at the end)
> - Group D adds a byte-comparison check against the pre-change rendered config.

______________________________________________________________________

## Group A — Mechanical SSOT Cleanup

### A1. Remove duplicate `eza` package ownership

- [x] Remove `eza` from `home.packages` in `modules/dev-tools/cli.nix:22`.

`refs:` `modules/dev-tools/cli.nix:22` (`eza` in `home.packages`); canonical owner `modules/shell/default.nix:87` (`programs.eza.enable`, with `icons`/`colors`/`extraOptions`).
`criteria:` Tenet 11 — one owner per package datum. `programs.eza.enable` remains the sole owner.
`verify:` `rg -n "eza" modules/dev-tools/cli.nix modules/shell/default.nix` shows a single occurrence (the enable).

### A2. Remove duplicate `pistol` package ownership

- [x] Remove `pistol` from `home.packages` in `modules/shell/default.nix:25`.

`refs:` `modules/shell/default.nix:25` (`pistol` in `home.packages`); canonical owner `modules/shell/default.nix:97` (`programs.pistol.enable` + `associations`).
`criteria:` Tenet 11 — same file, single ownership.

### A3. Replace greeter `--user saurabhj` literal with `hostFacts.username`

- [x] Replace the hardcoded `--user saurabhj` literal at `modules/desktop/greeter.nix:99` with `${hostFacts.username}` (already used at :18 and :78 in the same file).

`refs:` `modules/desktop/greeter.nix:99` (`command = "${noctaliaGreeterSession}/bin/greetd-noctalia-session -- --user saurabhj"`), :18 (`subject.user == "${hostFacts.username}"`), :78 (`default = "${hostFacts.username}"`).
`criteria:` No remaining literal username in greeter.nix besides the hostFacts-derived value.

### A4. Replace navi with intelli-shell (drop-in HM-native replacement)

User decision: drop navi entirely in favor of `programs.intelli-shell` (upstream HM module at `home-manager/master/modules/programs/intelli-shell.nix`) — eliminates the hardcoded `.#saurabhj` literal in navi's cheats by removing navi altogether. nixpkgs ships `intelli-shell` 3.4.5.

- [x] Delete `modules/dev-tools/navi.nix`.
- [x] Create `modules/dev-tools/intelli-shell.nix` as the HM aspect: `programs.intelli-shell = { enable = true; enableFishIntegration = true; enableBashIntegration = true; enableZshIntegration = true; settings = { ... }; };` (port any directly-equivalent settings from `~/.config/intelli-shell/config.toml` if the user has one — if not, start with default settings).
- [x] Update `hmAspects` in `modules/hosts/arch.nix`: replace `navi` with `intelli-shell` (alphabetical position).
- [ ] Drop navi from pacman after switch lands (deferred to user; not part of this change's verification).

`refs:` `modules/dev-tools/navi.nix` (full file); `home-manager/master/modules/programs/intelli-shell.nix` (upstream); `search.nixos.org/packages?query=intelli-shell` (nixpkgs 3.4.5).
`criteria:` No navi references in `modules/`; `programs.intelli-shell.enable = true` is the sole owner; `nix flake check --no-build --no-write-lock-file` green.
`verify:` `rg -n "navi" modules/` returns 0 matches; `rg -n "intelli-shell" modules/` shows the new aspect.

### A5. Eliminate LiteLLM port `8765` duplication

- [x] Replace the 3 hardcoded `http://localhost:8765` literals with `config.programs.litellm.port` (defaults to `webServices.litellm.port`):
  - `modules/hosts/arch/_home.nix:52` — aichat `api_base`
  - `modules/agents/hermes.nix:42` — model `base_url`
  - `modules/agents/litellm/_generated.nix:247` — opencode `baseURL`
- [x] Copy the pattern already used at `modules/agents/docs-mcp.nix:51` (`http://localhost:${toString config.programs.litellm.port}/v1`).

`refs:` `modules/agents/litellm/_hm.nix:32-36` (`port` option, `default = webServices.litellm.port`); `modules/agents/docs-mcp.nix:51` (correct pattern).
`criteria:` No literal `8765` in user-facing config; all read `programs.litellm.port`.

### A6. Sync stale KDE platform-theme comment

- [x] Update `modules/apps/kde.nix:23-24` comment (claims `QT_QPA_PLATFORMTHEME=qt6ct`) to the current value `gtk3` from `modules/desktop/portals.nix:46`.

`refs:` `modules/apps/kde.nix:23-24` (stale comment), `modules/desktop/portals.nix:46` (`QT_QPA_PLATFORMTHEME = "gtk3"`).
`criteria:` USER CONFIRMED gtk3 is intended; comment matches reality. `qt6ct` no longer referenced as the active theme.

### A7. (DEFERRED) Niks3 post-build-hook + socket path consolidation — EXCLUDE

- [ ] **No work in this change.** Document as a known deferred item (niks3 replaced by native NixOS module on migration day). See `design.md` §5.

### A8. Add cheap derivation-based CI job

- [x] Add a separate CI job to `.github/workflows/validate.yml` building `.#checks.x86_64-linux.{statix,deadnix,treefmt}`.
- [x] Keep the existing `nix flake check --no-build --no-write-lock-file` step as the fast eval gate.

`refs:` `.github/workflows/validate.yml` (single `flake-check` job today).
`criteria:` Confirmed via Nix manual — `--no-build` = "Do not build checks", so today's CI is eval-only. The new job performs real derivation builds of the cheap checks (NOT full HM/system-manager closure builds per PR).

### A9. (DEFERRED) `COMPAT(arch):` / `TODO(nixos):` markers — EXCLUDE

User decision: leave the debt. All listed sites are system-manager-scoped / transitional paths that won't be a problem on NixOS (or live in a different design space: `targets.genericLinux.enable` disappears under NixOS native; `system-manager.allowAnyDistro` is system-manager-only; `/usr/bin/uwsm` already carries the ponytail marker explaining the NixOS-day swap-back path). Markers add noise without preventing a real bug.

- [ ] **No work in this change.** See `design.md` §5 (non-goals).

______________________________________________________________________

## Group B — Eliminate `inputs`/`hostFacts` anti-pattern + typed topology

> Canonical justification: `mightyiam/dendritic` Anti-patterns → *`### specialArgs pass-thru`*; `dendrix.denful.dev/Dendritic.html` → *"No need to use `specialArgs` for communicating values"*. Skill tenets 7-9.

### B1. Define typed top-level `topology` option

- [x] Create `modules/policy/topology.nix` (flake-parts top-level option; "Shared typed top-level data" pattern, SKILL.md:439-470):
  - `options.topology.hosts.<name>.system` (`str`)
  - `options.topology.hosts.<name>.primaryUser` (`str`)
  - `options.topology.services.<name>.host` (`str`) — covers databaseHost, niks3ServerUrl, remoteHosts, phoenixCollectorEndpoint, etc.

`refs:` `.skills/dendritic-nix/SKILL.md:439-470` ("Shared typed top-level data").
`criteria:` Broad first per user decision; can refactor to granular later. Not injected via specialArgs.

### B2. Populate `topology` at the host composition layer

- [x] In `modules/hosts/arch.nix` (the host composition layer), set `topology.hosts.arch.{system,primaryUser}` and `topology.services.database.host` (and service topology) from `_facts.nix` data.
- [x] Ensure only the arch host sets it; do NOT route `topology` through `specialArgs`.

`refs:` `modules/hosts/arch/_facts.nix` (`username`, `architecture`, `remoteHosts`, `niks3ServerUrl`, `databaseHost`).
`criteria:` `topology` is a normal flake-parts option read by consumers via `config`.

### B3. Replace `inputs` argument injection

For each lower-level module currently destructuring `inputs` from specialArgs, use lexical capture at the outer top-level flake-parts module: `{ inputs, ... }: { flake.modules.homeManager.X = { imports = [ inputs.foo.homeManagerModules.bar ]; ... }; }`.

- [x] secrets (until Group C deletes it)
- [x] nixbuild
- [x] fish
- [x] direnv
- [x] hermes
- [x] tools
- [x] pi
- [x] qmd
- [x] mise
- [x] dev-tools/default
- [x] vicinae
- [x] monique
- [x] noctalia

`refs:` `.skills/dendritic-nix/SKILL.md` tenet 8; each file's top-level `inputs` destructure.
`criteria:` No lower-level HM/System Manager module pulls `inputs` from specialArgs; only top-level feature publishers take `inputs` lexically.

### B4. Replace `hostFacts.username`/`homeDir` with native options (tenet 7)

- [x] `_home.nix` — use native `home.username`/`home.homeDirectory` (host-local literals at the host composition layer; removed `hostFacts`).
- [x] `opencode.nix` — `appsDir` from native home path; replace `hostFacts.appsDir`.

`refs:` `modules/hosts/arch/_home.nix:11-12`; `modules/agents/opencode.nix` (`hostFacts.appsDir`).
`criteria:` No `hostFacts.username`/`homeDirectory`/`appsDir` reads where `config.home.*` suffices.

### B5. Replace `hostFacts.remoteHosts` consumers

- [x] `modules/ssh.nix` — read remote hosts from `topology.hosts` (typed).
- [x] `modules/shell/wezterm.nix` — same.

`refs:` `.skills/dendritic-nix/SKILL.md` tenet 9 (topology belongs to its owning domain).
`criteria:` No `hostFacts.remoteHosts` reads remain.

### B6. Replace `hostFacts.databaseHost` / `niks3ServerUrl` consumers

- [x] `modules/secrets.nix:59` — `hostFacts.databaseHost` in the `litellm.env` template (overlaps Group C; coordinate so the template moves to `litellm/_hm.nix` and reads `topology.services.database.host`).
- [x] `modules/niks3.nix` — `hostFacts.niks3ServerUrl` default → `topology.services.<niks3>.host`.

`refs:` `modules/secrets.nix:59` (`@${hostFacts.databaseHost}`); `modules/niks3.nix` (`serverUrl` default = `hostFacts.niks3ServerUrl`).
`criteria:` No `hostFacts.databaseHost`/`niks3ServerUrl` reads remain. Note: niks3 still deferred for full migration; only the topology fix applies now.

### B7. Replace `hostFacts.architecture`

- [x] `modules/hosts/arch/_system.nix:3` — `nixpkgs.hostPlatform = hostFacts.architecture` → literal `"x86_64-linux"` (system-manager scoped); also `arch.nix` `system = hostFacts.architecture` → literal `"x86_64-linux"`.

`refs:` `.skills/dendritic-nix/SKILL.md` tenet 7 (`pkgs.stdenv.hostPlatform.system`); `_system.nix:3`; `_facts.nix:8`.
`criteria:` `hostFacts.architecture` fully removed where `pkgs.stdenv.hostPlatform.system` applies.

### B8. Greeter primary-user access (per user decision — no `shrub.primaryUser`)

- [x] `modules/desktop/greeter.nix` — replace `hostFacts.username` use at system-manager call site with a direct literal `"saurabhj"` (no `COMPAT(arch):` marker, no `shrub.primaryUser` option). **(no work per user directive — literal `saurabhj` at system-manager call site, no marker)**

`refs:` `modules/desktop/greeter.nix:18,78,99`; `design.md` §5 (non-goal).
`criteria:` NixOS-day native `config.users.users.saurabhj` will own this; transitional marker documents it.

### B9. De-parameterize `pkgs/default.nix` from `hostFacts.uid`

- [x] Remove `hostFacts.uid` parameterization of `noctalia-greeter-sync` at `pkgs/default.nix` (global overlay). Specialize at the feature use site (greeter feature) instead.

`refs:` `pkgs/default.nix` (`noctalia-greeter-sync = final.callPackage ./noctalia-greeter-sync { inherit (hostFacts) uid; }`); skill tenet §"Approval-gated: host-specific overlays/packages".
`criteria:` Global package set no longer depends on host instance data (uid).

### B10. Remove `inputs` and `hostFacts` from `specialArgs` (close the change)

- [x] In `modules/hosts/arch.nix`, remove `inputs`/`hostFacts` from `specialArgs`/`extraSpecialArgs` after all consumers are converted; slim `arch.nix` accordingly.

`refs:` `modules/hosts/arch.nix:82-84,87,92`.
`criteria:` No `specialArgs`/`extraSpecialArgs` dependency bus remains.

### B11. Remove/shrink `modules/hosts/arch/_facts.nix`

- [x] Fold fields into either `topology` (service topology) or host-local literals at the host composition layer. (`_facts.nix` removed entirely.)

`refs:` `_facts.nix` (17 lines).
`criteria:` `_facts.nix` either removed or reduced to literals only used at `arch.nix` composition.

______________________________________________________________________

## Group C — Secrets Hybrid Aspect-Owned Design

> Feasibility: sops-nix `sops.placeholder.X` is built from the fully-merged module config (sops-nix `modules/home-manager/templates.nix` — `mapAttrs ... hmConfig.sops.secrets`), so secrets CAN be declared across modules and referenced from any module via `config.sops.placeholder.X`. See `design.md` §3.

### C1. SOPS foundation module

- [x] Create `modules/security/sops.nix` — SOPS foundation only:
  - imports `inputs.sops-nix.homeManagerModules.sops`
  - `sops.age.keyFile` policy
  - `home.packages = [ pkgs.age pkgs.sops ]` safety belt
  - No application secrets.

`refs:` current foundation in `modules/secrets.nix` (keyFile + imports).
`criteria:` Foundation owns SOPS infra, zero service secrets.

### C2. Shared LLM/API credentials aspect

- [x] Create `modules/security/credentials/agents.nix` — the ~20 shared credentials from `secrets/agents.yaml` (GEMINI_API_KEY, OPENROUTER_API_KEY, VOLCENGINE_API_KEY, OPENAI_API_KEY, DEEPSEEK_API_KEY, NEURALWATT_API_KEY, CURSOR_API_KEY, OPENCODE_API_KEY, OPENCODE_LITELLM_API_KEY, LITELLM_API_KEY, LITELLM_MASTER_KEY, LITELLM_DATABASE_PASSWORD, GITHUB_PAT, GITHUB_TOKEN, SOURCEGRAPH_TOKEN, JINA_TOKEN, TAVILY_API_KEY, BRAVE_API_KEY, FIRECRAWL_API_KEY, CONTEXT7_API_KEY).
- [x] Keep the shell-wide `zsh-secrets.env` template here (genuinely cross-feature shared env for the agent/dev workflow).

`refs:` `secrets/agents.yaml`; current `sops.templates."zsh-secrets.env"` in `modules/secrets.nix`.
`criteria:` Shared creds centralized in one credentials aspect.

### C3. Move service-specific templates to consumer feature modules

- [x] `modules/agents/litellm/_hm.nix` — owns `sops.templates."litellm.env"` (file content reaching into `config.programs.litellm.database.enable` / `headroomPort`, now legitimate since LiteLLM owns its template + `topology.services.database.host` for the DB host).
- [x] `modules/agents/hermes.nix` — owns `sops.templates."hermes.env"`.
- [x] `modules/agents/docs-mcp.nix` — owns `sops.templates."docs-mcp.env"`.
- [x] `modules/agents/grist.nix` (NOTE: correct path is `modules/agents/grist.nix`, not `modules/apps/`) — owns `sops.secrets."GRIST_SESSION_SECRET"` + `sops.templates."grist.env"`.
- [x] `modules/hosts/arch/_home.nix` (aichat) — owns `sops.templates."aichat.env"`.
- [x] `modules/niks3.nix` — owns `sops.secrets."NIKS3_AUTH_TOKEN"` + `sops.templates."niks3-auth-token"` (its `sopsFile` is `secrets/niks3-secrets.yaml` — per-secret `sopsFile` is already supported).
- [x] `modules/nix.nix` — owns `sops.templates."nix-access-tokens"` (GITHUB_PAT path for nix access).

`refs:` tenet 10; current owners of these templates in `modules/secrets.nix`.
`criteria:` Each service's secret(s) + template lives in that service's feature module.

### C4. Cross-references via `config.sops.placeholder.X`

- [x] Keep all cross-module secret references as `config.sops.placeholder.X` (mechanism verified in sops-nix source). No behavioral change to sops-nix activation/decryption.

`criteria:` Same decryption, same rendered outputs, relocated ownership only.

### C5. Delete the monolith + register new aspects

- [x] Delete `modules/secrets.nix`.
- [x] Register the new aspect `sops` (`flake.modules.homeManager.sops`?).
- [x] Register the aspect `credentials` (`flake.modules.homeManager.credentials`?).
- [x] Update `hmAspects` in `modules/hosts/arch.nix` accordingly (replace `"secrets"`).

`refs:` `modules/hosts/arch.nix` `hmAspects` list (currently `"secrets"`).
`criteria:` `modules/secrets.nix` gone; `sops` + `credentials` present in `hmAspects`; `nix flake check --no-build --no-write-lock-file` green.

### C6. (DEFERRED) Ciphertext reorganization — EXCLUDE

- [ ] No work. Reorg `secrets/*` into shared/users/hosts/services dirs only when multi-host age identities land on NixOS day. Document in `design.md` §5.

### C7. (DEFERRED) Formal `session-credentials` infrastructure — EXCLUDE

- [ ] No new aspect; apply the principle during migration (shared creds → `credentials`; service-only → feature). Document in `design.md` §5.

### C8. Spec / durable-doc rewrites

- [x] Rewrite `openspec/specs/system-manager-foundation/spec.md` if it documents the `hostFacts`/`secrets.nix` layout (verify current content; see `design.md` §6).
- [x] Rewrite `openspec/specs/dendritic-module-composition/spec.md` Requirement *"Host facts remain host-owned"* to the typed-topology + native-option model.
- [x] Update `ARCHITECTURE.md` durable decision *"Hosts own facts"* and the `hostFacts` specialArgs description.
- [x] Add a new canonical spec (or update the above) describing the new secrets ownership model (foundation + credentials + feature-owned templates).

`refs:` `openspec/specs/dendritic-module-composition/spec.md:37-45`; `ARCHITECTURE.md` ("Hosts own facts"); `design.md` §6.
`criteria:` No canonical spec documents the removed `hostFacts`/secrets-monolith patterns.

______________________________________________________________________

## Group D — Niri KDL File-Include Refactor (DMS-style)

> Verified: the niri HM module has NO `includes` option (only `settings`, `extraConfigEarly`, `extraConfig` where `extraConfig` is `types.lines` appended after settings). KDL parser supports `include optional=true` for any root-node type (spawn-at-startup/window-rule/layer-rule). Tenet 12: host import-list ordering must not encode feature semantics. See `design.md` §4.

### D1. Monique → own `.kdl` file

- [x] In `modules/desktop/monique.nix`, replace the `extraConfig` contribution (lines 44-48) with `xdg.configFile."niri/monique.kdl"` writing `~/.config/niri/monique.kdl` containing `include optional=true "monitors.kdl"` (mkIf-gated as before).

`refs:` `modules/desktop/monique.nix:44-48`.
`criteria:` No `extraConfig` contribution from monique.

### D2. Noctalia → own `.kdl` file

- [x] In `modules/desktop/noctalia.nix`, replace the `extraConfig` contribution (lines 26-45) with `xdg.configFile."niri/noctalia.kdl"` writing `~/.config/niri/noctalia.kdl` containing the spawn-at-startup + layer-rule + window-rule + `include optional=true "noctalia-binds.kdl"` block (mkIf-gated as before).
- [x] `noctalia-binds.kdl` itself stays as-is (`noctalia.nix:47-94` — already a separate file).

`refs:` `modules/desktop/noctalia.nix:26-45`; `:47-94` (noctalia-binds).
`criteria:` No `extraConfig` contribution from noctalia.

### D3. Niri `extraConfig` include lines

- [x] In `modules/desktop/niri.nix` `extraConfig`, append two `include optional=true` lines for `monique.kdl` and `noctalia.kdl` at the end (single author-controlled string, no merge semantics, deterministic order).

`refs:` `modules/desktop/niri.nix:204` (`extraConfig`).
`criteria:` Order authored once inline; host import order is now pure membership.

### D4. Remove the ordering warning comment

- [x] Remove the import-order warning comment in `modules/hosts/arch.nix:19-21` (constraint dissolved).

`refs:` `modules/hosts/arch.nix:19-21`.
`criteria:` Comment gone; `hmAspects` order no longer semantically load-bearing for niri.

### D5. Verify rendered output equivalence

- [x] Byte-compare rendered `config.kdl` against `/tmp/opencode/niri-config-pre.kdl` if it still exists, ELSE build + `niri validate` and visually compare.
- [x] CI `niri validate` (part of `checkConfig`) is the correctness gate.

`refs:` `design.md` §4.
`verify:` rendered config byte-equivalence OR `niri validate` passing + manual diff; `nix flake check --no-build --no-write-lock-file`.

______________________________________________________________________

## Final Validation

- [x] `nix flake check --no-build --no-write-lock-file` passes (Groups A-D complete).
- [x] `openspec validate --strict` passes.
- [x] User confirms acceptance (mechanical cleanup + topology + secrets split + niri equivalence).
