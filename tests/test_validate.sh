#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$TEST_DIR/.." && pwd)
VALIDATOR="$ROOT_DIR/scripts/validate.sh"
FIXTURES="$TEST_DIR/fixtures"
PASSED=0
OUTPUT=""
EXIT_CODE=0

run_case() {
  set +e
  OUTPUT=$("$VALIDATOR" "$1" 2>&1)
  EXIT_CODE=$?
  set -e
}

pass() {
  PASSED=$((PASSED + 1))
  printf 'PASS %02d: %s\n' "$PASSED" "$1"
}

fail() {
  echo "FAIL: $1" >&2
  printf '%s\n' "$OUTPUT" >&2
  exit 1
}

expect_pass() {
  run_case "$2"
  [ "$EXIT_CODE" -eq 0 ] || fail "$1 should pass"
  grep -q 'PASS: bundle is valid OKF v0.2' <<<"$OUTPUT" ||
    fail "$1 did not print PASS"
  pass "$1"
}

expect_error() {
  run_case "$2"
  [ "$EXIT_CODE" -eq 1 ] || fail "$1 should fail"
  grep -q "ERROR $3:" <<<"$OUTPUT" || fail "$1 did not report $3"
  grep -q "$4" <<<"$OUTPUT" || fail "$1 message did not match"
  pass "$1"
}

expect_warning() {
  run_case "$2"
  [ "$EXIT_CODE" -eq 0 ] || fail "$1 warning should not block"
  grep -q "WARNING $3:" <<<"$OUTPUT" || fail "$1 did not report $3"
  pass "$1"
}

# Real bundles with different domains and layouts.
expect_pass "analytics bundle" "$FIXTURES/valid-v02"
expect_pass "incident response bundle" "$FIXTURES/valid-incident-v02"
expect_pass "API bundle" "$FIXTURES/valid-api-v02"
expect_pass "external computation bundle" "$FIXTURES/valid-attested-external-v02"
expect_pass "paths with spaces" "$FIXTURES/rules/path with spaces"
expect_pass "inline source mapping" "$FIXTURES/rules/valid-inline-source"

# Required concept structure.
expect_error "missing frontmatter" "$FIXTURES/rules/e1-no-frontmatter" "E1" "no YAML frontmatter"
expect_error "invalid YAML" "$FIXTURES/rules/e1-invalid-yaml" "E1" "not parseable YAML"
expect_error "duplicate YAML key" "$FIXTURES/rules/e1-duplicate-key" "E1" "duplicate key"
expect_error "missing type" "$FIXTURES/rules/e2-missing-type" "E2" "requires non-empty string type"

# Reserved files.
expect_error "unquoted root version" "$FIXTURES/rules/e3-root-index-version" "E3" "okf_version"
expect_error "nested index frontmatter" "$FIXTURES/rules/e3-nested-index" "E3" "only the bundle-root"
expect_error "index without links" "$FIXTURES/rules/e3-index-no-links" "E3" "linked entry"
expect_error "log frontmatter" "$FIXTURES/rules/e3-log-frontmatter" "E3" "must not have frontmatter"
expect_error "invalid log date" "$FIXTURES/rules/e3-log-heading" "E3" "invalid log date"
expect_error "unsorted log dates" "$FIXTURES/rules/e3-log-order" "E3" "newest first"

# Optional v0.2 fields are optional, but must have the correct shape when used.
expect_error "missing computation runtime" "$FIXTURES/rules/e4-missing-runtime" "E4" "requires runtime"
expect_error "missing computation body" "$FIXTURES/rules/e4-missing-computation" "E4" "requires inline code"
expect_error "both computation forms" "$FIXTURES/rules/e4-both-computations" "E4" "mutually exclusive"
expect_error "invalid timestamps" "$FIXTURES/rules/e4-invalid-timestamps" "E4" "explicit offset"
expect_error "generated without by" "$FIXTURES/rules/e4-generated" "E4" "generated.by"
expect_error "incomplete verification" "$FIXTURES/rules/e4-verified" "E4" "verified\\[0\\].at"
expect_error "invalid status" "$FIXTURES/rules/e4-status" "E4" "status must"
expect_error "source without resource" "$FIXTURES/rules/e4-sources" "E4" "sources\\[0\\].resource"
expect_error "scalar tags" "$FIXTURES/rules/e4-tags" "E4" "tags must"
expect_error "invalid attested fields" "$FIXTURES/rules/e4-attestation-shape" "E4" "parameters\\[0\\].required"

# Explicitly permitted by OKF.
expect_warning "missing recommended display fields" "$FIXTURES/rules/w1-missing-display" "W1"
expect_pass "broken Markdown link" "$FIXTURES/rules/valid-broken-link"
expect_warning "legacy v0.1 fields" "$FIXTURES/legacy-v01" "W6"

# Command-level behavior and combined failure.
run_case "$FIXTURES/does-not-exist"
[ "$EXIT_CODE" -eq 2 ] || fail "missing directory should exit 2"
pass "missing directory"

run_case "$FIXTURES/invalid-v02"
[ "$EXIT_CODE" -eq 1 ] || fail "combined invalid bundle should fail"
for code in E2 E3 E4; do
  grep -q "ERROR $code:" <<<"$OUTPUT" ||
    fail "combined invalid bundle did not report $code"
done
pass "combined invalid bundle"

printf 'validator tests: PASS (%d checks)\n' "$PASSED"
