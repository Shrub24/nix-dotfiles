# Arch retirement

## NixOS is the only host class

**Id:** 0f6fdede-cd06-43b2-ba60-9475af66f3c7
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** a host that cannot run NixOS is added again

Legion's NixOS install is the source of truth. The system-manager layer, the
standalone Home Manager output and every Arch-only branch (the `/usr/bin` uwsm pin, the
genericLinux pkexec path, the pacman PATH entries) were removed rather than gated, and
Arch-era leftovers in the shared home are deleted rather than accommodated.

**Reason:** the owner stated that Arch compatibility and side-by-side use are not a
priority, so a second user-scoped evaluation had no consumer and every compatibility
branch was dead weight that could mask a real NixOS defect.

**Rejected alternative:** keep the standalone Home Manager output and the Arch branches
as a rollback path during the soak. Rejected by the owner; the Arch partitions stay
bootable in the firmware menu, but nothing in this repository serves them.

## Left in place on purpose

**Id:** c094bd1f-cdba-4f80-9808-8d52af23cd08
**Type:** constraint
**Status:** active
**Evidence:** inferred
**Revisit when:** the enrollment runbook drops its unenrolled-installation path, or the
nvim wrapper's verification note is re-run

Three remnants look like Arch debt but were kept deliberately. The `PATH=/usr/bin:/bin`
line in the nvim wrapper notes is a recorded verification witness for why the runtime
package set must be complete, so rewriting it would falsify the experiment. The
`saurabhj@arch` comment on an authorized key is part of the key line, and editing it
changes the rendered `authorized_keys` and the system derivation. The builder key path
`/root/.ssh/nix-remote` remains the documented pre-enrollment path.

**Reason:** each one is evidence, identity or a documented fallback, not a compatibility
branch.

## Session variables are systemd user variables

**Id:** b4b1cf75-337e-4153-82d8-bee0bca65104
**Type:** decision
**Status:** active
**Evidence:** inferred
**Revisit when:** the graphical session stops being started through uwsm and the systemd
user manager

The four variables the compositor needs live in `systemd.user.sessionVariables`, which
renders to `environment.d`, instead of `home.sessionVariables`.

**Reason:** the uwsm-managed session reads the systemd user environment, while
`home.sessionVariables` only reaches login shells. The reason comes from the worker that
made the change and was not re-measured on a booted session.

**Rejected alternative:** keep an unmanaged `~/.config/uwsm/env`. It was the Arch-era
route and sat outside the configuration.

## The wrapped editor is installed as nvim

**Id:** a89fcf10-ab02-42a5-88f1-868d341d923e
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** another editor binary named nvim is installed alongside it

The wrapper's `binName` was `nvim-nix` so the pacman `nvim` kept working. With Arch
gone nothing provided `nvim`, though `EDITOR` and the text/plain default both name it,
so the wrapper now installs `nvim` and its desktop entry.

**Rejected alternative:** keep `nvim-nix` and point `EDITOR` and the default handler at
it. The owner chose the plain name.
