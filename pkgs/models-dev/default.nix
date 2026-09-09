{
  fetchurl,
}:
# Single-file fetch, so $out is the JSON itself.
# Refresh the pin with `just models-dev`.
fetchurl {
  name = "models.dev-models.json";
  url = "https://models.dev/models.json";
  hash = "sha256-bTT+byDx4X9V3w2ZcNbtV6vfGM9Wsp4caHJemIZ9hTU=";
}
