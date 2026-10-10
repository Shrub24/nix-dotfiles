{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libheif,
  python3,
  nix-update,
  writeShellApplication,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xberg-cli";
  version = "1.3.8";
  # The version has to appear in the URL for nix-update to rewrite the source
  # when it bumps the version attribute.
  src = fetchurl {
    url = "https://github.com/xberg-io/xberg/releases/download/v${finalAttrs.version}/xberg-cli-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-XfQChc1/u3GOgWDCHjzDjhHnrrolOkzyBsy2Nj/8LSA=";
  };

  sourceRoot = "xberg-cli-x86_64-unknown-linux-gnu";

  # The shipped binary is prebuilt and links libheif and the C++ runtime.
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    libheif
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp xberg $out/bin/
    chmod +x $out/bin/xberg
  '';

  passthru = {
    updateScript = lib.getExe (writeShellApplication {
      name = "xberg-cli-update";
      runtimeInputs = [
        python3
        nix-update
      ];
      text = ''
        exec python3 ${./update.py}
      '';
    });
    checkUpdate = writeShellApplication {
      name = "xberg-cli-check-update";
      runtimeInputs = [ python3 ];
      text = ''
        exec python3 ${./update.py} --latest
      '';
    };
  };

  meta = {
    description = "CLI for document extraction (PDF, Office, images)";
    homepage = "https://github.com/xberg-io/xberg";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "xberg";
  };
})
