# Canonical OCI image references with version tag and immutable manifest digest.
# Update with skopeo inspect + Renovate regex manager.
{
  grist = "docker.io/gristlabs/grist:1.7.17@sha256:0d9bba2c7139e3e9e15839d03544746f7815bbe76e34dc71c9f6eadd0be82a8c";
  litellm-database = "ghcr.io/berriai/litellm-database:v1.92.0@sha256:64d3547e0b131bf4638342e52c12bc46d6f1d9b8498e4b731ff31be5ab316ea9";
  headroom-code = "ghcr.io/headroomlabs-ai/headroom:0.34.0-code@sha256:5253cc98bf85ae4f04992db728498d2b78a379d03edcec1b780af9430c323e76";
}
