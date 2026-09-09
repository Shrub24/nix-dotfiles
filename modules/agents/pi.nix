{ inputs, ... }:
{
  flake.modules.homeManager.pi =
    { config, pkgs, ... }:
    {
      programs.pi-coding-agent.package =
        (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
          useBun = true;
        }).overrideAttrs
          (old: {
            preInstall =
              builtins.replaceStrings
                [ "bun build --compile ./dist/bun/cli.js" ]
                [
                  "bun build --compile --no-compile-autoload-bunfig --compile-autoload-package-json ./dist/bun/cli.js"
                ]
                old.preInstall;
            postInstall =
              builtins.replaceStrings
                [
                  ''rm -rf "$out/lib" "$out/bin"''
                  ''--set PI_PACKAGE_DIR "$pkgdir"''
                ]
                [
                  ''rm -rf "$out/bin"''
                  ''--set PI_PACKAGE_DIR "$pkgdir" --set PI_SUBAGENTS_PI_CODING_AGENT_PACKAGE_ROOT "$out/libexec/pi-js-package"''
                ]
                old.postInstall
              + ''
                piPackage="$out/lib/node_modules/@earendil-works/pi-coding-agent"
                test -f "$piPackage/package.json"
                mkdir -p "$out/libexec"
                ln -s "$piPackage" "$out/libexec/pi-js-package"
              '';
          });

      home.file.".pi/agent".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/pi";
    };
}
