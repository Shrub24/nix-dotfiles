# Activation snippet for a file an application rewrites itself: seeding it
# through the store would break the app's rename-based saves, so the keys this
# repository owns are merged in instead and everything the app wrote survives.
{ pkgs }:
file: owned: ''
  cfg="$HOME/${file}"
  ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$cfg")"
  if ${pkgs.coreutils}/bin/test -s "$cfg"; then
    ${pkgs.jq}/bin/jq --argjson owned '${owned}' '. * $owned' "$cfg" > "$cfg.new"
  else
    ${pkgs.jq}/bin/jq -n --argjson owned '${owned}' '$owned' > "$cfg.new"
  fi
  ${pkgs.coreutils}/bin/mv -f "$cfg.new" "$cfg"
''
