_: {
  # Literal system double: the system-manager scope has no `pkgs.stdenv`.
  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;

  # Machine-specific boot: this disk's dracut drop-in and the Limine/snapper conf
  # naming this root subvolume. No shared aspect can own either.
  environment.etc."dracut.conf.d/10-optimise.conf".text = ''
    reproducible="yes"
    hostonly="yes"
    hostonly_mode="strict"
    compress="zstd"
    omit_drivers+=" nouveau "
  '';

  # Matches the live file (DRACUT_FALLBACK deliberately absent); replaceExisting
  # backs the original up before the first takeover.
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
