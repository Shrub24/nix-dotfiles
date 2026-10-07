# Pi-Bolt entrypoints

## Launch behaviour belongs to the installed package

**Id:** eac14512-df45-40f3-a76c-7176dce7f391
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Verification:** corroborated — lead and child entrypoints execute a payload in their own store output; changing runtime extension paths leaves the compilation derivation unchanged
**Revisit when:** Radar changes its installation-identity model, or Pi-Bolt provides an upstream launch contract that replaces these entrypoints

The lead package owns `pi` and `pi-bolt`; the child package owns
`pi-bolt-child`. Discovery flags, child extension filtering and native-helper
PATH are required packaging, not Home Manager launcher wiring. The module
selects compiled plugins and supplies runtime extension paths.

**Reason:** the public command and running executable should identify one
installation. Radar compares their store roots. Compilation is separate from
installation, so changing launch data does not repeat the AOT build.

**Rejected alternatives:** separate module-side launcher derivations split
command ownership from the package. Linking a shared executable from another
output preserves that split in the running executable's store identity.

**Consequence:** each install output copies its compiled payload and assets.
Launcher changes reuse compilation but create another install output. Direct
`process.execPath` launches still bypass the shell entrypoint; this change does
not alter the historian's launch contract.
