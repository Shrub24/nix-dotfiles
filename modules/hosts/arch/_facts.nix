{
  # Host-only machine facts for the Arch desktop host. Passed as `hostFacts`
  # specialArgs to BOTH home-manager and system-manager so reusable feature
  # modules never duplicate these literals.
  username = "saurabhj";
  uid = 1000;
  hostname = "arch";
  architecture = "x86_64-linux";
  appsDir = "/home/saurabhj/.dotfiles/apps";
  remoteHosts = [
    "oci-melb-1"
    "do-admin-1"
    "la-admin-1"
  ];
  niks3ServerUrl = "http://oci-melb-1:5751";
  databaseHost = "oci-melb-1";
}
