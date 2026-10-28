#!/usr/bin/env bash
# Harmony Hybrid Collaboration Starter - safer final setup script
# Usage: bash Setup-Harmony-Final.sh [target-repository]
#
# This script creates starter files only when the destination does not exist.
# It does NOT claim to implement a production SFU, TURN server, or live P2P mesh.

set -Eeuo pipefail

TARGET="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$SCRIPT_DIR/harmony-hybrid-cdn-edition"

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: target directory does not exist: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "ERROR: expected bundle folder not found beside this script:" >&2
  echo "  $BUNDLE_DIR" >&2
  echo "Download and extract harmony-hybrid-cdn-edition.zip beside this script," >&2
  echo "or use the ZIP directly." >&2
  exit 1
fi

echo "=== Harmony Starter Installer ==="
echo "Target: $TARGET"
echo "Policy: preserve existing files; only create missing files."
echo

created=0
skipped=0

while IFS= read -r -d '' source_file; do
  rel="${source_file#"$BUNDLE_DIR"/}"
  case "$rel" in
    install_harmony.sh) continue ;;
    *.zip) continue ;;
  esac

  destination="$TARGET/$rel"
  mkdir -p "$(dirname "$destination")"

  if [[ -e "$destination" ]]; then
    printf 'SKIP (exists): %s\n' "$rel"
    skipped=$((skipped + 1))
  else
    cp "$source_file" "$destination"
    printf 'CREATED: %s\n' "$rel"
    created=$((created + 1))
  fi
done < <(find "$BUNDLE_DIR" -type f -print0)

echo
echo "Created: $created"
echo "Skipped: $skipped"
echo
echo "Next steps:"
echo "  1. Review docs/implementation-status.md and docs/missing-work.md"
echo "  2. Configure local environment variables; do not commit secrets."
echo "  3. Run npm install && npm test && npm run build"
echo "  4. Review git diff before committing."
echo
echo "Important: the current bundle is a starter. It does not implement a production"
echo "WebRTC signaling service, TURN server, Cloudflare Calls SFU, or guaranteed cost tiers."
