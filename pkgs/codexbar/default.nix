{
  lib,
  stdenvNoCC,
  fetchurl,
  writeShellScript,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codexbar";
  version = "0.73.0";
  # The version has to appear in the URL for nix-update to rewrite the source
  # when it bumps the version attribute.
  src = fetchurl {
    url = "https://github.com/steipete/CodeXBar/releases/download/v${finalAttrs.version}/CodexBarCLI-v${finalAttrs.version}-linux-x86_64.tar.gz";
    sha256 = "sha256-qE9VbH7OvI5gbgo07g0SFib3LXr8HjrfV0ZBC8EPlhE=";
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
  passthru.updateScript = writeShellScript "update-codexbar" ''
    set -euo pipefail
    version="''${CODEXBAR_UPDATE_VERSION:-stable}"
    exec nix-update --flake --version "$version" codexbar
  '';

  meta = {
    description = "Show usage stats for AI coding-provider limits";
    homepage = "https://codex.bar/";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.linux;
  };
})
