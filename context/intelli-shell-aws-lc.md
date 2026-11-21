# intelli-shell on the system aws-lc

## intelli-shell rebuilds nixpkgs' package with `aws-lc` in `buildInputs`

**Id:** 90afd705-9c0d-4998-842e-5bfd6f5cd55d
**Type:** workaround
**Status:** superseded
**Superseded:** nix-fleet's nixpkgs pin (0bb82723, 2026-11-19) passed the fix, so the override was dropped from `pkgs/default.nix`.
**Evidence:** confirmed
**Source:** nixpkgs PR #584630 (intelli-shell: add missing dependency on aws-lc,
merged 2026-11-07T21:42Z as `84c6277e`); nixpkgs `cargo-setup-hook.sh` sets
`AWS_LC_SYS_USE_SYSTEM=1`
**Revisit when:** nix-fleet's nixpkgs pin passes 2026-11-07T21:42Z

The `intelli-shell` entry in `pkgs/default.nix` rebuilds nixpkgs' package with
`aws-lc` appended to `buildInputs`.

**Reason:** `cargo-setup-hook.sh` exports `AWS_LC_SYS_USE_SYSTEM=1` for every
Rust build, so `aws-lc-sys` looks for the system library instead of building its
own copy. intelli-shell 3.4.7 locks `rustls` 0.23.45, whose default provider is
`aws-lc-rs` 1.18.1, so the crate is in its graph, and nixpkgs' recipe did not
list `aws-lc`. The result is a `pkg-config` probe failure at build time. The
nixpkgs rev this repository pins through nix-fleet (`f4a03c0`, 2026-11-07T09:04Z)
predates the upstream fix by twelve hours, so the package builds here and fails.

**Alternatives:** wait for the next nixos-unstable advance and move the pin,
which blocks every build in the meantime for a package this repository uses on
both hosts; pin nix-fleet back to a rev with a working recipe, which costs the
rest of that day's nixpkgs; disable the `intelli-shell` aspect, which loses the
tool rather than fixing its build.

**Unknown:** whether the rebuilt package passes its own check phase here, since
the upstream PR reports an unrelated pre-existing test failure on
aarch64-darwin only and nothing was built locally to confirm.
