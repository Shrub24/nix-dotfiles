# Legion desktop session

## The phone widget needs `gdbus` on the shell's PATH

**Id:** fd45e7c3-dd23-4ca8-8988-b13936a2cd73
**Type:** constraint
**Status:** needs-review
**Evidence:** inferred
**Revisit when:** the phone-connect widget is seen listing the paired phone after a switch, or the plugin stops shelling out to `gdbus`

The Noctalia plugin `icefish/phone-connect` reads every KDE Connect device property by
running `gdbus`, and it probes `kdeconnectd`, `kdeconnect-cli` and `gdbus` by name on the
daemon's PATH. `pkgs.glib.bin` is in the Noctalia aspect's `home.packages` for that reason.

**Reason:** nixpkgs keeps `gdbus` in glib's `bin` output, which nothing else here puts in
the profile, so the running shell (checked on its own `/proc/<pid>/environ` PATH) could
not resolve it. On Arch it was `/usr/bin/gdbus`, which is why the widget worked there. The
symptom was a paired, reachable phone that the widget never listed. The shell's PATH
resolves it again as of the 2026-10-09 boot (`/proc/2391/environ`); the widget itself is
still unseen, which is why the entry stays `needs-review`.

**Not the cause:** the `S23 Ultra` alias, which was a separate stale setting, and the
`kdeconnectd` warnings (pipewire, the host-portal app id, `CAP_NET_ADMIN`), which affect
only screen sharing and Bluetooth.

## The KDE portal backend stays out of the frontend's startup set

**Id:** b0def88a-67c6-4a72-a48f-849f1865e359
**Type:** workaround
**Status:** needs-review
**Evidence:** inferred
**Revisit when:** a re-login after the switch shows the frontend reaching active without the 26 s gap, or the KDE backend starts from somewhere else at session start

`modules/desktop/portals.nix` keeps the KDE backend out of the default chain —
`default = [ "gtk" ]` with `org.freedesktop.impl.portal.FileChooser = [ "kde" ]` — so the
frontend never starts it during its own startup.

**Reason:** the frontend starts the backends its config names and then waits for them to
register, while the KDE backend's own startup calls back into the frontend's
`org.freedesktop.portal.Desktop`, which is not yet answering, so each waits on the other
until D-Bus times out. The 2026-10-09 boot timed it: `xdg-desktop-portal.service` started
20:43:43 and became active 20:44:09, `plasma-xdg-desktop-portal-kde.service` Starting
20:43:44 and Started 20:44:09, its first log line the expired Settings query. Clients
starting alongside (vicinae, kdeconnectd, easyeffects) hit the same timeout, and the
stalled window also produces the duplicate app-id and missing-access-impl lines. KDE stays
reachable for file dialogs, where it is activated on demand long after the frontend is up.
The mechanism is read from the unit timestamps and log ordering, not reproduced, and the
fix has not yet been confirmed by a re-login.

**Superseded:** the earlier `org.freedesktop.impl.portal.Settings = [ "gtk" ]` mapping,
recorded here as the fix, does not break the cycle — the KDE backend queries Settings on
its own startup whatever backend serves that interface. The mapping stays, because GTK is
the right Settings backend on this desktop.

**Rejected alternatives:** dropping the KDE backend outright, which loses the Qt file
dialog that the default chain gives the KDE apps; the removed Arch-era `override.conf` for
the unit, which set a bogus lowercase variable and was not the cause.
