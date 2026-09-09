{
  inputs,
  system,
  lib,
  lld,
  installShellFiles,
  perl,
  gnumake,
  version,
  src,
}:
let
  pkgsBase = inputs.nixpkgs.legacyPackages.${system};
  inherit ((inputs.fenix.packages.${system}.toolchainOf {
      channel = "nightly";
      # Must match rust-toolchain.toml in the pinned cass source.
      date = "2026-08-31";
      sha256 = "sha256-ko0a8G9o/p60mphrxmH0dNQsUdWkKMBaGexsqEqtCF4=";
    })) toolchain;
  craneLib = (inputs.crane.mkLib pkgsBase).overrideToolchain toolchain;
  unpacked = pkgsBase.runCommand "cass-${version}-source" { } ''
    mkdir -p $out
    tar -xzf ${src} -C $out --strip-components=1
  '';
  common = {
    src = unpacked;
    cargoLock = "${unpacked}/Cargo.lock";
    outputHashes = {
      "git+https://github.com/Dicklesworthstone/frankensqlite?rev=2d8a68b9ad82d685f8bacd9d5fe3c8fe5304a0e4#2d8a68b9ad82d685f8bacd9d5fe3c8fe5304a0e4" =
        "sha256-XVv6NeU11TE4LP6qTAnBBbbmkjn5lhJDEvxXYLfa9sg=";
    };
    nativeBuildInputs = [
      lld
      installShellFiles
      # openssl-src compiles vendored OpenSSL from source.
      perl
      gnumake
    ];
    # Upstream gate is an e2e/perf harness; unsuitable for the sandbox.
    doCheck = false;
  };
  cargoArtifacts = craneLib.buildDepsOnly common;
in
craneLib.buildPackage (
  common
  // {
    inherit cargoArtifacts version;
    pname = "cass";
    postInstall = ''
      install -Dm444 ${unpacked}/SKILL.md $out/share/cass/SKILL.md
      installShellCompletion --cmd cass \
        --bash <($out/bin/cass completions bash) \
        --fish <($out/bin/cass completions fish) \
        --zsh <($out/bin/cass completions zsh)
    '';
    meta = {
      description = "Search coding-agent session history across tools";
      homepage = "https://github.com/Dicklesworthstone/coding_agent_session_search";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "cass";
    };
  }
)
