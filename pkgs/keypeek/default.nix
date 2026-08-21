{
  inputs,
  system,
}:
inputs.keypeek.packages.${system}.default.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    install -Dm644 ${inputs.keypeek}/cargo-appimage.desktop \
      "$out/share/applications/keypeek.desktop"
    install -Dm644 resources/icon.svg \
      "$out/share/icons/hicolor/scalable/apps/keypeek.svg"
  '';
})
