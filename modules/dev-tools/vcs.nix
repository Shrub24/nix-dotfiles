_: {
  flake.modules.homeManager.vcs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # nixpkgs' `git` is built without the libsecret credential helper; `gitFull`
      # ships it, so credentials stay in the login keyring.
      git = pkgs.gitFull;
    in
    {
      home.packages = with pkgs; [
        lazyjj
        jj-hunk-tool
        difftastic # `jj diff --tool difft` (jj ships the preset)
      ];

      # delta owns jj's pager, diff formatter, and merge tool.
      programs.delta = {
        enable = true;
        enableJujutsuIntegration = true;
        options = {
          features = "line-numbers";
          navigate = true;
        };
      };

      programs.git = {
        enable = true;
        package = git;

        settings = {
          user = {
            name = "Saurabh";
            email = "jhanjeesaurabh@gmail.com";
          };

          init.defaultBranch = "main";
          pull.rebase = true;
          push = {
            default = "current";
            followTags = true;
            autoSetupRemote = true;
          };
          branch.sort = "-committerdate";

          alias.dv = "!nvim -c DiffviewOpen";

          core = {
            autocrlf = "input";
            # delta's own git integration would rewire the jj pager set below.
            pager = "delta";
          };

          credential.helper = "${git}/bin/git-credential-libsecret";
        };

        lfs.enable = true;

        ignores = [
          "**/.pi/sessions/"
          "**/.pi-herdsman/"
          "**/node_modules/"
          "**/.direnv/"
          "**/__pycache__/"
          "**/.venv/"
          "**/.DS_Store"
          "result"
          "result-*"
        ];
      };

      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "https";
          aliases.co = "pr checkout";
        };
        gitCredentialHelper.enable = true;
      };

      programs.lazygit.enable = true;

      programs.jjui.enable = true;

      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = "Saurabh Jhanjee";
            email = "jhanjeesaurabh@gmail.com";
          };
          ui.editor = "nvim";
          # Partial diffs (jj split/squash -i/absorb) open hunk.nvim; without this
          # jj falls back to its builtin line editor.
          ui.diff-editor = [
            "nvim"
            "-c"
            "DiffEditor $left $right $output"
          ];
          ui.diff-instructions = false;
          git.push-new-bookmarks = true;
          # Interactive viewer: `jj diff --tool hunk`, `jj interdiff --tool hunk`.
          # The shell wrapper reattaches a tty because jj captures diff output.
          "merge-tools".hunk = {
            program = "sh";
            diff-invocation-mode = "dir";
            diff-do-chdir = false;
            conflict-marker-style = "snapshot";
            diff-args = [
              "-c"
              ''exec nvim -c "HunkDiffView $1 $2" </dev/tty >/dev/tty''
              "hunk-difftool"
              "$left"
              "$right"
            ];
          };
          lazyjj.diff-format = "git";
          "--scope" = [
            {
              "--when".environments = [ "JJUI" ];
              ui = {
                diff-formatter = lib.getExe config.programs.delta.finalPackage;
                paginate = "never";
              };
            }
          ];
        };
      };
    };
}
