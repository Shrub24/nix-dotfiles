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

      # ---- systemd ----
      sc = "systemctl";
      scu = "systemctl --user";
      scs = "systemctl status";
      scsr = "systemctl restart";
      scst = "systemctl start";
      scsp = "systemctl stop";
      scr = "systemctl reload";
      sce = "systemctl enable --now";
      scd = "systemctl disable --now";
      scf = "systemctl list-units --failed";
      scl = "systemctl list-units";
      scucl = "systemctl --user list-units";

      # ---- journalctl ----
      jc = "journalctl";
      jcb = "journalctl -b";
      jcf = "journalctl -f";
      jce = "journalctl -xe";
      jcu = "journalctl --user";
      jcuf = "journalctl --user -f";
      jcs = "journalctl -u";
      jcus = "journalctl --user -u";

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

