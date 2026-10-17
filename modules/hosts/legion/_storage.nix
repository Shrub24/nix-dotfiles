# The data disk's UUID, the two subvolumes the runtime mounts, and their options.
{
  storage.dataDisk = {
    uuid = "47fa5ee2-addd-466b-b7fc-4e7d92968234";

    # subvolid=5 stays unmounted at runtime; these two are the whole runtime surface.
    homeSubvol = "@home";
    dataSubvol = "@data";

    commonOptions = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
}
