# Persistence inventory

Start with a persistent root and make home selective first. This is an inventory,
not an enabled impermanence configuration: no reset, mount or migration is
configured here. Keep root snapshots through the soak. Reduce root persistence
only after its state and recovery dependencies have been checked.

Add a row when a feature introduces durable state. Name its owner, what would be
lost, and whether it is active or only planned. Paths below use the normal XDG
locations; `~` means the primary user's home.

## Home: preserve first

| Path                                                                                                                                    | Owner / loss on reset                                                                                                                                                                                       | Basis                                                  |
| --------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `~/.config/sops/age/keys.txt`                                                                                                           | User sops bootstrap identity; decrypted secrets cannot replace this key. Keep an independent recovery copy.                                                                                                 | `modules/security/sops.nix`                            |
| `~/.local/share/keyrings`                                                                                                               | Login keyring, including interactive GitHub credentials. Not Nix-owned.                                                                                                                                     | Existing login state; `ARCHITECTURE.md`                |
| `~/.local/state/syncthing`                                                                                                              | Device keys, mutable configuration and database. Despite its system service, Legion keeps this state in home.                                                                                               | `modules/syncthing.nix`                                |
| `~/.local/share/grist`                                                                                                                  | Grist documents and bundled SQLite state.                                                                                                                                                                   | `modules/agents/grist.nix`                             |
| `~/.pi/agent/sessions`, `~/.pi/agent/kendex`                                                                                            | Operator transcripts and Magic Context history. Preserve together, not just the search index.                                                                                                               | Existing Pi state; `context/pi-bolt-entrypoints.md`    |
| Project-local `.pi/sessions/children` and other project-local agent state                                                               | Delegated transcripts and project history; retain with the projects that own them.                                                                                                                          | `context/pi-bolt-entrypoints.md`                       |
| `~/.pi/agent/auth.json`, `mcp-auth.json`                                                                                                | Interactive provider and MCP authentication. Sensitive; not committed.                                                                                                                                      | Existing Pi state                                      |
| Mutable files under `~/.pi/agent`                                                                                                       | Extension settings, approvals, trust and managed-agent state; for example `pi-herdsman/config.json`, `loop-police.json`, `pi-tool.json`, `pi-stamp.json`. Do not persist store-linked configuration copies. | `modules/agents/pi.nix`; `ARCHITECTURE.md`             |
| `~/.memex/memory`, `~/.memex/state`, `~/.memex/web-auth-token`                                                                          | Memex memory, processing state and MCP owner authentication. Index/vector directories are a separate rebuild-cost choice.                                                                                   | Existing Memex state; `modules/agents/memex.nix`       |
| `~/.config/qmd/index.yml`, `~/.config/qmd/trusted.json`, project `.qmd/`                                                                | Local collection definitions and trust decisions not declared by Nix.                                                                                                                                       | `context/qmd.md`; existing QMD state                   |
| Browser profiles, including `~/.mozilla` and `~/.config/chromium`                                                                       | Sessions, bookmarks, logins and extension state. Inventory the other enabled browser profiles before resetting home.                                                                                        | Existing profiles; `modules/apps/browser/`             |
| `~/.config/herdr`                                                                                                                       | Mutable operator settings seeded at activation; a switch restores only declared keys.                                                                                                                       | `ARCHITECTURE.md`                                      |
| `~/.config/monique`, `~/.local/share/wallpapers`                                                                                        | Monitor profiles and user wallpaper collection. Generated compositor includes and theme outputs are rebuildable.                                                                                            | Existing Monique state; `modules/desktop/noctalia.nix` |
| `~/Documents`, `~/Pictures`, `~/Music`, `~/Downloads`, projects and other user data                                                     | Preserve the actual data, including uncommitted work. Downloads includes Surge's output; Syncthing replicas are not a backup policy.                                                                        | `modules/surge.nix`, `modules/syncthing.nix`           |
| `~/.local/bin`, `~/Applications`                                                                                                        | Imperative installs the repository does not build: `cloudflared`, `bws`, `deep-filter`, `fzf-preview`, `hide-apps`, `cursor`, and AppImage bundles. Not reproducible from the flake.                        | 2026-10-08 home sweep                                  |
| `~/.ssh` unmanaged identities                                                                                                           | `home-forge-dev`, `environment-saurabh-eos`, `config.d/` and `known_hosts` are not delivered by sops; only the enrolled client keys are. Re-inventory before treating the directory as rebuildable.         | 2026-10-08 home sweep                                  |
| `~/.gnupg`, `~/.pki/nssdb`, `~/.kube/config`                                                                                            | Public keys and trust database, client certificates, and cluster credentials. The GPG private keyring is empty.                                                                                             | 2026-10-08 home sweep                                  |
| Agent state outside Pi: `~/.claude`, `~/.claude.json`, `~/.codex`, `~/.hermes`, `~/.config/opencode`, `~/.config/cortexkit`             | Sessions, approvals and per-tool state for the agents the repository configures but does not own.                                                                                                           | `modules/agents/`; 2026-10-08 home sweep               |
| `~/.keep-the-why`                                                                                                                       | Personal Keep-the-Why configuration and the project map; not Nix-owned.                                                                                                                                     | `AGENTS.md`; 2026-10-08 home sweep                     |
| `~/.local/share/64Gram`, `~/.local/share/dev.zmk.studio`, `~/.local/share/nicotine`, `~/.local/share/JetBrains`, `~/.local/share/fonts` | Application data and user content: chat history, keyboard layouts, shares, IDE projects, installed fonts.                                                                                                   | 2026-10-08 home sweep                                  |

### Home: decide before resetting

- `~/.local/share/containers`: keep volumes and writable application data unless
  every workload has a tested restore. Images alone are downloadable.
- `~/.ssh`: enrolled client keys are symlinks into decrypted sops secrets; the
  unmanaged identities named in the preserve table are not. Inspect them and
  `known_hosts` separately rather than assuming every identity is in sops.
- Shell history (`~/.local/share/fish` and any enabled bash/zsh history), zoxide,
  mutable Noctalia/plugin state, editor state, and other application profiles:
  choose retention deliberately. Nix config ownership does not imply state
  ownership. Confirm each application's current write path before adding mounts.
  The sweep found the concrete holders: `~/.local/state/noctalia`,
  `~/.local/state/vicinae`, `~/.local/state/nvim`, `~/.local/state/herdr`,
  `~/.local/state/herdr-radar-development`, `~/.local/state/custom-scripts`, and
  the fish and zoxide directories already listed above.
- `~/.agents` is a cross-tool symlink: preserve any local content at its target,
  not merely the link. Apply the same rule to other out-of-store links.
- `~/.cache/qmd/index.sqlite` and its WAL/SHM companions, QMD models,
  `~/.memex/index` and `~/.memex/vectors`: rebuildable if their source documents
  and sessions survive. Keeping them avoids re-indexing and downloads. Stop the
  service before taking a database copy; a single SQLite file may not be current.

Generic build caches (`.npm`, `.bun`, `.cargo` caches, `.rustup`, `.gradle`, etc.)
are not mandatory persistence. Check for local source or configuration before
classifying an entire directory as disposable.

### Home: rebuild cost, not identity

Measured 2026-10-08. None of this is worth a mount on its own, but the re-download
cost is real, so decide per directory whether fetching it again is acceptable:

| Path                                                              | What it holds                                                           |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `~/.bun` (13 GB), `~/go` (10 GB)                                  | Package and module caches; `go` also holds installed binaries.          |
| `~/.local/share/uv` (6.9 GB)                                      | uv-managed interpreters and tool environments.                          |
| `~/.rustup` (2.7 GB), `~/.cargo` (127 MB)                         | Toolchains and crate cache; installed binaries live in `~/.cargo/bin`.  |
| `~/.local/share/mise` (612 MB), `~/.npm`, `~/.gradle`, `~/.cmake` | Version-manager installs and build caches.                              |
| `~/.local/share/containers` (4.2 GB)                              | Rootless Podman images and volumes: volumes are data, images are not.   |
| `~/.local/state/cargo-broot-remnants.tar.zst`                     | A stray archive left in state; nothing in the repository references it. |

### Home: do not carry across

The same sweep found state that is dead or dangling. A reset is a good moment to
drop it rather than preserve it:

- Arch-era profile links, all dangling: `~/.nix-profile`,
  `~/.local/state/nix/profiles/{channels,home-manager,profile}`, `~/.nix-defexpr`.
- Pre-switch user units in `~/.config/systemd/user`, all dangling: `syncthing`,
  `syncthing-init`, `niks3-auto-upload` (service and socket), `nh-clean` (service
  and timer), `appimagelauncherd`, `gcr-ssh-agent`, `gnome-keyring-daemon`.
- Install-time symlinks in the home: `result-legion`,
  `result-legion-install-tools`.
- `~/.local/share/Trash` (11 GB) and the 216 unmanaged desktop entries in
  `~/.local/share/applications` left by applications the repository does not
  install.
- Backup files (`*.bak`, `*.old`, `*.pre-hm`, `*.pre-nix`) under `~/.config` and
  `~/.ssh`.
- Configurations of applications no longer installed, and the retired LazyVim
  tree at `~/.config/nvim` — the editor loads its configuration from the store.
- `..memex.compaction.lock` and `..memex.ingest.lock` in the home root: empty
  files whose doubled dot suggests a naming bug upstream; confirm before deleting.

### Durable state under snapshot-excluded roots

The migration recorded `.local/share` and `.local/state` as nested subvolumes;
`modules/hosts/legion/_storage.nix` still lists them as home churn roots. Btrfs
snapshots do not descend into child subvolumes. These concrete paths therefore
need independent preservation and backup coverage:

- `~/.local/share/grist`: documents and SQLite state.
- `~/.local/share/keyrings`: login credentials.
- `~/.local/state/syncthing`: device keys, configuration and database.
- `~/.local/share/containers`: volumes and writable application data; recorded
  as a further nested subvolume for nodatacow.

Also choose whether to retain `~/.local/share/fish` (history) and
`~/.local/share/zoxide` (navigation history); both exist on Legion.

The churn list is descriptive, not a reset policy. Re-check the live subvolume
layout with privileges before migrating it; the unprivileged audit could not
read the btrfs tree. Add newly discovered durable paths here by name rather than
classifying either whole XDG directory as regenerable.

## Root: retained for now

These paths already survive because root remains persistent. They become an
explicit mount/restore checklist only if root is reset later.

| Path                                                   | Reason / owner                                                                                                                                 |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `/var/lib/sops-nix/key.txt`                            | System secret bootstrap key; provision externally before activation.                                                                           |
| `/var/lib/tailscale`                                   | Existing tailnet machine identity.                                                                                                             |
| `/var/lib/bluetooth`                                   | Bluetooth pairings.                                                                                                                            |
| `/etc/NetworkManager/system-connections`               | Saved Wi-Fi/VPN profiles and embedded credentials; root-only.                                                                                  |
| `/var/lib/nixos`                                       | NixOS account allocation and activation state.                                                                                                 |
| `/etc/machine-id`                                      | Stable machine identity; decide persistence before a reset-root boot.                                                                          |
| `/nix`, `/boot`, `/home`, `/data`, snapshot subvolumes | Existing independently mounted storage; keep the filesystem topology, not copied directory contents.                                           |
| `/var/lib/containers`                                  | System-scope Podman storage: volumes and writable application data survive, images do not. Pruned weekly by `virtualisation.podman.autoPrune`. |
| `/var/cache`, `/var/tmp`, `/var/log`, `/.snapshots`    | Churn subvolumes from the same disko layout; they exist to keep writes out of the root snapshot, not to hold state.                            |

Legion's SSH host keys and builder key are restored from its encrypted identity
file; keep the bootstrap key and recovery procedure rather than making a second
unmanaged key source. Other enabled system services may add state: this table is
not yet a complete reset-root manifest.

### Root: regenerable, or already handled

- `/var/lib/private`, `/var/lib/machines`, `/var/lib/noctalia-greeter`,
  `/var/lib/niks3-hook`, `/var/lib/beszel-agent`, `/var/lib/fwupd`,
  `/var/lib/upower`: small service state that the owning service recreates.
- `/var/lib/systemd/coredump`: transient. The sweep found two `rustfmt` aborts
  from 2026-10-07/08 (`agent-radar`, `--edition 2024 --check`) worth reading
  before pruning.
- `/var/log/journal` (40 MB): journald retention applies; no separate mount is
  needed.

### Root: do not carry across

- The EFI boot entries are NVRAM rather than files, and they survive a reset on
  their own: 12 entries remain, including the Arch-era `Limine` loader on the
  old ESP and the install USB. `efivarfs` is 88% full, so prune them with
  `efibootmgr` instead of preserving them.
- `/var/lib/libvirt/images` is declared as a subvolume in
  `modules/hosts/legion/_disko.nix`, but no libvirt service is configured:
  decide whether to keep the mount or drop the declaration.

## Planned: telemetry adoption

Not enabled yet. Add these to the root checklist when the lanes are deployed:

| Path                               | Owner / loss on reset                                                |
| ---------------------------------- | -------------------------------------------------------------------- |
| `/var/lib/vmagent`                 | Metrics remote-write queue.                                          |
| `/var/lib/vector`                  | Journal shipper state and buffers.                                   |
| `/var/lib/opentelemetry-collector` | Persistent OTLP queue; may hold the only copy of undelivered traces. |

The fleet contract owns these mechanisms. Record the evaluated storage paths
again at adoption; an inventory entry is not evidence that a lane is delivering.
