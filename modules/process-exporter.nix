# Selection is enablement: the fleet aspect owns the exporter, its loopback
# bind and its scrape registration. The process groups are this workstation's
# policy — stable daemon names whose resource use matters when they misbehave.
# The fleet refuses an empty list, so the groups are required. Threads stay
# off: per-thread labels multiply series.
{ inputs, ... }:
{
  flake.modules.nixos.process-exporter =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.process-exporter ];

      services.prometheus.exporters.process = {
        extraFlags = [ "-threads=false" ];
        settings.process_names = [
          # Wrapped executables (tailscaled, noctalia, mcp-nixos) appear under
          # the 15-character truncation of the wrapper's name in /proc comm.
          {
            name = "nix-daemon";
            comm = [ "nix-daemon" ];
          }
          {
            name = "tailscaled";
            comm = [ ".tailscaled-wra" ];
          }
          {
            name = "sshd";
            comm = [ "sshd" ];
          }
          {
            name = "NetworkManager";
            comm = [ "NetworkManager" ];
          }
          {
            name = "bluetoothd";
            comm = [ "bluetoothd" ];
          }
          {
            name = "greetd";
            comm = [ "greetd" ];
          }
          # The telemetry path itself.
          {
            name = "vmagent";
            comm = [ "vmagent" ];
          }
          {
            name = "otelcol-contrib";
            comm = [ "otelcol-contrib" ];
          }
          {
            name = "beszel-agent";
            comm = [ "beszel-agent" ];
          }
          {
            name = "syncthing";
            comm = [ "syncthing" ];
          }
          # Desktop session.
          {
            name = "niri";
            comm = [ "niri" ];
          }
          {
            name = "pipewire";
            comm = [ "pipewire" ];
          }
          {
            name = "pipewire-pulse";
            comm = [ "pipewire-pulse" ];
          }
          {
            name = "wireplumber";
            comm = [ "wireplumber" ];
          }
          {
            name = "Xwayland";
            comm = [ "Xwayland" ];
          }
          {
            name = "noctalia";
            comm = [ ".noctalia-wrapp" ];
          }
          # Agent runtime.
          {
            name = "pi";
            comm = [ "pi" ];
          }
          {
            name = "herdr";
            comm = [ "herdr" ];
          }
          {
            name = "surge";
            comm = [ "surge" ];
          }
          {
            name = "mcp-nixos";
            comm = [ ".mcp-nixos-wrap" ];
          }
        ];
      };
    };
}
