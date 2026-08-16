# Tasks: dendritic-single-tree

## 1. Scaffold the single tree

- [x] 1.1 Create `modules/flake/scaffold.nix` (declare `flake.modules` option) and `modules/flake/tooling.nix` (treefmt, statix/deadnix checks with updated fileset, devshell, nvfetcher app) from flake.nix content; point `import-tree` at `./modules`.
- [x] 1.2 Verify the empty scaffold evaluates: `nix flake check --no-build --no-write-lock-file` with both trees still present.

## 2. Migrate home aspects

- [x] 2.1 Migrate agents: `modules/agents/{pi,hermes,tools,opencode,docs-mcp,grist,qmd,web-catalog}.nix` as per-feature aspect files (raw module function becomes the aspect value); move `programs.pi.package` override into pi.nix.
- [x] 2.2 Migrate litellm: `modules/agents/litellm/default.nix` publishes `homeManager.litellm`; sibling raw files `/_`-prefixed and imported from it.
- [x] 2.3 Migrate desktop: `modules/desktop/{niri,noctalia,monique}.nix` (homeManager) and `modules/desktop/greeter.nix` (systemManager).
- [x] 2.4 Migrate dev-tools, shell, secrets, niks3, mutagen, mosh per the design mapping table.

## 3. Merge cross-class features and system aspects

- [x] 3.1 Create `modules/nix.nix`, `modules/ssh.nix`, `modules/tailscale.nix` — each ONE file holding both `homeManager.*` and `systemManager.*` values from the merged old files.
- [x] 3.2 Migrate `modules/nixbuild.nix` (systemManager.nixbuild) and `modules/foundation/{network,boot}.nix` (systemManager.{network,boot}).

## 4. Host composition in-tree

- [x] 4.1 Create `modules/hosts/arch.nix` building `homeConfigurations.saurabhj` and `systemConfigs.arch` from published aspects (explicit selection lists, `specialArgs`, checks preserved); move `hosts/arch/{facts,home,system}.nix` to `modules/hosts/arch/_{facts,home,system}.nix` (raw, `/_`-ignored).
- [x] 4.2 Reduce `flake.nix` to a manifest: inputs, `mkFlake`, `import-tree ./modules`, `systems`; delete old host composition and perSystem tooling from it.
- [x] 4.3 Delete `flake-modules/` and `modules/{home,system}` entirely; remove `hosts/` if empty.

## 5. Docs

- [x] 5.1 Update ARCHITECTURE.md Composition section, README layout references, and `docs/web-services-catalog.md` module paths to the single-tree layout (delegated to DocWriter).

## 6. Validation

- [x] 6.1 Full suite: `nix fmt -- --fail-on-change`, `nix flake check --no-build --no-write-lock-file`, lefthook pre-commit, `openspec validate dendritic-single-tree --type change --strict`.
- [x] 6.2 Verify niri `extraConfig` render ordering is unchanged (niri base before Noctalia/Monique extensions) by diffing the rendered niri config against the pre-migration build.
