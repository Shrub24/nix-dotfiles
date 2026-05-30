{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings."*" = {
      ControlMaster = "auto";
      ControlPersist = "600";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      Compression = true;
      HashKnownHosts = true;
      TCPKeepAlive = true;
      StrictHostKeyChecking = "accept-new";
      VisualHostKey = true;
    };
  };
}
