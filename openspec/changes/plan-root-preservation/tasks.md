# Tasks

Tentative plan only. Disk growth is next, under its existing change and approvals; neither operation depends on the other. Do not begin this change until the preliminary plan is reviewed and a new implementation instruction is given. Every task below is future work, not approval to perform a disk operation or root reset.

## 1. Resolve the adoption gates

- [ ] 1.1 Review Preservation versus Impermanence against fresh upstream evidence and the pinned nixpkgs; record the selected revision or decision to retain persistent root in the design before adding an input.
- [ ] 1.2 Reconcile `docs/impermanence.md` with live privileged state and service owners, including `/root`, `/var/lib/private`, NetworkManager and system containers; verify each retained path has an owner, loss mode, migration method and backup coverage.
- [ ] 1.3 Choose the initial `/var/lib` granularity and native ownership boundary; record how DynamicUser backing state remains writable without fixed dynamic UIDs or duplicate initialization rules.
- [ ] 1.4 Confirm the password source, early sops bootstrap ordering and automatic-timezone reset policy; document observable login/decryption/timezone acceptance before implementation.
- [ ] 1.5 Choose the reset-disabled recovery path, bounded old-root retention and interaction with Snapper root snapshots; document precisely which subvolumes can be removed and which are excluded.

## 2. Implement and test persistence without root reset

- [ ] 2.1 Add the approved pinned persistence input and selectable NixOS aspect using existing module conventions; verify Legion selects it, Spectre does not, and no reset unit is enabled yet.
- [ ] 2.2 Implement the approved encrypted persistence mount and manifest with feature-local ownership where applicable; add VM assertions for early mount availability, machine-id, account allocation, secret-key modes and visible failure when required storage is missing.
- [ ] 2.3 Implement the approved password and timezone handling; verify password login and secret decryption across two VM reboots, plus the documented timezone behaviour before and after a location fix.
- [ ] 2.4 Test actual state writes for a DynamicUser service and each remaining persisted-file write class across reboot and live configuration switch; confirm old data remains readable and new writes succeed without ownership conflicts.
- [ ] 2.5 Write the state-migration procedure and validate it in a fixture containing existing data; verify ownership, ACLs/attributes, database consistency and detection of unmigrated state before mounts can hide it.

## 3. Implement and test reset and recovery

- [ ] 3.1 Implement the reviewed systemd-initrd Btrfs reset and old-root retention policy; prove unlock/reset/root-mount ordering and sentinel survival in `/nix`, persistence, home, data, logs and every retained subvolume.
- [ ] 3.2 Implement the reset-disabled recovery path and document restore steps; boot that path in the VM and verify it preserves the selected root and allows inspection/restore without another reset.
- [ ] 3.3 Run successive reset boots, a live switch and a boot-generation change; verify stable machine-id, UID/GID, SSH identity, password login and service data, with no fresh identities when persistence is absent.
- [ ] 3.4 Document reset limits, home snapshot gaps and the approved Snapper/retention policy; verify no documentation promises that old generations recover omitted data or that persistence replaces backups.

## 4. Approval-gated Legion rollout

- [ ] 4.1 Obtain approval for storage preparation, then back up and migrate the approved manifest with reset disabled; record independent restore evidence and compare live versus persistent paths before enabling consumer mounts.
- [ ] 4.2 Build the exact Legion generation, execute the focused rebooting VM test and canonical evaluation check, and verify the documented reset-disabled hardware recovery boot; retain the resulting evidence before seeking reset approval.
- [ ] 4.3 Obtain explicit approval immediately before the first reset-enabled hardware boot; verify login, sops, SSH/Tailscale identity, Bluetooth, NetworkManager, timezone and writable telemetry state against recorded pre-reset values.
- [ ] 4.4 Record a second reset boot and journal/service health audit, then update the inventory and architecture to the verified implementation; keep home persistent and Spectre deferred.

## Workflow follow-up

- Review and archive only after the approved behaviour is implemented and accepted; artifact completeness alone is not rollout approval.
- Consider narrowing broad persistence entries only after their loss modes and restores have been verified.
- Treat ephemeral home as a separate future proposal, not unfinished work in this change.
