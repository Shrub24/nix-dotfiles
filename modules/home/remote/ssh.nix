{
  systemd.user.tmpfiles.rules = [
    "d %h/.ssh/ctl 0700 - - -"
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      # ── Global defaults (Interactive / Latency Baseline) ──────────
      "*" = {
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        ClearAllForwardings = "yes";
        Compression = "yes";
        HashKnownHosts = "yes";
        TCPKeepAlive = "no";
        StrictHostKeyChecking = "accept-new";
        VisualHostKey = "yes";
        IPQoS = "lowdelay";

        ControlPath = "~/.ssh/ctl/%r@%h:%p";
        ControlPersist = "600";
      };

      "eu.nixbuild.net" = {
        ControlMaster = "auto";
        StrictHostKeyChecking = "accept-new";
      };

      "Host oci-melb-1 do-admin-1" = {
        User = "dev";
        ControlMaster = "auto";
      };

      "Host github.com gitlab.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        ControlMaster = "auto";
        IPQoS = "throughput";
      };
    };
  };
}
