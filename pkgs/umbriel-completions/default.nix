{
  lib,
  runCommand,
  umbriel,
}:

# Umbriel ships no shell completions, so the file is generated from the binary's
# own help: its commands, `msg` actions, `config` subcommands and `subscribe`
# events. Regenerating on every Umbriel bump keeps the list in step with it.
runCommand "umbriel-completions" { } ''
  umbriel=${lib.getExe umbriel}
  strip() { sed 's/\x1b\[[0-9;]*m//g'; }
  top=$("$umbriel" --help 2>&1 | strip || true)
  msg=$("$umbriel" msg --help 2>&1 | strip || true)

  mkdir -p $out
  {
    echo "# Generated from \`umbriel --help\` and \`umbriel msg --help\`; do not edit."
    echo "# Umbriel ships no completions upstream."
    echo

    # One candidate per line: fish treats a space-separated -a string as one word.
    printf '%s\n' "$top" | awk '
      /^  [a-z]/ && $2 != "|" {
        name = $1
        if (name in seen) next
        seen[name] = 1
        print "complete -c umbriel -f -n __fish_use_subcommand -a " name
      }'
    echo

    printf '%s\n' "$msg" | awk '
      /^  [a-z]/ && $2 != "|" {
        name = $1; sub(/:.*/, "", name)
        if (name in seen) next
        seen[name] = 1
        desc = $0; sub(/^  [^ ]+ */, "", desc)
        gsub(/\047/, "\\\047", desc)
        printf "complete -c umbriel -f -n \047__fish_seen_subcommand_from msg\047 -a %s -d \047%s\047\n", name, desc
      }'
    echo

    for w in validate schema; do
      echo "complete -c umbriel -f -n '__fish_seen_subcommand_from config' -a $w"
    done
    events=$(printf '%s\n' "$top" | sed -n 's/.*events: //p' | tr -d ',')
    for e in $events; do
      echo "complete -c umbriel -f -n '__fish_seen_subcommand_from subscribe' -a $e"
    done
  } > $out/umbriel.fish
''
