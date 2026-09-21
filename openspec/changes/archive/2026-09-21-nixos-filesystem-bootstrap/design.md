## Context

See `proposal.md` for motivation. The current Arch home directory masks several
first-switch assumptions, while username and UID literals are repeated across
outer flake-parts modules and inner Home Manager/NixOS modules. The repository
prohibits a `specialArgs` identity bus and keeps ownership with each feature.

## Goals / Non-Goals

**Goals:**

- Make the first-switch filesystem declarations evaluation-verifiable.
- Keep one typed primary-user declaration at host composition.
- Preserve mutable theme and wallpaper files after their initial seed.
- Make each feature own only its paths and privilege scope.

**Non-Goals:**

- Creating a central filesystem bootstrap aspect.
- Pre-creating paths that Home Manager or native NixOS modules already create.
- Creating logind runtime directories or redesigning the deferred Niks3 socket.
- Migrating existing mutable user files back into the Nix store.

## Decisions

### D1. Model the primary user as `{ name; uid; }`

`topology.hosts.arch.primaryUser` becomes a typed submodule. Outer feature
modules read it through `config.topology`; raw host modules are curried with the
same value at composition. Dynamic `users.users.${name}` and
`home-manager.users.${name}` keys remove duplicate identity literals without
reintroducing `specialArgs`.

Keeping a string plus a sibling UID option was rejected because the two values
form one account identity and every consumer needs them together.

### D2. Derive home paths from the account name

The host home path is `/home/${name}`. Home Manager receives that value through
its native `home.homeDirectory` option. NixOS creates the Unix account; Home
Manager remains the owner of files below the home directory.

### D3. Use the declaration that matches path semantics

- Managed files use `home.file` or `xdg.configFile`; these declarations create
  their parent directories.
- Empty mutable user directories use Home Manager `systemd.user.tmpfiles.rules`.
- Mutable seed files use tmpfiles `C`, so an absent file is copied from a store
  seed while an existing runtime-edited file is preserved.
- System tmpfiles are added only for mutable system paths with no native owner.

A global tmpfiles list was rejected because it separates paths from their
consumer and creates competing owners.

### D4. Seed existing UX dependencies without new inputs

WezTerm seeds a tracked TOML matching the current theme. Noctalia seeds
`pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath` under its
mutable wallpaper directory and points its default setting at that filename.
Posting receives only its mutable data directory.

### D5. Keep graphics acceptance manual

The interactive desktop VM already verifies boot, login and compositor UX.
Making the headless check expose a GL-backed output would add virgl test
infrastructure unrelated to filesystem ownership. This change instead evaluates
the Home Manager activation and inspects the generated user tmpfiles rules.

## Risks / Trade-offs

- \[A `C` seed can become stale after upstream defaults change\] → It is only a
  safe first-run fallback; runtime owners may replace it and switches preserve it.
- [Changing the topology option shape touches many consumers] → Keep the change
  mechanical and run an exhaustive literal sweep plus all configuration evals.
- [A headless VM can report a running niri process with no output] → Keep output
  acceptance in the working interactive VM rather than expanding this change.
- [Niks3 still references the user runtime socket before login] → Keep it
  explicitly deferred; do not violate logind ownership to hide the issue.

## Migration Plan

1. Change the topology schema and host composition, then remove duplicated
   identity literals from consumers.
1. Add feature-local user tmpfiles and seed sources.
1. Evaluate the Home Manager activation and generated user tmpfiles rules.
1. Apply Home Manager before the eventual bare-metal NixOS switch. Existing
   mutable destinations are preserved by `C`; rollback removes the declarations
   without deleting user data.
