#!/usr/bin/env bash
# Verify the preserved source content against content/manifests/source_inventory.json.
#
# Exits non-zero on any missing file or digest mismatch. A mismatch means the
# archival source has been altered — do not proceed to compile a bundle from it.
#
# Satisfies requirements 1.3 and 1.4. Called by CI and by the documented
# fresh-checkout setup steps.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/content/manifests/source_inventory.json"
SOURCE_DIR="$REPO_ROOT/content/source"

if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: manifest not found at $MANIFEST" >&2
  exit 1
fi

# Prefer jq; fall back to python3 so a bare checkout still verifies.
read_manifest() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '.routines[] | .routineId as $r | .files[] | "\(.sha256)  \($r)/\(.preservedPath)"' "$MANIFEST"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$MANIFEST" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    doc = json.load(fh)
for routine in doc["routines"]:
    for entry in routine["files"]:
        print(f'{entry["sha256"]}  {routine["routineId"]}/{entry["preservedPath"]}')
PY
  else
    echo "FAIL: need jq or python3 to read the manifest" >&2
    exit 1
  fi
}

expected="$(read_manifest)"
if [[ -z "$expected" ]]; then
  echo "FAIL: manifest yielded no entries" >&2
  exit 1
fi

missing=0
while read -r _digest path; do
  if [[ ! -f "$SOURCE_DIR/$path" ]]; then
    echo "MISSING: content/source/$path" >&2
    missing=1
  fi
done <<< "$expected"

if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "FAIL: source content is incomplete. Run scripts/fetch_content.sh first." >&2
  exit 1
fi

echo "Verifying $(wc -l <<< "$expected") files against $MANIFEST"
if ! (cd "$SOURCE_DIR" && sha256sum -c --quiet <<< "$expected"); then
  echo >&2
  echo "FAIL: digest mismatch. The archival source must not be modified." >&2
  echo "      Restore the original bytes; do not regenerate or 'fix' source JSON." >&2
  exit 1
fi

echo "OK: all preserved source files match their recorded digests."
