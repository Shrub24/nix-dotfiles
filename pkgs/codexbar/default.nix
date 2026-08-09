{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codexbar";
  version = "0.48.0";

  # nixpkgs' codexbar is macOS-only; the project ships a Linux CLI tarball per release.
  src = fetchurl {
    url = "https://github.com/steipete/CodeXBar/releases/download/v${finalAttrs.version}/CodexBarCLI-v${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256:0wqsqhpkfa2fyp8lynlrbmrvaxksgz13np77s83fxkkk4xc58w6c";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 CodexBarCLI $out/bin/codexbar
    runHook postInstall
  '';

  meta = {
    description = "Show usage stats for AI coding-provider limits";
    homepage = "https://codex.bar/";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.linux;
  };
})
