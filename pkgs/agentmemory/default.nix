{ lib, buildNpmPackage, fetchurl, makeWrapper, iii-engine, nodejs }:

buildNpmPackage rec {
  pname = "agentmemory";
  version = "0.9.21";

  src = fetchurl {
    url = "https://registry.npmjs.org/@agentmemory/agentmemory/-/agentmemory-${version}.tgz";
    hash = "sha256-M/qn1BNhIS7o+Bx1/3y90WAuKULbbrMbtIFHmoth1Dw=";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-O7ffF55gU/iYSEolwbIl4CY6mZ/Im7thKSuUeJoi15Q=";

  npmFlags = [ "--legacy-peer-deps" "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/agentmemory \
      --prefix PATH : ${lib.makeBinPath [ iii-engine ]}
  '';

  meta = {
    description = "Persistent memory for AI coding agents — powered by iii-engine";
    homepage = "https://github.com/rohitg00/agentmemory";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
