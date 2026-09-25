# The data disk's topology, stated once. Everything that names a device UUID
# or a subvolume of this disk derives from here — the system-manager mount
# units and skeleton, the NixOS fileSystems, and the disko capture. Nothing
# downstream restates these facts.
#
# homeChurn paths exist as nested subvolumes under @home so btrfs snapshots
# of the home subvolume exclude them: snapshots do not descend into child
# subvolumes, which is the whole mechanism. Only regenerable state belongs
# here — caches, indices, container storage, package stores.
# nodatacow paths are created empty and marked +C before any data lands:
# random-write and SQLite workloads fragment under CoW. Caches are NOT in
# this set — nodatacow also disables compression.
{ primaryUser }:
{
  storage.dataDisk = {
    uuid = "47fa5ee2-addd-466b-b7fc-4e7d92968234";

    # subvolid=5 stays unmounted at runtime except for admin passes; the
    # two subvolumes below are the whole runtime surface of this disk.
    homeSubvol = "@home";
    dataSubvol = "@data";

    mountpoint = "/data";
    homeMountpoint = "/home";

    commonOptions = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];

    # Regenerable state, kept out of the home snapshots. One subvolume per
    # root, coarse by design: per-tool lists rot (aube and cortexkit were
    # both misses).
    homeChurn = [
      ".cache"
      ".local/share"
      ".local/state"
      ".npm"
      ".bun"
      "go"
      ".cargo"
      ".rustup"
      ".nuget"
      ".gradle"
    ];

    # Created empty and chattr +C before any data lands.
    nodatacow = [
      ".local/share/containers" # podman overlay on CoW = fragmentation
      ".mozilla" # SQLite profile thrash
    ];

    # The user directory inside @home. Plain directory, not a subvol — the
    # home snapshots must capture its contents.
    homeUser = primaryUser.name;
  };
}
