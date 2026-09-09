{
  bat,
  coreutils,
  writeShellApplication,
  zip,
}:
{
  # Upstream's bat hook also rewrites ~/.config/bat/config to select the theme.
  # That file is Nix-rendered here and the selection lives in the BAT_THEME
  # session variable, so only the cache rebuild is left.
  bat = writeShellApplication {
    name = "noctalia-template-bat";
    runtimeInputs = [ bat ];
    text = ''
      bat cache --build
    '';
  };

  # Run a template's own apply.sh from a writable copy. Upstream's libreoffice
  # hook assembles its .oxt inside its own directory, which is read-only in the
  # store; the script resolves its static files relative to its own location, so
  # staging the directory carries them along.
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
