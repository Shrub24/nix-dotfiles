# Timezone

## Automatic timezone is the baseline for every host

**Id:** fea46999-9ee9-4a18-9422-ec5948b9caf1
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** a host becomes fixed in place, or geoclue regains an IP location source

`services.automatic-timezoned` is enabled in the shared foundation aspect and no host
declares `time.timeZone`. Locale sits there too.

**Reason:** both hosts are laptops that move, and host files stay thin. Its only usable
location source is a Wi-Fi scan, because geoclue's IP source is disabled upstream and
the nixpkgs module cannot enable it, so on ethernet alone the zone stays at the last
fix. That is also why a missing wlan interface looked like a timezone bug.

**Rejected alternative:** a host-specific `time.timeZone` literal. It was briefly
written for legion and removed, since a fixed zone is wrong for a machine that travels.
