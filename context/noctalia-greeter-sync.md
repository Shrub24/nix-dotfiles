# Noctalia greeter sync

## Passwordless sync through the nixpkgs option

**Id:** 66813e08-8fc9-4662-911c-bad56f1ef723
**Type:** decision
**Status:** needs-review
**Evidence:** inferred
**Revisit when:** the silent sync is checked on a booted session, or noctalia-greeter
changes how its apply helper validates the staging directory

The greeter's appearance sync still runs `pkexec` on upstream's apply helper, which is
the only way to run it as root. The prompt is removed by `passwordlessSyncUsers` on the
nixpkgs greeter module, which renders the polkit rule for upstream's
`org.noctalia.greeter.sync-appearance` action. No wrapper, sudoers entry or hand-written
rule remains. The owner's goal was background sync without a polkit prompt; `pkexec`
itself was acceptable. That the sync is now silent has not been observed yet, so the
entry stays `needs-review` until it is.

**Reason:** the Arch-era wrapper copied files into a root-owned `/run` directory, which
greeter 1.6.0's helper rejects because it requires the staging directory to belong to
the invoking user. Upstream's own action and option are the supported path.

**Rejected alternatives:** a sudoers or visudo entry, which grants broader command
rights than one action; a systemd path unit running the helper as root, which would have
to fake the invoking user's id; keeping the wrapper, which the 1.6.0 helper rejects.
