{
  lib,
  stdenv,
  autoPatchelfHook,
  makeWrapper,
  glibc,
  version,
  src,
}:

stdenv.mkDerivation {
  pname = "byterover-cli";
  inherit version src;

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

  meta = {
    description = "ByteRover CLI (brv) - The portable memory layer for autonomous coding agents";
    homepage = "https://github.com/campfirein/byterover-cli";
    changelog = "https://github.com/campfirein/byterover-cli/releases/tag/v${version}";
    license = lib.licenses.elastic20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "brv";
    platforms = [ "x86_64-linux" ];
  };
}
