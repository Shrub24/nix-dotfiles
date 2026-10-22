{
  hermes-agent,
  installShellFiles,
}:
hermes-agent.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ installShellFiles ];

  # Upstream installs no completions and the CLI generates them itself, so they
  # are added here rather than by a shell aspect that would have to reach into
  # this package's flake input.
  postInstall = (old.postInstall or "") + ''
    installShellCompletion --cmd hermes \
      --bash <($out/bin/hermes completion bash) \
      --fish <($out/bin/hermes completion fish) \
      --zsh <($out/bin/hermes completion zsh)
  '';
})
