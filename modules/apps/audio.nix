_: {
  flake.modules.homeManager.audio =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.feishin
        pkgs.kid3-qt
        pkgs.easyeffects
        pkgs.qpwgraph
        pkgs.lsp-plugins
        pkgs.ladspa-sdk
      ];
    };
}
