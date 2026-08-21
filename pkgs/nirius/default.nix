{
  lib,
  rustPlatform,
  version,
  src,
}:

rustPlatform.buildRustPackage {
  pname = "nirius";
  inherit version src;

  # Build metadata, not source metadata — stays inline by design.
  cargoHash = "sha256-RDDbx/JiyWwPOBEJDl7uJ1rGvGK1IYnjv0UTNjg+Yhc=";

  meta = {
    description = "Utility commands for the niri wayland compositor";
    homepage = "https://git.sr.ht/~tsdh/nirius";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "nirius";
  };
}
