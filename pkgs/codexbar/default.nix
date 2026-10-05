{
  lib,
  stdenvNoCC,
  version,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "codexbar";
  inherit version src;

  # nixpkgs' codexbar is macOS-only; upstream's Linux tarball has no top-level dir.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 CodexBarCLI $out/bin/codexbar
    # Must land in bin/: the binary resolves this SwiftPM bundle next to itself,
    # else providers fail with "CodexBarCore resource bundle is missing".
    cp -r CodexBar_CodexBarCore.bundle "$out/bin/"
    # Beside the binary too: the version string is read from there.
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
