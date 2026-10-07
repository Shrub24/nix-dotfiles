## 1. Gates and selection

- [ ] 1.1 Delete `sshIdentitiesEnrolled` and the unenrolled branches in `modules/hosts/legion.nix`, `legion/ssh-identities.nix` and both runbooks.
- [ ] 1.2 After Spectre is enrolled, delete the `secretsEnrolled` phase lists in `modules/hosts/spectre.nix`.
- [ ] 1.3 Drop the Home Manager `tailscale`, `syncthing`, `mosh` and `niks3` selections that `embeddedHmAspects` subtracts, and the subtraction.

## 2. Upstream adoption

- [ ] 2.1 Decide `telemetry`: select it with a real destination and producers, or delete `modules/telemetry.nix`.
- [ ] 2.2 Drop the `dev` build account when home-forge selects `build-account` (`modules/policy/fleet.nix`).
- [ ] 2.3 Register the snapper timer units with the fleet `notify` capability.
- [ ] 2.4 Re-test the fleet `podman` aspect against the nixpkgs `podman-prune` unit; keep the local `autoPrune` if they still clash.

## 3. Local modules

- [ ] 3.1 Confirm whether surge's upstream flake module still installs an overlay and writes its unit outside the store; keep or replace `modules/surge.nix`.
- [ ] 3.2 Decide `boot.kernelPackages = linuxPackages_latest` on merit.
- [ ] 3.3 Shrink legion's hand-listed initrd modules to overrides over the facter report.
- [ ] 3.4 Decide early `i915` KMS.

## 4. Residual Arch traces

- [ ] 4.1 Re-key or accept the `saurabhj@arch` comment on the authorized key.
- [ ] 4.2 Remove `~/.config/uwsm/env`, `~/.config/uwsm/env-niri`, and the Arch-era lines in `~/.bash_profile` and `~/.profile`.
- [ ] 4.3 Revoke the Google OAuth client for vdirsyncer.

## 5. OpenSpec bookkeeping

- [ ] 5.1 Reconcile `add-spectre-host` sections 3–6 with the completed install.
- [ ] 5.2 Tick or drop the open items in `migrate-home-to-data-disk`, `snapper-snapshots` and `migrate-agent-configs-to-nix`.
- [ ] 5.3 Fix the system-manager and Arch sshd lines in `docs/runbooks/enroll-legion-identities.md`.
- [ ] 5.4 Hold `nixos-dual-boot-install` section 7 until the owner ends the soak.
