# Context index

## 0

## 1

## 2

## 3

## 4

## 5

## 6

## 7

## 8

## 9

## A

- [agent-env-templates.md](agent-env-templates.md) — why the shared env template is rendered once per shell dialect instead of replayed through bash
- [arch-retirement.md](arch-retirement.md) — why NixOS is the only host class, what Arch-looking remnants were kept on purpose, and the session-variable and nvim-name choices
- [agent-discipline.md](agent-discipline.md) — why each agent discipline has one owning skill

## B

## C

## D

- [desktop-shell.md](desktop-shell.md) — why Monique owns monitor state, Niri is store-linked, and Noctalia themes come from local template rows
- [documentation.md](documentation.md) — why the rationale lives in `context/` rather than ARCHITECTURE.md

## E

## F

## G

## H

- [herdr.md](herdr.md) — why delegation is herdsman, and why Herdr's `config.toml` is a declared real file
- [host-package-licensing.md](host-package-licensing.md) — why Legion permits Zotero's exact pinned Firefox ESR despite Nixpkgs marking it insecure

## I

## J

## K

## L

- [legion-desktop.md](legion-desktop.md) — why the phone widget needs gdbus on the shell's PATH, and why the KDE portal backend is kept out of the frontend's startup Settings query
- [legion-hardware.md](legion-hardware.md) — why iwlwifi stays out of the initrd, and which graphics modules facter loads early

## M

## N

- [noctalia-greeter-sync.md](noctalia-greeter-sync.md) — how greeter sync becomes passwordless, and why the wrapper and sudoers routes lost

## O

## P

- [package-updates.md](package-updates.md) — why each pin set has one registered owner, why update scripts edit tracked package files in place, and why a source URL has to carry the version attribute
- [pi-agent-definitions.md](pi-agent-definitions.md) — why agent definitions sit under the Pi agent directory, and which skills each role preloads
- [pi-bolt-build.md](pi-bolt-build.md) — why Pi-Bolt's own flake builds the payload and what this repository still owns
- [pi-bolt-compiled-plugins.md](pi-bolt-compiled-plugins.md) — how a compiled Pi-Bolt extension binds Pi's own modules, why the build owns that binding, and what the package asserts about the compiled set
- [pi-bolt-entrypoints.md](pi-bolt-entrypoints.md) — why launch behaviour belongs to the package, and why the entrypoints sit beside the payload's own launcher
- [pi-bolt-release-pins.md](pi-bolt-release-pins.md) — why a Pi-Bolt tag's runtime is a separate release asset keyed to the engine stamp, and how the flake that owns the pin verifies it
- [pi-config-ownership.md](pi-config-ownership.md) — why a file Pi or an extension rewrites is never a store link, and why herdsman's config is rendered
- [pi-dashboard.md](pi-dashboard.md) — why the dashboard runs as a service, attaches locally, and is exposed only on Legion's tailnet interface
- [pi-herdsman.md](pi-herdsman.md) — the incident where herdsman re-read session transcripts on a refresh pass, and what the fix leaves behind
- [pi-otel.md](pi-otel.md) — why Pi uses the run-trace fork with a lock-derived runtime closure and leaves backend fanout and credentials at the fleet gateway
- [pi-plugin-dependencies.md](pi-plugin-dependencies.md) — why a plugin's npm dependencies are pinned by its consumer, so the producer's pin cannot be enforced
- [pi-plugin-sources.md](pi-plugin-sources.md) — why every Pi extension source is a pin rather than a live checkout, and what that costs

## Q

- [qmd.md](qmd.md) — why the CLI and the user service share one Nix build, and where its trust and spec collection live

## R

## S

- [SSH identities](ssh-identities.md) — restore Legion client and builder keys without a surviving home; external age bootstrap.

## T

- [telemetry-metrics.md](telemetry-metrics.md) — why the fleet metrics lane is adopted now while journals wait, and why forwarder health cannot see a total transport outage
- [timezone.md](timezone.md) — why automatic timezone is baseline for every host, and its Wi-Fi dependence
- [trust.md](trust.md) — why build trust and SSH reach are separate selections

## U

## V

## W

## X

## Y

## Z
