{ inputs, ... }:
{
  # The fork carries the package assets (desktop entry, icon, udev rule) and
  # the Home Manager module this repository configures. Its Rust build follows
  # the shared crane toolchain.
  flake-file.inputs.keypeek = {
    url = "github:Shrub24/keypeek";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.crane.follows = "crane";
  };

  flake.modules.homeManager.keypeek =
    { ... }:
    {
      imports = [ inputs.keypeek.homeManagerModules.default ];

      programs.keypeek = {
        enable = true;
        service.enable = true;
        settings = {
          size = 75;
          font_size_multiplier = 1.0;
          auto_fit_before_ellipsis = false;
          position = "Bottom";
          timeout = 2000;
          activation_delay = 0;
          offset_x = 10;
          offset_y = 10;
          visible_layers = "0xffffffff";
          font_color = "255,255,255,255";
          legend_mode = "Stacked";
          layer_color_0 = "83,83,83,239";
          layer_color_1 = "80,140,115,239";
          layer_color_2 = "100,115,150,239";
          layer_color_3 = "140,110,150,239";
          layer_color_4 = "95,121,127,239";
          layer_color_5 = "147,137,110,239";
          layer_color_6 = "127,127,127,239";
        };
      };
    };

  flake.modules.nixos.keypeek =
    { ... }:
    {
      imports = [ inputs.keypeek.nixosModules.default ];

      programs.keypeek.bleUdev.enable = true;
    };
}
