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

## NVIDIA's free-buffer pool is capped for niri

**Id:** 7c370826-ada5-4a76-9e4e-d894cf8f41cf
**Type:** workaround
**Status:** active
**Evidence:** confirmed
**Source:** niri wiki, Nvidia page; NVIDIA/egl-wayland#126
**Revisit when:** NVIDIA stops retaining freed buffers in the driver pool, or VRAM
measured under this profile still tracks use rather than the buffers niri holds

Legion's niri renders on the dGPU, because `debug.render-drm-device` pins it to
`pci-0000:01:00.0`. An application profile under
`/etc/nvidia/nvidia-application-profiles-rc.d/` sets `GLVidHeapReuseRatio` to 0 for
that process, so the driver returns freed buffers instead of pooling them.

**Reason:** after 24 hours niri was charged 1,640 MiB of VRAM while the dma-bufs it
still held accounted for 963 MiB. The remainder is the driver's free pool together
with niri's own EGL effect textures for blur — the two are not separable from
outside the process — but niri's anonymous memory was 15 MB, so none of the
retention was in its heap. Niri's wiki puts a healthy compositor near 100 MiB and
names 1 GiB as this quirk.

**Rejected alternative:** read the growth as a niri leak and restart the compositor
on a schedule, which trades session state for a pool that keeps behaving the same
way. The heap measurement rules niri out as the holder.

## The compositor renders on the dGPU

**Id:** 7dddb363-038e-4868-a457-25ccd4ab99e0
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** niri gains per-output render devices, the machine settles on a single
external monitor, or a MUX mode puts every output on one GPU

`debug.render-drm-device` points at the dGPU's render node
(`pci-0000:01:00.0-render`), the opposite of what Prime offload does by default.

**Reason:** only the Thunderbolt port scans out from the iGPU. A second external
monitor needs another port, and those scan out from the dGPU, so rendering on the
iGPU copies every frame of that monitor across the bus — the direction niri's FAQ
names as the one that stutters, and what happens here with two monitors attached.
Rendering on the dGPU pays a copy for the internal panel instead, which is the
cheaper trade once both monitors sit on dGPU ports: the panel is then the only
Intel-driven output.

**Rejected alternative:** render on the iGPU with a single external monitor on the
Thunderbolt port. That carries no copy at all and lets the dGPU stay parked, but it
stops working as soon as a second monitor appears, and the render device is fixed at
startup.
