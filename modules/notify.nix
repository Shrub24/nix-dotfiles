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

        # ntfy-only dispatch. The shared aspect asserts Telegram policy
        # unconditionally, so the group is bound; the empty token file is what
        # actually disables the Telegram path — dispatch skips a falsy
        # token_file silently, where a missing file would log an unreadable
        # token on every event. Removing that line and adding the token secret
        # turns Telegram on.
        telegram = {
          chatId = "-1003913476155";
          topics = {
            critical = "2";
            warning = "3";
            info = "4";
            music = "5";
            system = "6";
          };
          tokenFile = "";
        };

        # System-scoped ntfy token. Placeholder until filled with
        # `sops secrets/notify.yaml`; dispatch is best-effort, so an unauthorised
        # token degrades delivery without affecting the observed unit.
        secretFiles.hostSystem = ../secrets/notify.yaml;

        # Registrations this aspect owns are the units present on every host
        # that selects it. Host-specific units register from the host module.
        # nix-daemon and tailscaled are absent deliberately: both units ship in
        # systemd.packages (pkgs.nix, pkgs.tailscale), so their option-level
        # serviceConfig carries no ExecStart and the shared aspect's fail-closed
        # validation rejects the registration. Covering them needs an upstream
        # relaxation for package-provided units.
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
