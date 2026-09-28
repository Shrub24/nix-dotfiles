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
    # The provider plugins are JavaScript shipped as a SwiftPM resource bundle,
    # and the binary resolves it next to itself (executableDirectory), so the
    # bundle has to land in bin/ — without it every provider reports
    # "CodexBarCore resource bundle is missing next to the executable".
    cp -r CodexBar_CodexBarCore.bundle "$out/bin/"
    # Sibling of the binary too; read for the version string.
    install -Dm644 VERSION "$out/bin/VERSION"
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
