{
  lib,
  stdenvNoCC,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "nixos-boot";
  version = "0.2.0"; # upstream's declared version; the pin is flake.lock's rev.

  inherit src;
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    theme=load_unload
    dir=$out/share/plymouth/themes/$theme
    install -Dm644 "$src/src/$theme/$theme.plymouth" "$dir/$theme.plymouth"
    install -Dm644 "$src/src/$theme/$theme.script" "$dir/$theme.script"
    install -Dm644 -t "$dir" "$src/src/$theme/"*.png

    # Upstream patches an unused generic.script; its installed script also names nonexistent frames.
    substituteInPlace "$dir/$theme.script" \
      --replace-fail 'Window.SetBackgroundTopColor (1, 1, 1);' 'Window.SetBackgroundTopColor (0, 0, 0);' \
      --replace-fail 'Window.SetBackgroundBottomColor (1, 1, 1);' 'Window.SetBackgroundBottomColor (0, 0, 0);' \
      --replace-fail 'image_prefix = "nixos-";' 'image_prefix = "";'

    substituteInPlace "$dir/$theme.plymouth" --replace-fail /usr/ "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Plymouth theme showing a growing and shrinking NixOS logo on a black background";
    homepage = "https://github.com/Melkor333/nixos-boot";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
