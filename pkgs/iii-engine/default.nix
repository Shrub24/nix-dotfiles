{ lib, stdenv, fetchurl }:

let
  version = "0.11.2";
  target = "x86_64-unknown-linux-gnu";
in
stdenv.mkDerivation {
  pname = "iii-engine";
  inherit version;

  src = fetchurl {
    url = "https://github.com/iii-hq/iii/releases/download/iii/v${version}/iii-${target}.tar.gz";
    hash = "sha256-nIPEd4i070vutl3ZvzfpT5k3cM09uHRGTDzhzckjUs0=";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp iii $out/bin/
  '';

  passthru.version = version;

  meta = {
    description = "Runtime daemon for agentmemory — persistent memory for AI coding agents";
    homepage = "https://github.com/iii-hq/iii";
    license = lib.licenses.unfreeRedistributable; # ELv2 — source-available, not OSI-approved
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = [ ];
  };
}
