#!/usr/bin/env bash
set -Eeuo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"
while IFS= read -r -d '' file; do
  rel="${file#"$SOURCE_DIR"/}"
  case "$rel" in
    install_harmony.sh) continue ;;
    *.zip) continue ;;
  esac
  mkdir -p "$(dirname "$rel")"
  if [[ -e "$rel" ]]; then
    echo "SKIP (exists): $rel"
  else
    cp "$file" "$rel"
    echo "CREATED: $rel"
  fi
done < <(find "$SOURCE_DIR" -type f -print0)
echo "Harmony files copied. Review docs/implementation-status.md and docs/missing-work.md."
