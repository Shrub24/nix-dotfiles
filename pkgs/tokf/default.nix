{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tokf";
  version = "0.2.45";

  src = fetchFromGitHub {
    owner = "mpecan";
    repo = "tokf";
    tag = "catalog-types-v${finalAttrs.version}";
    hash = "sha256-xTSBmLWSZ1OELHLPJKboirk/iUadfMdoHG+Oh6+gP+0=";
  };

  cargoHash = "sha256-rkn+fhCFUGwHPtcwYwu0RNQ/kp60x46Wc+9SqwPiRG8=";

  doCheck = false;

  postInstall = ''
    $out/bin/tokf completions zsh > _tokf
    install -D _tokf $out/share/zsh/site-functions/_tokf
    $out/bin/tokf completions bash > tokf
    install -D tokf $out/share/bash-completion/completions/tokf
    $out/bin/tokf completions fish > tokf.fish
    install -D tokf.fish $out/share/fish/vendor_completions.d/tokf.fish
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  meta = {
    description = "Config-driven CLI tool that compresses command output before it reaches an LLM context";
    homepage = "https://github.com/mpecan/tokf";
    changelog = "https://github.com/mpecan/tokf/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    # maintainers = with lib.maintainers; [ ];
    mainProgram = "tokf";
  };
})
