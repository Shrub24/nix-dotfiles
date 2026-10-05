# The data disk's topology: UUID and subvolume names nothing else restates.
#
# TODO: mountpoint, homeMountpoint, homeChurn, nodatacow and homeUser have no
# consumer; the subvolumes and +C were realised by
# docs/runbooks/migrate-home-to-data-disk.md. Drop them, or adopt them in disko,
# when the data disk is next reorganised.
#
# homeChurn paths are nested subvolumes, so home snapshots exclude them.
# Snapshots do not descend into child subvolumes. Regenerable state only.
#
# nodatacow paths are created empty and chattr +C first (CoW fragments and
# random-write/SQLite loads); caches are excluded — nodatacow also stops
# compression.
{ primaryUser }:
{
  storage.dataDisk = {
    uuid = "47fa5ee2-addd-466b-b7fc-4e7d92968234";

    # subvolid=5 stays unmounted at runtime; these two are the whole runtime surface.
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

    # Regenerable state, kept out of home snapshots; one subvolume per root.
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

    nodatacow = [
      ".local/share/containers" # podman overlay on CoW = fragmentation
      ".mozilla" # SQLite profile thrash
    ];

    # Plain directory inside @home — home snapshots must capture its contents.
    homeUser = primaryUser.name;
  };
}
