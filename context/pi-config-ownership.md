# Pi configuration ownership

## A file an application rewrites is never Nix-owned

**Id:** aa075c09-b99d-4121-95b4-c3fad7d89db2
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

The Pi configuration surface is rendered by the `programs.pi-coding-agent` Home Manager module, but the test is the write path, not whether the file holds settings. Pi's `settings.json` and `mcp.json` are declared with `force = true`. Pi's own settings manager writes in place and fails loudly on a store link, while an extension that saves through a temporary file plus `rename()` (the dashboard's bridge registrar did) replaces the link with a real file. Without `force`, Home Manager backs the drift up, and a second occurrence collides with the backup it left before.

The extension settings files `pi-tool.json` and `pi-stamp.json` stay undeclared, because nothing about them is ours to reassert. GTK's `gtk.gtk3.bookmarks` follows the same rule: GTK saves a bookmark edited in a chooser through a rename, but the file holds only the directories `xdg.userDirs` declares. That is policy rather than app-owned settings, so the next switch moves the edit aside as a backup.

**Alternatives:** unknown.
**Reason:** the write path decides ownership; a store link under a rename-based writer silently becomes a regular file.

## Herdsman's config is rendered by Nix, and nothing writes it

**Id:** bb7dcc14-cf23-4c3a-bdb2-da78a7b48b51
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

`pi-herdsman/config.json` is a store-rendered file. Herdsman's `/agents` settings menus were retired, so no runtime path rewrites the file and a store link is safe. Keys set in the Nix module are the only settings; a key left out takes the extension's default. A model scope only restricts, so each list names the models that definition actually pins.

**Alternatives:** unknown.
**Reason:** with the UI menus retired, nothing at runtime needs to write the file.
