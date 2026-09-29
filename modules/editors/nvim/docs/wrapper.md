# Wrapper layout

Moved from `modules/editors/nvim/_wrapper.nix` so the code stays lean. Comments in code are signposts only.

```
Binaries on the wrapped editor's PATH. Spec-level `runtimePkgs` needs a
specMods declaration; the module-level option is enough until per-language
splits are wanted.

Everything the editor enables as an LSP server belongs here, not only in
modules/editors/lsp.nix: that one lands in the home profile, and the wrapper
APPENDS its runtimePkgs to PATH rather than replacing it. Launched with a
bare PATH (a GUI entry, a systemd unit, `env -i`) those binaries are absent
and every server silently fails to start. Verified: with PATH=/usr/bin:/bin
gopls, marksman, texlab, yaml-language-server and vtsls all reported
executable = 0 before this list was completed.
```
