# Legion hardware

## iwlwifi stays out of the initrd

**Id:** e57b380c-d7f0-473b-b536-21e863cddf0d
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Revisit when:** a kernel or firmware change lets iwlmvm load after switch-root with
iwlwifi in the initrd

With iwlwifi pulled into the initrd on legion, iwlmvm did not load after switch-root and
Wi-Fi stayed down on the AX211. Wi-Fi loads after switch-root instead. The same list is
kept clean on spectre.

## Facter does not load graphics modules in the initrd

**Id:** 2829b198-1ae2-4eb5-8dae-3e79146203c5
**Type:** decision
**Status:** active
**Evidence:** inferred
**Revisit when:** early KMS is wanted for the LUKS prompt

Legion's nixos-facter report is wired through `reportPath` like spectre's, and
`hardware.facter.detected.boot.graphics.kernelModules` is pinned to an empty list.

**Reason:** facter would add `i915` and `nvidia` to the initrd's loaded modules.
Loading the proprietary module that early is risky and the LUKS prompt has not needed
early KMS, so the boot behaviour stays as before. The only other initrd change is
`thunderbolt` and `usb_storage` as available modules.

**Rejected alternative:** accept facter's defaults. Early `i915` KMS remains a separate,
reversible choice.
