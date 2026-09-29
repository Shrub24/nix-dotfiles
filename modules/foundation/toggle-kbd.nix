_: {
  # Disables the built-in keyboard and trackpad (e.g. with an external board
  # resting on the deck) and restores them. The privileged half is a store
  # helper with the interface baked in; sudo lets the user run exactly its
  # `lock` and `unlock` verbs without a password — nothing else under usbhid.
  flake.modules.nixos.toggle-kbd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.toggle-kbd;
      usbhid = "/sys/bus/usb/drivers/usbhid";

      helper = pkgs.writeShellApplication {
        name = "toggle-kbd-helper";
        runtimeInputs = [ pkgs.kmod ];
        text = ''
          case "''${1-}" in
            lock)
              echo ${cfg.usbInterface} > ${usbhid}/unbind
              modprobe -r i2c_hid_acpi
              ;;
            unlock)
              modprobe i2c_hid_acpi
              echo ${cfg.usbInterface} > ${usbhid}/bind
              ;;
            *)
              echo "usage: toggle-kbd-helper lock|unlock" >&2
              exit 2
              ;;
          esac
        '';
      };

      toggle = pkgs.writeShellApplication {
        name = "toggle-kbd";
        runtimeInputs = [ pkgs.libnotify ];
        text = ''
          if [ -e ${usbhid}/${cfg.usbInterface} ]; then
            /run/wrappers/bin/sudo ${lib.getExe helper} lock
            notify-send -u critical "DECK LOCKED" "Keyboard & Trackpad disabled."
          else
            /run/wrappers/bin/sudo ${lib.getExe helper} unlock
            notify-send "DECK ACTIVE" "Controls restored."
          fi
        '';
      };
    in
    {
      options.programs.toggle-kbd.usbInterface = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "[0-9]+-[0-9.]+:[0-9]+\\.[0-9]+");
        default = null;
        example = "3-9:1.0";
        description = "usbhid interface of the built-in keyboard, as named under ${usbhid}.";
      };

      config = lib.mkIf (cfg.usbInterface != null) {
        environment.systemPackages = [ toggle ];

        security.sudo.extraRules = [
          {
            users = [ config.currentHost.primaryUser.name ];
            commands =
              map
                (verb: {
                  command = "${lib.getExe helper} ${verb}";
                  options = [ "NOPASSWD" ];
                })
                [
                  "lock"
                  "unlock"
                ];
          }
        ];
      };
    };
}
