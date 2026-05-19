{ config, ... }:
{
  programs.zsh.zsh-abbr = {
    enable = true;

    abbreviations = {
      # ---- Git ----
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gap = "git add -p";
      gb = "git branch";
      gbd = "git branch -D";
      gc = "git commit -v";
      gca = "git commit -v --amend";
      gcl = "git clone";
      gco = "git checkout";
      gd = "git diff";
      gds = "git diff --staged";
      gf = "git fetch";
      gl = "git log --oneline --graph";
      glg = "git log --oneline --graph --all";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gpl = "git pull --rebase";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase -i";
      grs = "git restore";
      grst = "git restore --staged";
      gst = "git status";
      gsw = "git switch";
      gswc = "git switch -c";

      # ---- File system ----
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -iv";
      mkdir = "mkdir -p";

      # ---- System ----
      df = "duf";
      ps = "procs";
      top = "btm";

      # ---- Nix ----
      nd = "nix develop";
      nb = "nix build";
      nf = "nix flake";
      nfu = "nix flake update";
      ns = "nix search";
      ne = "nix eval";
      nr = "nix run";
      nixos-rebuild = "sudo nixos-rebuild";

      # ---- Misc ----
      cat = "bat";
      du = "dust";
      sed = "sd";
    };

    globalAbbreviations = {
      G = "| grep";
      L = "| less";
      H = "| head";
      T = "| tail";
      C = "| wc -l";
      X = "| xargs";
      F = "| fzf";
    };
  };
}

