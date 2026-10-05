{ config, inputs, ... }:
let
  # Resolved at the flake-parts level from the fleet's service inventory.
  ntfyUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "ntfy";
    endpoint = "api";
    via = "tailnet";
  };
in
{
  flake.modules.nixos.notify =
    { config, ... }:
    {
      # nix-fleet owns the mechanism and the `services.notify.events.<unit>`
      # contract; this binds the dispatch policy and the units this host cares about.
      imports = [ inputs.nix-fleet.modules.nixos.notify ];

      services.notify = {
        ntfy = {
          enable = true;
          serverUrl = ntfyUrl;

          # Routing is declared by use case, never derived from severity, and fails
          # closed at eval without both halves. `system` is the one such use case here.
          topics.system = "system";
          defaultTopic = "system";
        };

        # ntfy-only dispatch: the shared aspect requires a chat id and topics
        # whenever telegram is enabled, and dispatch policy is consumer-local.
        telegram.enable = false;

        secretFiles.hostSystem = ../secrets/notify.yaml;

        # Only units nothing else owns; the fleet's aspects register their own.
        events = {
          sshd.failure.severity = "critical";
          greetd.failure.severity = "critical";
          firewall.failure.severity = "critical";
          "podman-prune".failure = { };
        };
      };

      # Root units need no membership; the grant is for the owner's own calls.
      users.users.${config.currentHost.primaryUser.name}.extraGroups = [ "notify" ];
    };
}
