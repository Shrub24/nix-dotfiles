{ config, inputs, ... }:
let
  # Service topology read at the flake-parts level, closed over by the NixOS
  # module.
  ntfyUrl = config.topology.services.ntfy.host;
in
{
  flake.modules.nixos.notify =
    { config, ... }:
    {
      # nix-fleet owns the mechanism: the daemon, the `notify` CLI, the
      # `unit-notify` systemd event handler and the
      # `services.notify.events.<unit>.{failure,success}` contract. This aspect
      # binds the fleet's dispatch policy and registers the units whose failure
      # means the machine is broken or unreachable.
      imports = [ inputs.nix-fleet.modules.nixos.notify ];

      services.notify = {
        ntfy = {
          enable = true;
          serverUrl = ntfyUrl;
        };

        # ntfy-only dispatch. Telegram is off, not merely unconfigured: the
        # shared aspect asserts its chat id and topics whenever it is enabled,
        # and dispatch policy is consumer-local.
        telegram.enable = false;

        # System-scoped ntfy token. Placeholder until filled with
        # `sops secrets/notify.yaml`; dispatch is best-effort, so an unauthorised
        # token degrades delivery without affecting the observed unit.
        secretFiles.hostSystem = ../secrets/notify.yaml;

        # Registration follows ownership: the fleet's aspects register the
        # units they own — nix-baseline owns nix-daemon, ssh owns sshd,
        # tailscale owns tailscaled, beszel-agent and nix-gc their own. What is
        # left here is this composition's policy: the units nothing else owns,
        # and the severity this host wants on units owned elsewhere.
        events = {
          sshd.failure.severity = "critical";
          greetd.failure.severity = "critical";
          firewall.failure.severity = "critical";
          "podman-prune".failure = { };
        };
      };

      # The daemon dispatches over /run/notify/notify.sock; root units need no
      # membership, so this grant exists for the owner's own `notify` calls.
      users.users.${config.currentHost.primaryUser.name}.extraGroups = [ "notify" ];
    };
}
