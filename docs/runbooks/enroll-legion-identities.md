# Enroll Legion's SSH identities

Legion restores its persistent SSH identities from
`secrets/hosts/legion/ssh.yaml`. Enrollment is selected in
`modules/hosts/legion.nix` through `sshIdentitiesEnrolled`. Enable it only after
all six keys have been populated and verified against both age recipients.
While enrollment is disabled, existing unmanaged keys remain in use.

The file groups `client/ed25519`, `client/rsa`, `builder`, `host/ed25519`,
`host/rsa` and `host/ecdsa`. Its explicit `.sops.yaml` rule includes the user and
root age recipients. The server keys preserve the existing host identity rather
than generating a replacement that clients and nix-fleet do not trust.

## Import the existing keys

Either edit the encrypted template with `sops secrets/hosts/legion/ssh.yaml`, or
run the following from the repository root in a Bash shell. The pipeline reads
keys only on the machine holding them and sends plaintext directly to sops;
only encrypted output reaches disk. Do not enable shell tracing, print the
pipeline contents, or commit private keys in plaintext. A populated plaintext
file in the flake can enter the Nix store even before enrollment is enabled.

```sh
set -o pipefail
ciphertext=$(mktemp secrets/hosts/legion/ssh.XXXXXX)
if sudo python3 - <<'PY' | sops --encrypt --input-type json --output-type yaml \
  --filename-override secrets/hosts/legion/ssh.yaml /dev/stdin > "$ciphertext"
import json
from pathlib import Path

read = lambda path: Path(path).read_text()
identities = {
    "client": {
        "ed25519": read("/home/saurabhj/.ssh/id_ed25519"),
        "rsa": read("/home/saurabhj/.ssh/id_rsa"),
    },
    "builder": read("/root/.ssh/nix-remote"),
    "host": {
        "ed25519": read("/etc/ssh/ssh_host_ed25519_key"),
        "rsa": read("/etc/ssh/ssh_host_rsa_key"),
        "ecdsa": read("/etc/ssh/ssh_host_ecdsa_key"),
    },
}
print(json.dumps(identities))
PY
then
  mv "$ciphertext" secrets/hosts/legion/ssh.yaml
else
  rm -f "$ciphertext"
  printf 'Enrollment failed; existing keys and configuration are unchanged.\n' >&2
fi
```

Preserve any private-key passphrase: sops encryption does not replace SSH's
passphrase protection. Do not generate replacement identities to populate the
file. Keep a secured backup of the original keys until restoration is verified.

Check the user recipient can decrypt and that all entries are populated, without
printing their contents:

```sh
sops --decrypt --output-type json secrets/hosts/legion/ssh.yaml | python3 -c '
import json, sys
d = json.load(sys.stdin)
keys = [d["builder"], *d["client"].values(), *d["host"].values()]
assert len(keys) == 6 and all(k.strip().startswith("-----BEGIN ") for k in keys)
print("All six identity entries are populated")
'
```

Repeat this check with the root recipient by replacing the first command with
`sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt "$(command -v sops)" --decrypt --output-type json secrets/hosts/legion/ssh.yaml`.
Both checks must pass. The user bootstrap key is
`~/.config/sops/age/keys.txt`; the system bootstrap key is
`/var/lib/sops-nix/key.txt`. Keep secured off-machine backups of both; these are
external bootstrap identities, not secrets encrypted by the identities they
bootstrap.

## Enable delivery

Set `sshIdentitiesEnrolled = true` in `modules/hosts/legion.nix`, then run:

```sh
nix fmt
nix flake check --no-build --no-write-lock-file
```

Enrollment selects `legion-ssh-identities` in all three Legion compositions:

- Home Manager restores the two client keys at `~/.ssh/id_ed25519` and
  `~/.ssh/id_rsa`, with mode `0600`.
- System-manager on Arch and NixOS restore `builder` at
  `/run/secrets/ssh-builder`, root-owned with mode `0400`; remote-build dispatch
  uses that path. Rotation restarts `nix-daemon.service`.
- NixOS restores the three server host keys under `/run/secrets/ssh-host-*`,
  root-owned with mode `0400`. Native `services.openssh.hostKeys` selects them;
  rotation restarts `sshd.service`. Automatic host-key generation is disabled,
  so missing secrets cannot silently become new identities.

Root sops does not derive bootstrap identities from these SSH keys: it uses the
external age key. The Arch sshd remains outside system-manager ownership and
continues using its existing `/etc/ssh/ssh_host_*` files until the NixOS transition.

The client secret paths replace the unmanaged files with links to decrypted
state. Do not let other key-management tools rewrite those paths. Public-key
files may remain, but authentication does not require them: OpenSSH can derive
public keys from the private keys. No private key enters the Nix store.

After switching, compare public fingerprints with the pre-switch record, verify
secret installation, and test the daemon's builder authentication. Retain secured
backups until those checks pass. The Legion provisioning runbook retains the old
builder and server-key copies only for unenrolled installations.

## Reinstall or impermanence

Provision the external age identities before secret installation, readable only
by their respective owners. On an impermanent system these bootstrap keys must
be restored or mounted from a persistent, secured location before sops runs. This
repository does not yet configure impermanence mounts.

The encrypted file plus the bootstrap age identities reconstruct the SSH client,
builder and server keys; the previous home and root SSH directories are no longer
prerequisites. Tailscale state and the interactive GitHub login/keyring remain
separate migration state. Their retention is not implied by managing SSH keys.
