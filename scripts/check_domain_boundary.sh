#!/usr/bin/env bash
# Fail the build if packages/dance_domain imports Flutter, FFI or Serverpod,
# or declares them as a dependency. There is no analyzer lint for an ABSENT
# import, so this greps directly. Task 0.3 / design.md "Dependency
# boundaries": dance_domain must stay callable from both the client and the
# server tiers, which is only true if it depends on neither.
#
# Run from anywhere; paths are resolved relative to the repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMAIN_DIR="$REPO_ROOT/packages/dance_domain"

if [[ ! -d "$DOMAIN_DIR" ]]; then
  echo "FAIL: $DOMAIN_DIR not found" >&2
  exit 1
fi

fail=0

check_pubspec() {
  local pubspec="$DOMAIN_DIR/pubspec.yaml"
  if [[ ! -f "$pubspec" ]]; then
    echo "FAIL: $pubspec not found" >&2
    fail=1
    return
  fi
  if grep -Eiq '^\s*(flutter|serverpod(_client|_shared)?)\s*:' "$pubspec"; then
    echo "FAIL: $pubspec declares a forbidden dependency:" >&2
    grep -Ein '^\s*(flutter|serverpod(_client|_shared)?)\s*:' "$pubspec" >&2
    fail=1
  fi
}

check_imports() {
  local hits
  hits="$(grep -rEn \
    "^\s*import\s+['\"]package:(flutter|serverpod)" \
    "$DOMAIN_DIR/lib" "$DOMAIN_DIR/test" 2>/dev/null || true)"
  # dart:ffi is a Dart-core import, not a package import, so it needs its
  # own pattern.
  local ffi_hits
  ffi_hits="$(grep -rEn "^\s*import\s+['\"]dart:ffi" \
    "$DOMAIN_DIR/lib" "$DOMAIN_DIR/test" 2>/dev/null || true)"

  if [[ -n "$hits" || -n "$ffi_hits" ]]; then
    echo "FAIL: dance_domain imports a forbidden package:" >&2
    [[ -n "$hits" ]] && echo "$hits" >&2
    [[ -n "$ffi_hits" ]] && echo "$ffi_hits" >&2
    fail=1
  fi
}

check_pubspec
check_imports

# Second half: dance_trainer_flutter must never import dance_trainer_server
# directly (design.md "Dependency boundaries" — the app talks to the server
# only through the generated dance_trainer_client, never by reaching into
# server internals). Only runs once both packages actually exist; skipped
# gracefully before that (task 0.1 was incomplete when this script was
# first written).
FLUTTER_DIR="$REPO_ROOT/dance_trainer_flutter"
SERVER_PKG_NAME="dance_trainer_server"

if [[ -d "$FLUTTER_DIR" ]]; then
  if grep -Eiq "^\s*${SERVER_PKG_NAME}\s*:" "$FLUTTER_DIR/pubspec.yaml" 2>/dev/null; then
    echo "FAIL: $FLUTTER_DIR/pubspec.yaml depends on $SERVER_PKG_NAME directly" >&2
    fail=1
  fi
  flutter_hits="$(grep -rEn "^\s*import\s+['\"]package:${SERVER_PKG_NAME}" \
    "$FLUTTER_DIR/lib" 2>/dev/null || true)"
  if [[ -n "$flutter_hits" ]]; then
    echo "FAIL: dance_trainer_flutter imports the server package directly:" >&2
    echo "$flutter_hits" >&2
    fail=1
  fi
else
  echo "SKIP: $FLUTTER_DIR does not exist yet — nothing to check on that half."
fi

if [[ "$fail" -ne 0 ]]; then
  echo >&2
  echo "dance_domain must import neither Flutter, FFI nor Serverpod, and" >&2
  echo "dance_trainer_flutter must never import dance_trainer_server" >&2
  echo "directly. This is what lets the client (provisional) and server" >&2
  echo "(authoritative) tiers run identical scoring code and agree" >&2
  echo "(requirement 8.3), and what keeps the app talking to the backend" >&2
  echo "only through the generated dance_trainer_client." >&2
  exit 1
fi

echo "OK: dance_domain has no Flutter, FFI or Serverpod dependency, and" \
     "dance_trainer_flutter does not import dance_trainer_server directly."
