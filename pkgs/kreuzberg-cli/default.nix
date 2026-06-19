{
  lib,
  stdenv,
  version,
  src,
}:

stdenv.mkDerivation {
  pname = "kreuzberg-cli";
  inherit version src;

  sourceRoot = "kreuzberg-cli-x86_64-unknown-linux-gnu";

  installPhase = ''
    mkdir -p $out/bin
    cp kreuzberg $out/bin/
    chmod +x $out/bin/kreuzberg
  '';

  meta = {
    description = "CLI for document extraction (PDF, Office, images)";
    homepage = "https://github.com/kreuzberg-dev/kreuzberg";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "kreuzberg";
  };
}
