{
  lib,
  stdenvNoCC,
  version,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "codexbar";
  inherit version src;

  # nixpkgs' codexbar is macOS-only; the project ships a Linux CLI tarball per release.
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
}
