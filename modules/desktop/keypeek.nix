{ inputs, ... }:
{
  flake.modules.homeManager.keypeek =
    { ... }:
    {
      imports = [ inputs.keypeek.homeManagerModules.default ];

      programs.keypeek = {
        enable = true;
        # The service is what reads the generated INI (`--config`), and it is the
        # only mode that keeps settings declarative: the interactive settings UI
        # writes state, so it stays off the service's own instance.
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

      # ZMK BLE boards have no USB identity, so the packaged rule matches modalias;
      # USB access for the same board is declared in the desktop-services aspect.
      programs.keypeek.bleUdev.enable = true;
    };
}
