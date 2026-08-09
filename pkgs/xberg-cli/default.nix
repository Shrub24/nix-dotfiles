{
  lib,
  stdenv,
  version,
  src,
}:

stdenv.mkDerivation {
  pname = "xberg-cli";
  inherit version src;

  sourceRoot = "xberg-cli-x86_64-unknown-linux-gnu";

  installPhase = ''
    mkdir -p $out/bin
    cp xberg $out/bin/
    chmod +x $out/bin/xberg
  '';

  meta = {
    description = "CLI for document extraction (PDF, Office, images)";
    homepage = "https://github.com/xberg-io/xberg";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "xberg";
  };
}
