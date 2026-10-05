{
  bat,
  coreutils,
  writeShellApplication,
  zip,
}:
{
  # Upstream's bat hook also rewrites ~/.config/bat/config, which is Nix-rendered
  # here (theme comes from BAT_THEME), so only the cache rebuild is left.
  bat = writeShellApplication {
    name = "noctalia-template-bat";
    runtimeInputs = [ bat ];
    text = ''
      bat cache --build
    '';
  };

  # apply.sh runs from a writable copy: upstream's libreoffice hook assembles its
  # .oxt inside the template dir, which is read-only in the store.
  stage = writeShellApplication {
    name = "noctalia-template-stage";
    runtimeInputs = [
      coreutils
      zip
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: noctalia-template-stage <template-dir>" >&2
        exit 2
      fi
      source_dir="$1"
      build="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/template-stage/$(basename "$source_dir")"
      rm -rf "$build"
      mkdir -p "$(dirname "$build")"
      cp -r "$source_dir" "$build"
      chmod -R u+w "$build"
      exec bash "$build/apply.sh"
    '';
  };
}
