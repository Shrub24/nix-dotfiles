{
  lib,
  buildNpmPackage,
  importNpmLock,
  piExtensions,
}:
let
  src = "${piExtensions}/pi-otel";
  manifest = lib.importJSON (src + "/package.json");

  # The dev-only Pi host entries lack integrity hashes and must not shadow
  # the running host's module aliases.
  lock = lib.importJSON (src + "/package-lock.json");
  package = lib.removeAttrs manifest [ "devDependencies" ];
  packageLock = lock // {
    packages = lib.filterAttrs (_: entry: !(entry.dev or false)) (
      lock.packages // { "" = lib.removeAttrs lock.packages."" [ "devDependencies" ]; }
    );
  };

  npmDeps = importNpmLock {
    inherit package packageLock;
    npmRoot = src;
  };
in
buildNpmPackage {
  pname = "pi-otel";
  inherit (manifest) version;
  inherit src;
  inherit npmDeps;

  inherit (importNpmLock) npmConfigHook;

  # The peer is the running Pi, which supplies it; npm must not resolve it.
  npmInstallFlags = [ "--legacy-peer-deps" ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp package.json $out/package.json
    cp -r src $out/src
    cp -r node_modules $out/node_modules
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    OUT=$out node -e '
      const fs = require("node:fs");
      const pkg = require(process.env.OUT + "/package.json");
      for (const entry of pkg.pi.extensions) fs.accessSync(process.env.OUT + "/" + entry);
      for (const name of Object.keys(pkg.dependencies)) {
        require.resolve(name, { paths: [process.env.OUT + "/src"] });
      }
    '
    runHook postInstallCheck
  '';

}
