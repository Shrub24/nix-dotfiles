_: {
  flake.modules.homeManager.modal =
    { config, ... }:
    {
      # Modal owns its auth secret (own ciphertext file); the SDK/CLI reads
      # token_id/token_secret from the active profile in ~/.modal.toml.
      sops = {
        secrets = {
          MODAL_TOKEN_ID = {
            sopsFile = ../../secrets/modal.yaml;
            format = "yaml";
            key = "token_id";
          };
          MODAL_TOKEN_SECRET = {
            sopsFile = ../../secrets/modal.yaml;
            format = "yaml";
            key = "token_secret";
          };
        };

        templates."modal.toml" = {
          path = "${config.home.homeDirectory}/.modal.toml";
          content = ''
            [default]
            token_id = "${config.sops.placeholder.MODAL_TOKEN_ID}"
            token_secret = "${config.sops.placeholder.MODAL_TOKEN_SECRET}"
          '';
        };
      };
    };
}
