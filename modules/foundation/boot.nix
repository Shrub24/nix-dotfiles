_: {
  flake.modules.systemManager.boot = {
    environment.etc."dracut.conf.d/10-optimise.conf".text = ''
      reproducible=yes
      compression=zstd
    '';

    # Matches the pre-existing live file (DRACUT_FALLBACK deliberately absent);
    # replaceExisting backs up the original before the first takeover.
    environment.etc."default/limine" = {
      replaceExisting = true;
      text = ''
          TARGET_OS_NAME="Endeavour OS"

        MAX_SNAPSHOT_ENTRIES="auto"

        EXCLUDE_SNAPSHOT_TYPES="post"

        SNAPPER_CONFIG_NAME="root"

        ROOT_SUBVOLUME_PATH="/@"

        ROOT_SNAPSHOTS_PATH="/@snapshots"

        ENABLE_RSYNC_ASK=no

        NOTIFICATION_ICON="/usr/share/icons/hicolor/128x128/apps/LimineSnapperSync.png"

        KERNEL_CMDLINE[default]+="quiet nowatchdog splash systemd.show_status=no rw nvme_core.default_ps_max_latency_us=0 zswap.enabled=0 rootflags=subvol=/@ root=UUID=35eb40c3-6466-4e66-ad20-9b7da9140992"

        SNAPSHOT_KERNEL_PARAMETERS-="quiet"
        SNAPSHOT_KERNEL_PARAMETERS-="splash"
      '';
    };
  }

  ;

  # NixOS translation: NixOS OWNS the boot config natively via boot.loader.* +
  # boot.initrd.* (see modules/hosts/arch/_hardware.nix — systemd-boot, btrfs,
  # zram, kernel modules, etc.). The systemManager aspect's Limine `default/limine`
  # conf and dracut.conf drop-in are Arch/transitional state that does NOT apply
  # to NixOS (NixOS uses its own initrd builder, not dracut; systemd-boot is the
  # loader, not Limine).
  #
  # ponytail: intentionally empty no-op. This aspect exists so the nixosAspects
  # registration stays parallel to systemAspects and future boot work has a home;
  # host-specific boot config lives in _hardware.nix, not here.
  flake.modules.nixos.boot = { ... }: { };
}
