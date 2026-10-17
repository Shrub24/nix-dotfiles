{
  lib,
  stdenvNoCC,
  fetchurl,
  python3,
  nix-update,
  writeShellApplication,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codexbar";
  version = "0.77.0";
  # The version has to appear in the URL for nix-update to rewrite the source
  # when it bumps the version attribute.
  src = fetchurl {
    url = "https://github.com/steipete/CodexBar/releases/download/v${finalAttrs.version}/CodexBarCLI-v${finalAttrs.version}-linux-x86_64.tar.gz";
    sha256 = "sha256-qcMLi1bsL8hSa2O6Ry8xmJYFx+AcLGWslbSr8gt+VNQ=";
  };

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

  # Preserve nix-update's standard discovery; the recorded target is an
  # opt-in for reproducible acceptance because the fleet app has no flag passthrough.
  passthru.updateScript = lib.getExe (writeShellApplication {
    name = "codexbar-update";
    runtimeInputs = [
      python3
      nix-update
    ];
    text = ''
      exec python3 ${./update.py}
    '';
  });

  meta = {
    description = "Show usage stats for AI coding-provider limits";
    homepage = "https://codex.bar/";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.linux;
  };
})
