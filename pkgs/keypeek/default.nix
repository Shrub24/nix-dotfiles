{
  inputs,
  system,
}:
inputs.keypeek.packages.${system}.default.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./zmk-default-vid-pid.patch ];
  postInstall = (old.postInstall or "") + ''
    install -Dm644 ${inputs.keypeek}/cargo-appimage.desktop \
      "$out/share/applications/keypeek.desktop"
    install -Dm644 resources/icon.svg \
      "$out/share/icons/hicolor/scalable/apps/keypeek.svg"
  '';
})
