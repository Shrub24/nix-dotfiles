{
  environment.etc."ssh/ssh_config.d/30-remote-hosts.conf" = {
    text = ''
      # Remote build/managed hosts — ControlMaster enabled for multiplexing
      Host oci-melb-1 do-admin-1
        ControlMaster auto
        ControlPersist 600
        ControlPath /run/ssh-%r@%h:%p
        ServerAliveInterval 60
        ServerAliveCountMax 3
        StrictHostKeyChecking accept-new
        TCPKeepAlive no
        Compression no
        IPQoS throughput
        
    '';
    mode = "0644";
  };
}
