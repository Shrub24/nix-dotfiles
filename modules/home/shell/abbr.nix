# Shared abbreviation definitions for fish and zsh.
# Each entry: abbr_name = { expansion = "..."; global = true/false (optional) }
# `global = true` means position="anywhere" in fish, globalAbbreviation in zsh.
{
  # ---- Git ----
  g = { expansion = "git"; };
  ga = { expansion = "git add"; };
  gaa = { expansion = "git add --all"; };
  gap = { expansion = "git add -p"; };
  gb = { expansion = "git branch"; };
  gbd = { expansion = "git branch -D"; };
  gc = { expansion = "git commit -v"; };
  gca = { expansion = "git commit -v --amend"; };
  gcl = { expansion = "git clone"; };
  gco = { expansion = "git checkout"; };
  gd = { expansion = "git diff"; };
  gds = { expansion = "git diff --staged"; };
  gf = { expansion = "git fetch"; };
  gl = { expansion = "git log --oneline --graph"; };
  glg = { expansion = "git log --oneline --graph --all"; };
  gp = { expansion = "git push"; };
  gpf = { expansion = "git push --force-with-lease"; };
  gpl = { expansion = "git pull --rebase"; };
  grb = { expansion = "git rebase"; };
  grba = { expansion = "git rebase --abort"; };
  grbc = { expansion = "git rebase --continue"; };
  grbi = { expansion = "git rebase -i"; };
  grs = { expansion = "git restore"; };
  grst = { expansion = "git restore --staged"; };
  gst = { expansion = "git status"; };
  gsw = { expansion = "git switch"; };
  gswc = { expansion = "git switch -c"; };

  # ---- File system ----
  mkdir = { expansion = "mkdir -p"; };

  # ---- Nix ----
  nd = { expansion = "nix develop"; };
  nb = { expansion = "nix build"; };
  nf = { expansion = "nix flake"; };
  nfu = { expansion = "nix flake update"; };
  ns = { expansion = "nix search"; };
  ne = { expansion = "nix eval"; };
  nr = { expansion = "nix run"; };
  nixos-rebuild = { expansion = "sudo nixos-rebuild"; };

  # ---- systemd ----
  sc = { expansion = "systemctl"; };
  scu = { expansion = "systemctl --user"; };
  scs = { expansion = "systemctl status"; };
  scsr = { expansion = "systemctl restart"; };
  scst = { expansion = "systemctl start"; };
  scsp = { expansion = "systemctl stop"; };
  scr = { expansion = "systemctl reload"; };
  sce = { expansion = "systemctl enable --now"; };
  scd = { expansion = "systemctl disable --now"; };
  scf = { expansion = "systemctl list-units --failed"; };
  scl = { expansion = "systemctl list-units"; };
  scucl = { expansion = "systemctl --user list-units"; };

  # ---- journalctl ----
  jc = { expansion = "journalctl"; };
  jcb = { expansion = "journalctl -b"; };
  jcf = { expansion = "journalctl -f"; };
  jce = { expansion = "journalctl -xe"; };
  jcu = { expansion = "journalctl --user"; };
  jcuf = { expansion = "journalctl --user -f"; };
  jcs = { expansion = "journalctl -u"; };
  jcus = { expansion = "journalctl --user -u"; };

  # ---- Pipe abbreviations (global/anywhere) ----
  G = { expansion = "| grep"; global = true; };
  L = { expansion = "| less"; global = true; };
  H = { expansion = "| head"; global = true; };
  T = { expansion = "| tail"; global = true; };
  C = { expansion = "| wc -l"; global = true; };
  X = { expansion = "| xargs"; global = true; };
  F = { expansion = "| fzf"; global = true; };
}
