_: {
  flake.modules.nixos.foundation = {
    system.stateVersion = "26.11";
    networking.hostName = "arch";
    # Placeholder bootstrap user; real user config arrives with aspect side-port.
    users.users.saurabhj = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
