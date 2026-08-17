_: {
  flake.modules.homeManager.fonts =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        maple-mono.truetype
        maple-mono.NF
        fira-code
        liberation_ttf
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        open-sans
        dejavu_fonts
        cantarell-fonts
      ];
    };
}
