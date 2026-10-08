{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libheif,
  writeShellScript,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xberg-cli";
  version = "1.3.6";
  # The version has to appear in the URL for nix-update to rewrite the source
  # when it bumps the version attribute.
  src = fetchurl {
    url = "https://github.com/xberg-io/xberg/releases/download/v${finalAttrs.version}/xberg-cli-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-fakh+dL4FH3LbnOie0hwJpStNlZwPkB/AO/YZZhbx3A=";
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

  passthru.updateScript = writeShellScript "update-xberg-cli" ''
    set -euo pipefail
    version="''${XBERG_UPDATE_VERSION:-stable}"
    if [[ "$version" != stable && ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "xberg-cli: expected stable or an exact stable vX.Y.Z tag, got: $version" >&2
      exit 2
    fi
    # The capture groups are load-bearing: extract_version only accepts a tag
    # when the regex matches with groups, and joins the groups as the version.
    exec nix-update --flake --version "$version" --version-regex '^v([0-9]+)\.([0-9]+)\.([0-9]+)$' xberg-cli
  '';

  meta = {
    description = "CLI for document extraction (PDF, Office, images)";
    homepage = "https://github.com/xberg-io/xberg";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "xberg";
  };
})
