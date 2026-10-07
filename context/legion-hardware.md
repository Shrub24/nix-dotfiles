# Legion hardware

## iwlwifi stays out of the initrd

**Id:** e57b380c-d7f0-473b-b536-21e863cddf0d
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Revisit when:** a kernel or firmware change lets iwlmvm load after switch-root with
iwlwifi in the initrd

With iwlwifi pulled into the initrd on legion, iwlmvm did not load after switch-root and
Wi-Fi stayed down on the AX211. Wi-Fi loads after switch-root instead. Spectre's
facter report supplies its initrd drivers; an explicit stage-2 `iwlwifi` load and
disabled initrd networking preserve the same boundary.

## Facter loads i915 early, never nvidia

**Id:** 2829b198-1ae2-4eb5-8dae-3e79146203c5
**Type:** decision
**Status:** active
**Evidence:** inferred
**Revisit when:** the proprietary nvidia module is wanted in the initrd, or early i915 KMS causes a boot problem

Legion's nixos-facter report is wired through `reportPath` like spectre's, and
`hardware.facter.detected.boot.graphics.kernelModules` is pinned to `[ "i915" ]`.

**Reason:** facter would also load `nvidia` in the initrd, and loading the
proprietary module that early is risky. `i915` is loaded so the Plymouth passphrase
screen starts at the panel's native mode instead of the firmware framebuffer. The only
other initrd modules facter contributes are available ones: `thunderbolt` and `xhci_pci`
from its keyboard module, `nvme`, `sd_mod` and `usb_storage` from its disk module, so
the host file lists no initrd modules of its own.

**Rejected alternative:** accept facter's defaults (early `nvidia`), or load no graphics
module (the earlier pin, which left the splash on the firmware framebuffer).
