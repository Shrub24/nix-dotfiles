# GlobalProtect

## The gateway is SAML-only, so the NetworkManager profile is gone

**Id:** f4f8a670-ae56-428e-a982-96a2e983de3e
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `openconnect --protocol=gp --non-inter vpn.unimelb.edu.au`, 2026-11-10; `nmcli
connection show "UoM GlobalProtect"` reporting `connection.timestamp: 0`
**Revisit when:** the gateway accepts user/password authentication again, or
globalprotect-openconnect gains a NetworkManager backend

The `globalprotect` NixOS aspect and its profile are removed. `gpclient` —
nixpkgs' globalprotect-openconnect, already in the shared CLI aspect — is the only
GlobalProtect client here.

**Reason:** the gateway answers the prelogin with a `SAML REDIRECT` to
`sso.unimelb.edu.au` and returns no password form. NetworkManager's openconnect plugin
drives a fixed username/password dialog and has no external-browser handoff, so the
profile could never complete: `connection.timestamp` was still `0`, meaning it had
never activated once. A declared profile that cannot authenticate is not an unused
convenience, it is a configuration claiming a connection it cannot make.

**Rejected alternative:** keep the profile for gateways that do offer password auth. It
carries no credentials either way, and the one gateway it names is SAML-only, so it
would have stayed dead until someone re-derived the same finding.

**Rejected alternative:** `openconnect --protocol=gp --external-browser=<cmd>`, which does
complete this flow by hand. It is a manual paste-the-URL loop with no state to declare,
which `gpclient` already wraps.
