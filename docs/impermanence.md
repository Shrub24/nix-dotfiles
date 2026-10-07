# Persistence inventory

Start with a persistent root and make home selective first. This is an inventory,
not an enabled impermanence configuration: no reset, mount or migration is
configured here. Keep root snapshots through the soak. Reduce root persistence
only after its state and recovery dependencies have been checked.

Add a row when a feature introduces durable state. Name its owner, what would be
lost, and whether it is active or only planned. Paths below use the normal XDG
locations; `~` means the primary user's home.

## Home: preserve first

| Path                                                                                | Owner / loss on reset                                                                                                                                                                                       | Basis                                                  |
| ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `~/.config/sops/age/keys.txt`                                                       | User sops bootstrap identity; decrypted secrets cannot replace this key. Keep an independent recovery copy.                                                                                                 | `modules/security/sops.nix`                            |
| `~/.local/share/keyrings`                                                           | Login keyring, including interactive GitHub credentials. Not Nix-owned.                                                                                                                                     | Existing login state; `ARCHITECTURE.md`                |
| `~/.local/state/syncthing`                                                          | Device keys, mutable configuration and database. Despite its system service, Legion keeps this state in home.                                                                                               | `modules/syncthing.nix`                                |
| `~/.local/share/grist`                                                              | Grist documents and bundled SQLite state.                                                                                                                                                                   | `modules/agents/grist.nix`                             |
| `~/.pi/agent/sessions`, `~/.pi/agent/kendex`                                        | Operator transcripts and Magic Context history. Preserve together, not just the search index.                                                                                                               | Existing Pi state; `context/pi-bolt-entrypoints.md`    |
| Project-local `.pi/sessions/children` and other project-local agent state           | Delegated transcripts and project history; retain with the projects that own them.                                                                                                                          | `context/pi-bolt-entrypoints.md`                       |
| `~/.pi/agent/auth.json`, `mcp-auth.json`                                            | Interactive provider and MCP authentication. Sensitive; not committed.                                                                                                                                      | Existing Pi state                                      |
| Mutable files under `~/.pi/agent`                                                   | Extension settings, approvals, trust and managed-agent state; for example `pi-herdsman/config.json`, `loop-police.json`, `pi-tool.json`, `pi-stamp.json`. Do not persist store-linked configuration copies. | `modules/agents/pi.nix`; `ARCHITECTURE.md`             |
| `~/.memex/memory`, `~/.memex/state`, `~/.memex/web-auth-token`                      | Memex memory, processing state and MCP owner authentication. Index/vector directories are a separate rebuild-cost choice.                                                                                   | Existing Memex state; `modules/agents/memex.nix`       |
| `~/.config/qmd/index.yml`, `~/.config/qmd/trusted.json`, project `.qmd/`            | Local collection definitions and trust decisions not declared by Nix.                                                                                                                                       | `context/qmd.md`; existing QMD state                   |
| Browser profiles, including `~/.mozilla` and `~/.config/chromium`                   | Sessions, bookmarks, logins and extension state. Inventory the other enabled browser profiles before resetting home.                                                                                        | Existing profiles; `modules/apps/browser/`             |
| `~/.config/herdr`                                                                   | Mutable operator settings seeded at activation; a switch restores only declared keys.                                                                                                                       | `ARCHITECTURE.md`                                      |
| `~/.config/monique`, `~/.local/share/wallpapers`                                    | Monitor profiles and user wallpaper collection. Generated compositor includes and theme outputs are rebuildable.                                                                                            | Existing Monique state; `modules/desktop/noctalia.nix` |
| `~/Documents`, `~/Pictures`, `~/Music`, `~/Downloads`, projects and other user data | Preserve the actual data, including uncommitted work. Downloads includes Surge's output; Syncthing replicas are not a backup policy.                                                                        | `modules/surge.nix`, `modules/syncthing.nix`           |

### Home: decide before resetting

- `~/.local/share/containers`: keep volumes and writable application data unless
  every workload has a tested restore. Images alone are downloadable.
- `~/.ssh`: Nix delivers Legion's enrolled keys, but inspect unmanaged keys and
  `known_hosts` separately. Do not assume every identity is in sops.
- Shell history (`~/.local/share/fish` and any enabled bash/zsh history), zoxide,
  mutable Noctalia/plugin state, editor state, and other application profiles:
  choose retention deliberately. Nix config ownership does not imply state
  ownership. Confirm each application's current write path before adding mounts.
- `~/.agents` is a cross-tool symlink: preserve any local content at its target,
  not merely the link. Apply the same rule to other out-of-store links.
- `~/.cache/qmd/index.sqlite` and its WAL/SHM companions, QMD models,
  `~/.memex/index` and `~/.memex/vectors`: rebuildable if their source documents
  and sessions survive. Keeping them avoids re-indexing and downloads. Stop the
  service before taking a database copy; a single SQLite file may not be current.

Generic build caches (`.npm`, `.bun`, `.cargo` caches, `.rustup`, `.gradle`, etc.)
are not mandatory persistence. Check for local source or configuration before
classifying an entire directory as disposable.

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

| Path                                                   | Reason / owner                                                                                       |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `/var/lib/sops-nix/key.txt`                            | System secret bootstrap key; provision externally before activation.                                 |
| `/var/lib/tailscale`                                   | Existing tailnet machine identity.                                                                   |
| `/var/lib/bluetooth`                                   | Bluetooth pairings.                                                                                  |
| `/etc/NetworkManager/system-connections`               | Saved Wi-Fi/VPN profiles and embedded credentials; root-only.                                        |
| `/var/lib/nixos`                                       | NixOS account allocation and activation state.                                                       |
| `/etc/machine-id`                                      | Stable machine identity; decide persistence before a reset-root boot.                                |
| `/nix`, `/boot`, `/home`, `/data`, snapshot subvolumes | Existing independently mounted storage; keep the filesystem topology, not copied directory contents. |

Legion's SSH host keys and builder key are restored from its encrypted identity
file; keep the bootstrap key and recovery procedure rather than making a second
unmanaged key source. Other enabled system services may add state: this table is
not yet a complete reset-root manifest.

## Planned: telemetry adoption

Not enabled yet. Add these to the root checklist when the lanes are deployed:

| Path                               | Owner / loss on reset                                                |
| ---------------------------------- | -------------------------------------------------------------------- |
| `/var/lib/vmagent`                 | Metrics remote-write queue.                                          |
| `/var/lib/vector`                  | Journal shipper state and buffers.                                   |
| `/var/lib/opentelemetry-collector` | Persistent OTLP queue; may hold the only copy of undelivered traces. |

The fleet contract owns these mechanisms. Record the evaluated storage paths
again at adoption; an inventory entry is not evidence that a lane is delivering.
