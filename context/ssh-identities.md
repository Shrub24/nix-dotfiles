# SSH identities

## Restore client and builder identities through sops

**Id:** 80adf314-5819-4dc4-806d-fcf03a3a6d54
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** Legion adopts impermanence or changes its bootstrap-key provisioning

Legion's SSH client, remote-builder and server host private keys are enrolled in a
host-specific sops file and delivered by the layer that owns each consumer.
Enrollment is explicit and requires importing the existing keys before enabling it.
The import and bootstrap procedure is in
[the enrollment runbook](../docs/runbooks/enroll-legion-identities.md).

**Reason:** a preserved home makes the current migration work but cannot recreate
identities after a wipe. Restoring the server identity also preserves the public
host key clients and nix-fleet already trust. Encrypted identity delivery makes these
identities recoverable without the previous home or root filesystem, including a future
impermanent installation.

**Rejected alternative:** continue carrying unmanaged keys in the shared home and
root's SSH directory. That preserves this installation but leaves identity recovery
outside the configuration. The decryption identities still require external,
secured provisioning: encrypting a bootstrap key with itself cannot solve bootstrap.
