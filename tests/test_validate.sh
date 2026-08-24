#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$TEST_DIR/.." && pwd)
VALIDATOR="$ROOT_DIR/scripts/validate.sh"
FIXTURES="$TEST_DIR/fixtures"

valid_output=$("$VALIDATOR" "$FIXTURES/valid-v02")
if ! grep -q "OKF v0.2" <<<"$valid_output"; then
  echo "valid fixture did not report OKF v0.2" >&2
  exit 1
fi

set +e
invalid_output=$("$VALIDATOR" "$FIXTURES/invalid-v02" 2>&1)
invalid_status=$?
set -e

if [ "$invalid_status" -eq 0 ]; then
  echo "invalid fixture unexpectedly passed" >&2
  exit 1
fi
for expected_code in E2 E3 E4 W7 W8; do
  if ! grep -q "$expected_code:" <<<"$invalid_output"; then
    echo "invalid fixture did not report $expected_code" >&2
    exit 1
  fi
done

legacy_output=$("$VALIDATOR" "$FIXTURES/legacy-v01")
if ! grep -q "W6:" <<<"$legacy_output"; then
  echo "legacy fixture did not report migration warnings" >&2
  exit 1
fi

echo "validator tests: PASS"
