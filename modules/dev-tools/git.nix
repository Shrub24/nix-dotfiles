_: {
  flake.modules.homeManager.git =
    { pkgs, ... }:
    let
      # nixpkgs' `git` is built without the libsecret credential helper; `gitFull`
      # ships it, so credentials stay in the login keyring.
      git = pkgs.gitFull;
    in
    {
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
          diff.tool = "nvimdiff";
          difftool.nvimdiff.cmd = "nvim -c DiffviewOpen $LOCAL $REMOTE";

          core = {
            autocrlf = "input";
            # delta's own git integration would rewire the jj pager in cli.nix.
            pager = "delta";
          };

          credential.helper = "${git}/bin/git-credential-libsecret";
        };

        lfs.enable = true;

        # Git and jj both read this when core.excludesFile is unset. Only the
        # mutable session data is ignored: projects version their own .pi skills
        # and settings.
        ignores = [ "**/.pi/sessions/" ];
      };

      programs.gh = {
        enable = true;
        # `hosts` stays unset: hosts.yml holds the auth token and remains
        # unmanaged.
        settings = {
          git_protocol = "https";
          aliases.co = "pr checkout";
        };
        gitCredentialHelper.enable = true;
      };
    };
}
