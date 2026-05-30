{
  config,
  lib,
  appsDir,
  ...
}:

{
  home.file.".config/opencode".source =
    config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/opencode";
  home.file.".agents".source =
    config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/agents";
}
