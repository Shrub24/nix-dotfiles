#!/usr/bin/env bash
# Regenerate vendored package-lock.json from the npm tarball.
# Usage: ./update.sh [version]
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="${1:-0.9.21}"
TARBALL_URL="https://registry.npmjs.org/@agentmemory/agentmemory/-/agentmemory-${VERSION}.tgz"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> agentmemory v${VERSION} update"
echo ""

# 1. Compute source hash from the tarball
echo "[1] Computing source hash..."
HASH=$(nix hash convert --hash-algo sha256 "$(nix store prefetch-file --json "$TARBALL_URL" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['hash'])")" 2>/dev/null || true)
if [ -z "$HASH" ]; then
  # fallback: download + hash manually
  curl -sL "$TARBALL_URL" -o "$WORKDIR/package.tgz"
  HASH=$(nix hash file --sri --type sha256 "$WORKDIR/package.tgz")
else
  nix hash convert --hash-algo sha256 "$HASH" >/dev/null 2>&1 || true
  # download for lockfile generation
  curl -sL "$TARBALL_URL" -o "$WORKDIR/package.tgz"
fi
echo "  source hash (SRI): $HASH"

# 2. Unpack
echo "[2] Unpacking tarball..."
tar xzf "$WORKDIR/package.tgz" -C "$WORKDIR"
cd "$WORKDIR/package"

# 3. Generate package-lock.json
echo "[3] Generating package-lock.json..."
npm install --package-lock-only --ignore-scripts --legacy-peer-deps 2>&1 | tail -1

# 4. Copy lockfile into repo
echo "[4] Copying lockfile..."
cp package-lock.json "$DIR/package-lock.json"
wc -c <"$DIR/package-lock.json" | xargs printf '  -> %d bytes written\n'

# 5. Print update instructions
cat <<EOF

==> Summary for pkgs/agentmemory/default.nix
  version = "${VERSION}";
  hash = "${HASH}";
  npmDepsHash = "";  # run after lockfile is in place:

  nix run nixpkgs#nix-prefetch-npm-deps -- "$DIR/package-lock.json"

EOF
