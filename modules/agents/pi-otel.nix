{
  flake.modules.homeManager.pi-otel =
    { osConfig, ... }:
    {
      programs.pi-coding-agent.settings.otel = {
        endpoint = osConfig.services.telemetry.otlp.httpUrl;
        protocol = "http/protobuf";
        traces = true;
        metrics = false;
        logs = false;
        captureContent = "full";
        selfLogs = false;
      };
    };
}
