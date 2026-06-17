{
  lib,
  stdenv,
  fetchurl,
  version,
  hash,
  initHash,
  workerHash,
}:

let
  target = "x86_64-unknown-linux-gnu";
  initTarget = "x86_64-unknown-linux-musl"; # install script picks musl for iii-init on x86_64 Linux
  workerTarget = "x86_64-unknown-linux-gnu"; # iii-worker always uses glibc on x86_64 Linux

  baseUrl = "https://github.com/iii-hq/iii/releases/download/iii/v${version}";
in
stdenv.mkDerivation {
  pname = "iii-engine";
  inherit version;

  # Fetch all 3 component tarballs
  srcs = [
    (fetchurl {
      url = "${baseUrl}/iii-${target}.tar.gz";
      inherit hash;
    })
    (fetchurl {
      url = "${baseUrl}/iii-init-${initTarget}.tar.gz";
      hash = initHash;
    })
    (fetchurl {
      url = "${baseUrl}/iii-worker-${workerTarget}.tar.gz";
      hash = workerHash;
    })
  ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    for src in $srcs; do
      tar -xzf "$src"
    done
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    for bin in iii iii-init iii-worker; do
      if [ -f "$bin" ]; then
        cp "$bin" $out/bin/
        chmod 755 $out/bin/"$bin"
      fi
    done
    runHook postInstall
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
