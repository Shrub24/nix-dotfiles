{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "byterover-cli";
  version = "3.16.1";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "campfirein";
    repo = "byterover-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-p2sSvlL8zUd4k3ex0Am0Tds5jwbmrtoZmoLRPt+fidM=";
  };

  npmDeps = importNpmLock {
    npmRoot = finalAttrs.src;
  };

  npmFlags = [ "--legacy-peer-deps" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "ByteRover CLI (brv) - The portable memory layer for autonomous coding agents";
    homepage = "https://github.com/campfirein/byterover-cli";
    changelog = "https://github.com/campfirein/byterover-cli/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.elastic20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "brv";
    platforms = lib.platforms.all;
  };
})
