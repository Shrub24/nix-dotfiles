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
**Status:** superseded
**Superseded by:** a7bc0c00-1557-4205-9ff1-50ca6f0a3399
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

## The file chooser is a terminal backend

**Id:** a7bc0c00-1557-4205-9ff1-50ca6f0a3399
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `xdg-desktop-portal` journal, 2026-10-25 and 2026-10-26; portal and KIO state
read from the running session, 2026-10-28
**Revisit when:** the terminal chooser cannot express a save dialog, yazi leaves the
nixpkgs pin, or the portal frontend gains a chooser that keeps its own history
**See:** legion-desktop.md#the-kde-portal-backend-stays-out-of-the-frontends-startup-set — b0def88a-67c6-4a72-a48f-849f1865e359 — as of 2026-10-28

`org.freedesktop.impl.portal.FileChooser` resolves to `xdg-desktop-portal-termfilechooser`,
which runs yazi in kitty and reads the selection back from the file its wrapper writes. The
KDE backend is gone from both package lists.

**Reason:** the KDE dialog was never reachable. The frontend builds a proxy for every
interface at its own startup, so naming `kde` for FileChooser started that backend while
the frontend was still starting, the backend queried the frontend back, and D-Bus gave up
after 25 s (`Failed to create file chooser proxy: … Timeout was reached`, 2026-10-25 and
again at the 2026-10-26 startup of the frontend that served the next two and a half days).
That is the same cycle b0def88a blames on the `default` chain — the per-interface mapping
alone was enough to trigger it, which is why the workaround never held. Restarting the
frontend with the backend already up produced the dialog, and it was not worth keeping: no
Qt style plugin is installed (`kdeglobals` names `widgetStyle=kvantum`, a package this
machine does not have) and KIO has no reader for GTK's `recently-used.xbel`, so its Recent
stayed empty beside 377 GTK entries. Neither backend remembered the last folder. yazi
brings multi-select through `--chooser-file` and frecency through zoxide, and the backend
supplies the last-folder memory nothing else in the chain has
(`$XDG_STATE_HOME/xdg-desktop-portal-termfilechooser/last_dir`). The trade: the picker is a
terminal window, and a save makes the filename part of the yazi session rather than a text
field.

The package comes from nixpkgs: the 1.5.0 release it once needed ahead of the pin — the one
that registers `niri` in the portal file and closes a command injection in the wrapper
scripts — is what nix-fleet's pin now carries.

**Rejected alternatives:** keep the KDE backend and order its unit before the frontend —
the two wait on each other whatever the order, since the backend's startup needs a frontend
that is already answering; use `xdg-desktop-portal-gtk` — no extra backend and a sidebar
that takes Projects, but no recent folders and no last-folder memory; run
`kactivitymanagerd` so KDE recents populate — a resident daemon for documents only KDE
applications register, while the GTK list stays invisible to KIO; use
`xdg-desktop-portal-termfilepickers` — younger, unpackaged, and it fixes the chooser to its
own yazi wrappers.

## Screen sharing goes through the umbriel portal

**Id:** 5edc5a10-1c69-4dcc-afb0-56d85ce55d0a
**Type:** decision
**Status:** active
**Evidence:** inferred
**Source:** portal and PipeWire journals and the Chromium and Vesktop client logs, 2026-11-04 and 2026-11-09; live picker and window state on 2026-11-09
**Revisit when:** a share fails under umbriel with a format or negotiation error, or the wlr backend gains a picker
**See:** legion-desktop.md#the-file-chooser-is-a-terminal-backend — a7bc0c00-1557-4205-9ff1-50ca6f0a3399 — as of 2026-11-09

`org.freedesktop.impl.portal.ScreenCast` and `Screenshot` resolve to the umbriel
portal. `xdg-desktop-portal-wlr` is out of both package lists and out of the generic
ScreenCast chain, which falls back to gnome then gtk. The `xdg-desktop-portal-wlr`
config block is gone with it — nothing selected that backend any more.

**Reason:** the umbriel picker is the only one in the chain. It offers screen and
window tabs, thumbnails and cursor modes, while xdpw in its picker-less mode shares
exactly one named output and needs a hand-written config to say which. The detour
through xdpw existed only to work around a failure that was never the portal's.

That failure was misdiagnosed. On 2026-11-04 Chromium inside Vesktop reached the
picker, selected a source, and died with `PipeWire stream state error: no more input
formats`; the cause was read as the portal's format offers being too narrow for the
consumer. The portal's stderr held nothing to support that, and the same Vesktop
build could not paint its own window at all — its renderer was throwing Vencord
patch errors (`Cannot read properties of undefined (reading 'get')`). Repairing
Vencord made screen sharing work under the unchanged umbriel backend, on 2026-11-09.
So the confirmed half is the outcome: shares work under umbriel, and they failed
under it while the client's renderer was broken. That the broken renderer caused
the format rejection is inferred from that sequence, not traced through the
capturer.

The portal package is pinned to the `Shrub24` fork branch `fix/picker-parent-window`,
which forwards `parent_window` from `Start` into the picker and has the picker import it.

Measured on 2026-11-09: given a real handle, the picker parents. Launched with
`parent_window: "wayland:<handle>"` from a GTK3 window that exported itself, the picker
reports that window's id as its `parent` and floats. Asked by Chromium through the portal,
the request the picker receives carries no `parent_window` key at all, so it floats
unparented — the client sends none back. Chromium's ScreenCast client omits it, and
libportal 0.9.1's screencast session API takes no parent argument, so the fork helps only
clients that export a window themselves.

**Rejected alternatives:** keep xdpw as the ScreenCast backend — it works, but with
no picker it cannot offer a window, a source choice or cursor modes, and it needs
per-output configuration that names one display; keep it in the package list as a
fallback — with the mapping moved nothing selects it, so it is an installed backend
that can never run; leave the xdpw config file in place for the same reason — the
file outlives the reason it existed.
