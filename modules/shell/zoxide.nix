_: {
  # zoxide keeps every directory it has ever seen. Its aging is a capacity valve,
  # not a clock: scores are only rescaled when the database's total passes
  # _ZO_MAXAGE (10000), and an entry is dropped only once its rescaled score
  # falls below 1. A database of a few hundred points therefore never ages, so a
  # deleted or abandoned directory keeps the rank it earned.
  #
  # This is the missing clock. It reads the database, reports the entries whose
  # directory is gone, and removes them on request.
  flake.modules.homeManager.zoxide =
    { pkgs, ... }:
    let
      prune = pkgs.writeShellApplication {
        name = "zoxide-prune";
        runtimeInputs = [ pkgs.zoxide ];
        text = ''
          apply=false
          all=false
          for arg in "$@"; do
            case "$arg" in
              --apply) apply=true ;;
              --all) all=true ;;
              *)
                echo "usage: zoxide-prune [--apply] [--all]" >&2
                echo "  --apply  remove the entries, not just list them" >&2
                echo "  --all    include paths outside \$HOME" >&2
                exit 2
                ;;
            esac
          done

          # Paths outside $HOME are skipped by default: a directory under an
          # unmounted filesystem (/mnt/Shared, a removable disk) is missing for a
          # reason that has nothing to do with the database.
          missing=0
          while IFS= read -r dir; do
            test -d "$dir" && continue
            if [ "$all" = false ]; then
              case "$dir" in
                "$HOME"/*) ;;
                *) continue ;;
              esac
            fi
            missing=$((missing + 1))
            if [ "$apply" = true ]; then
              zoxide remove "$dir" 2>/dev/null || continue
              printf 'removed  %s\n' "$dir"
            else
              printf 'missing  %s\n' "$dir"
            fi
          done < <(zoxide query --list)

          if [ "$missing" -eq 0 ]; then
            echo "zoxide-prune: every entry exists"
          elif [ "$apply" = false ]; then
            echo "zoxide-prune: $missing missing (re-run with --apply to remove)"
          else
            echo "zoxide-prune: removed $missing"
          fi
        '';
      };
    in
    {
      home.packages = [ prune ];
    };
}
