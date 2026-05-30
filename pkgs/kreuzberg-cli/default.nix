{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation {
  pname = "kreuzberg-cli";
  version = "4.9.7";

  src = fetchurl {
    url = "https://github.com/kreuzberg-dev/kreuzberg/releases/download/v4.9.7/kreuzberg-cli-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-WTqB5tTrKGnzlVf7tSeDuMpj4YstitGn+9dvOW5rl5o=";
  };

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
