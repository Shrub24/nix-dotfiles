{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  glibc,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "byterover-cli";
  version = "3.16.1";

  src = fetchurl {
    url = "https://storage.googleapis.com/brv-releases/channels/stable/brv-linux-x64.tar.gz";
    hash = "sha256-V3EVPa6XGqFFJ5FtI486lwtbAKULVHwZw1Tz+oRbRu4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    glibc
    stdenv.cc.cc.lib
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/byterover-cli
    cp -r . $out/lib/byterover-cli

    makeWrapper $out/lib/byterover-cli/bin/node $out/bin/brv \
      --add-flags "$out/lib/byterover-cli/bin/run.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "ByteRover CLI (brv) - The portable memory layer for autonomous coding agents";
    homepage = "https://github.com/campfirein/byterover-cli";
    changelog = "https://github.com/campfirein/byterover-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.elastic20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "brv";
    platforms = [ "x86_64-linux" ];
  };
})
