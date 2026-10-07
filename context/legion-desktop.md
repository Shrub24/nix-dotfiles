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
symptom was a paired, reachable phone that the widget never listed. The fix has been
evaluated but not yet seen working, which is why the entry stays `needs-review`.

**Not the cause:** the `S23 Ultra` alias, which was a separate stale setting, and the
`kdeconnectd` warnings (pipewire, the host-portal app id, `CAP_NET_ADMIN`), which affect
only screen sharing and Bluetooth.

## The KDE portal backend stays out of the frontend's startup Settings query

**Id:** b0def88a-67c6-4a72-a48f-849f1865e359
**Type:** workaround
**Status:** needs-review
**Evidence:** inferred
**Revisit when:** a re-login shows no "Settings portal not found" timeout, or xdg-desktop-portal-kde stops calling the frontend while it starts

`modules/desktop/portals.nix` sets `org.freedesktop.impl.portal.Settings = [ "gtk" ]`
while the KDE backend remains the default for every other interface.

**Reason:** the boot journal showed `xdg-desktop-portal` starting at 74.5 s and the KDE
backend then logging "Settings portal not found ... Timeout was reached" at 99.7 s. The
frontend queries its Settings backends while it is still starting, and the KDE backend's
own startup calls back into the frontend, which is not yet on the bus, so each waits on
the other until D-Bus times out at 26 s. Qt apps that start alongside (vicinae,
kdeconnectd, easyeffects) hit the same timeout. With the KDE backend out of that query it
activates later, once the frontend is running. The mechanism is read from the journal
ordering, not reproduced, and the fix has not yet been confirmed by a re-login.

**Rejected alternatives:** dropping the KDE backend, which loses the Qt file dialog the
default chain gives Dolphin and the KDE apps; the removed Arch-era `override.conf` for
the unit, which set a bogus lowercase variable and was not the cause.
