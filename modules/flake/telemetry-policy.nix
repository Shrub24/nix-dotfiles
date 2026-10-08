# Evaluation-time policy for the metrics adoption
# (`adopt-fleet-observability`): what both workstation compositions must hold
# once `telemetry` and `node-exporter` are selected. Failing assertions throw
# while the check attribute is evaluated, so the failures surface under the
# canonical `nix flake check --no-build --no-write-lock-file` path, not in a
# derivation the build step would have to run.
{
  config,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  hosts = {
    legion = config.flake.nixosConfigurations.legion;
    spectre = config.flake.nixosConfigurations.spectre;
  };

  expectedDestination = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "victoriametrics";
    endpoint = "remote-write";
    via = "tailnet";
  };

  # One host's verdict: the empty list is the policy. Each entry is a named
  # gap, so a failure reads as what is missing rather than as a bare false.
  checkHost =
    hostName: osConfig:
    let
      cfg = osConfig.config;
      telemetry = cfg.services.telemetry;
      scrapeFor = job: telemetry.scrape.${job} or null;
      nodeScrape = scrapeFor "node";
      healthScrape = scrapeFor "vmagent-health";
      # `unitConfig.OnFailure` is the rendered unit-file value (a string), not the
      # option-level list, and the notify aspect attaches its handler there.
      onFailure =
        unit:
        let
          raw = lib.attrByPath [ "systemd" "services" unit "unitConfig" "OnFailure" ] null cfg;
        in
        if raw == null then
          [ ]
        else if builtins.isList raw then
          raw
        else
          [ raw ];
      hookRenders = unit: builtins.any (hook: lib.hasInfix "notify-event@${unit}." hook) (onFailure unit);
      # A unit registered for notification only renders hooks if the notify
      # aspect is selected on the same host; registrations alone are inert.
      hookFindings = map (
        unit:
        lib.optionalString (
          !hookRenders unit
        ) "${hostName}: ${unit} has no effective notify hook (registrations without notify)"
      ) (builtins.attrNames cfg.services.notify.events);
    in
    lib.optional (
      !(telemetry.destinations ? fleet-metrics)
      || telemetry.destinations.fleet-metrics.protocol != "prometheus-remote-write"
      || telemetry.destinations.fleet-metrics.signals != [ "metrics" ]
      || telemetry.destinations.fleet-metrics.endpoint != expectedDestination
    ) "${hostName}: destination fleet-metrics is not the canonical metrics-only remote-write endpoint"
    ++ lib.optional (
      telemetry.pipelines.metrics != [ "fleet-metrics" ]
    ) "${hostName}: pipelines.metrics is not pinned to [ \"fleet-metrics\" ]"
    ++ lib.optional (
      telemetry.otlp.signals != [ ] || telemetry.otlp.ingress != null
    ) "${hostName}: OTLP admission or gateway ingress is configured; this change is metrics-only"
    ++ lib.optional telemetry.journald.enable "${hostName}: journald shipping is enabled; journals are the separate gated change"
    ++ lib.optional (cfg.services.vector.enable or false
    ) "${hostName}: Vector is enabled; journals are the separate gated change"
    ++ lib.optional (
      !(nodeScrape != null && nodeScrape.target == "127.0.0.1")
    ) "${hostName}: node scrape is not a loopback source"
    ++ lib.optional (
      !(
        nodeScrape != null
        && nodeScrape.labels.instance == "${cfg.networking.hostName}:${toString nodeScrape.port}"
      )
    ) "${hostName}: node scrape instance label is not <hostName>:port"
    ++
      lib.optional
        (
          !(
            healthScrape != null
            && healthScrape.target == "127.0.0.1"
            && healthScrape.labels.instance == "${cfg.networking.hostName}:${toString healthScrape.port}"
          )
        )
        "${hostName}: vmagent-health scrape is not a loopback source with an explicit <hostName>:port instance label"
    ++ lib.optional (
      nodeScrape != null
      && healthScrape != null
      && nodeScrape.labels.instance == healthScrape.labels.instance
    ) "${hostName}: node and vmagent-health instance labels are not distinct"
    ++ lib.optional (
      !cfg.services.vmagent.enable
    ) "${hostName}: vmagent is not enabled for the declared scrape work"
    ++ lib.optional (
      !(builtins.any (arg: arg == "-httpListenAddr=127.0.0.1:8429") (
        cfg.services.vmagent.extraArgs or [ ]
      ))
    ) "${hostName}: vmagent health listener is not the loopback 127.0.0.1:8429 bind"
    ++ builtins.filter (finding: finding != "") hookFindings;

  hostFindings = lib.concatMap (hostName: checkHost hostName hosts.${hostName}) (
    builtins.attrNames hosts
  );

  # Negative case: a composition that registers failure events without
  # selecting notify must produce hook findings, not a pass. If the probe
  # stops detecting the gap, the policy check fails on the empty verdict
  # instead of silently accepting inert registrations.
  negativeProbe = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.nix-fleet.modules.nixos.telemetry
      inputs.nix-fleet.modules.nixos.node-exporter
      {
        nixpkgs.hostPlatform = system;
        networking.hostName = "telemetry-probe";
        system.stateVersion = "26.11";
        services.telemetry.destinations.probe = {
          protocol = "prometheus-remote-write";
          endpoint = "http://127.0.0.1:9999/api/v1/write";
          signals = [ "metrics" ];
        };
      }
    ];
  };
  negativeFindings = checkHost "telemetry-probe" negativeProbe;
  negativeOk = builtins.any (
    finding: lib.hasInfix "registrations without notify" finding
  ) negativeFindings;

  failures =
    hostFindings
    ++ lib.optional (
      !negativeOk
    ) "policy self-test: probe composition with registrations but no notify evaluated clean";
in
{
  flake.checks.${system}.telemetry-policy =
    if failures != [ ] then
      throw "telemetry-policy: ${lib.concatStringsSep "; " failures}"
    else
      inputs.nixpkgs.legacyPackages.${system}.runCommand "telemetry-policy" { } ''
        touch $out
      '';
}
