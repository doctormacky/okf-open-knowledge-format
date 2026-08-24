#!/usr/bin/env bash
# Lightweight OKF Bundle Validator v0.2
# Usage: validate.sh <bundle-path>
# Checks core conformance plus selected OKF v0.2 field contracts:
#   E1: All non-reserved .md files have YAML frontmatter
#   E2: All frontmatter has non-empty 'type' field
#   E3: Reserved files follow structure rules
#   E4: Attested Computation concepts have their required contract

set -euo pipefail

BUNDLE="${1:-.}"
BUNDLE="${BUNDLE%/}"
if [ -z "$BUNDLE" ]; then
  BUNDLE="/"
fi
ERRORS=0
WARNINGS=0
TOTAL=0
YAML_PARSER_WARNING=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

if [ ! -d "$BUNDLE" ]; then
  echo -e "${RED}Error: '$BUNDLE' is not a directory${NC}"
  exit 1
fi

echo "Validating OKF v0.2 bundle: $BUNDLE"
echo "---"

# Find all .md files
while IFS= read -r -d '' file; do
  TOTAL=$((TOTAL + 1))
  relative="${file#$BUNDLE/}"
  basename=$(basename "$file")

  # Skip reserved files (validate separately)
  if [[ "$basename" == "index.md" || "$basename" == "log.md" ]]; then
    # E3: Check reserved file structure
    if [[ "$basename" == "index.md" ]]; then
      # index.md should NOT have frontmatter (except bundle root may have okf_version)
      if head -1 "$file" | grep -q "^---$"; then
        # Allow only if it's bundle root and contains okf_version
        if [[ "$relative" != "index.md" ]]; then
          echo -e "${RED}E3: $relative — index.md should not have frontmatter${NC}"
          ERRORS=$((ERRORS + 1))
        elif ! sed -n '2,/^---$/p' "$file" | grep -qE '^okf_version:[[:space:]]*(["'\''])0[.]2\1[[:space:]]*$'; then
          echo -e "${RED}E3: $relative — root index frontmatter must declare okf_version: \"0.2\"${NC}"
          ERRORS=$((ERRORS + 1))
        fi
      fi
      if ! grep -qE '^# +[^#]' "$file"; then
        echo -e "${RED}E3: $relative — index.md should group entries under headings${NC}"
        ERRORS=$((ERRORS + 1))
      fi
      if ! grep -qE '^[*+-] +\[[^]]+\]\([^)]+\)' "$file"; then
        echo -e "${YELLOW}W4: $relative — index.md contains no linked entries${NC}"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
    if [[ "$basename" == "log.md" ]]; then
      if head -1 "$file" | grep -q '^---$'; then
        echo -e "${RED}E3: $relative — log.md should not have frontmatter${NC}"
        ERRORS=$((ERRORS + 1))
      fi
      # log.md should have date headings in YYYY-MM-DD format
      if ! grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" "$file" 2>/dev/null; then
        if [ -s "$file" ]; then
          echo -e "${YELLOW}W: $relative — log.md has no ISO 8601 date headings${NC}"
          WARNINGS=$((WARNINGS + 1))
        fi
      else
        log_headings=$(sed -nE 's/^## (.*)$/\1/p' "$file")
        if echo "$log_headings" | grep -qEv '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
          echo -e "${RED}E3: $relative — all log headings must use ## YYYY-MM-DD${NC}"
          ERRORS=$((ERRORS + 1))
        elif [[ "$log_headings" != "$(echo "$log_headings" | LC_ALL=C sort -r)" ]]; then
          echo -e "${RED}E3: $relative — log date headings must be newest first${NC}"
          ERRORS=$((ERRORS + 1))
        fi
      fi
    fi
    continue
  fi

  # E1: Check for YAML frontmatter
  if ! head -1 "$file" | grep -q "^---$"; then
    echo -e "${RED}E1: $relative — no YAML frontmatter${NC}"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Extract frontmatter (between first --- and second ---)
  if [ "$(grep -c '^---$' "$file")" -lt 2 ]; then
    echo -e "${RED}E1: $relative — frontmatter has no closing delimiter${NC}"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  frontmatter=$(sed -n '2,/^---$/p' "$file" | sed '$d')
  body=$(
    awk '
      $0 == "---" && markers < 2 { markers++; next }
      markers == 2 { print }
    ' "$file"
  )

  # Parse YAML with an available structured parser.
  if command -v ruby >/dev/null 2>&1; then
    if ! echo "$frontmatter" | ruby -ryaml -rdate -e '
      value = YAML.safe_load(
        STDIN.read,
        permitted_classes: [Date, Time],
        aliases: false
      )
      exit(value.is_a?(Hash) ? 0 : 1)
    ' >/dev/null 2>&1; then
      echo -e "${RED}E1: $relative — frontmatter is not a parseable YAML mapping${NC}"
      ERRORS=$((ERRORS + 1))
      continue
    fi
  elif command -v python3 >/dev/null 2>&1 &&
       python3 -c 'import yaml' >/dev/null 2>&1; then
    if ! echo "$frontmatter" | python3 -c '
import sys
import yaml

value = yaml.safe_load(sys.stdin.read())
raise SystemExit(0 if isinstance(value, dict) else 1)
' >/dev/null 2>&1; then
      echo -e "${RED}E1: $relative — frontmatter is not a parseable YAML mapping${NC}"
      ERRORS=$((ERRORS + 1))
      continue
    fi
  elif [ "$YAML_PARSER_WARNING" -eq 0 ]; then
    echo -e "${YELLOW}W0: $relative — no YAML parser found; syntax parsing was skipped${NC}"
    WARNINGS=$((WARNINGS + 1))
    YAML_PARSER_WARNING=1
  fi

  # E2: Check for non-empty type field
  type_value=$(echo "$frontmatter" | grep -E "^type:" | sed 's/^type:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs || true)
  if [ -z "$type_value" ]; then
    echo -e "${RED}E2: $relative — missing or empty 'type' field${NC}"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Warnings for recommended fields
  if ! echo "$frontmatter" | grep -qE "^title:"; then
    echo -e "${YELLOW}W1: $relative — missing recommended 'title' field${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
  if ! echo "$frontmatter" | grep -qE "^description:"; then
    echo -e "${YELLOW}W1: $relative — missing recommended 'description' field${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi

  # W6: v0.1 migration fields
  if echo "$frontmatter" | grep -qE '^timestamp:[[:space:]]*'; then
    echo -e "${YELLOW}W6: $relative — legacy 'timestamp' is superseded by 'generated.at'${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
  if echo "$body" | grep -qE '^# Citations[[:space:]]*$'; then
    echo -e "${YELLOW}W6: $relative — legacy '# Citations' is superseded by 'sources' and keyed footnotes${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi

  # W7: all OKF timestamp-valued fields need a datetime and explicit offset
  timestamp_pattern='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})'
  while IFS= read -r timestamp_line; do
    [ -n "$timestamp_line" ] || continue
    if ! echo "$timestamp_line" | grep -qE "$timestamp_pattern"; then
      echo -e "${YELLOW}W7: $relative — timestamp needs an ISO 8601 datetime with explicit UTC offset: $timestamp_line${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  done < <(
    echo "$frontmatter" |
      grep -E '^[[:space:]]*(stale_after|last_modified|at|from|to):|(^|[,{])[[:space:]]*(stale_after|last_modified|at|from|to):' ||
      true
  )

  # W8: optional v0.2 families must follow their internal contracts
  if echo "$frontmatter" | grep -qE '^generated:[[:space:]]*'; then
    generated_block=$(
      echo "$frontmatter" |
        awk '/^generated:[[:space:]]*/ { active=1 } active { print } active && NR > 1 && /^[^[:space:]]/ && !/^generated:/ { exit }'
    )
    if ! echo "$generated_block" | grep -qE '(^|[,{[:space:]])by:[[:space:]]*[^ },]+'; then
      echo -e "${YELLOW}W8: $relative — 'generated.by' is required when 'generated' is present${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi

  status_value=$(
    echo "$frontmatter" |
      sed -nE 's/^status:[[:space:]]*["'\'']?([^"'\'', #]+).*/\1/p' |
      head -1
  )
  if [ -n "$status_value" ] &&
     [[ "$status_value" != "draft" && "$status_value" != "stable" && "$status_value" != "deprecated" ]]; then
    echo -e "${YELLOW}W8: $relative — status should be draft, stable, or deprecated${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi

  if echo "$frontmatter" | grep -qE '^sources:[[:space:]]*$'; then
    sources_block=$(
      echo "$frontmatter" |
        awk '/^sources:[[:space:]]*$/ { active=1; next } active && /^[^[:space:]]/ { exit } active { print }'
    )
    source_count=$(echo "$sources_block" | grep -Ec '^[[:space:]]*-[[:space:]]+' || true)
    resource_count=$(echo "$sources_block" | grep -Ec '^[[:space:]]+(resource|-[[:space:]]+resource):[[:space:]]*[^[:space:]]' || true)
    if [ "$source_count" -eq 0 ] || [ "$resource_count" -lt "$source_count" ]; then
      echo -e "${YELLOW}W8: $relative — each 'sources' entry requires a non-empty 'resource'${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi

  # E4: type-specific requirements for Attested Computation
  if [[ "$type_value" == "Attested Computation" ]]; then
    runtime_value=$(
      echo "$frontmatter" |
        sed -nE 's/^runtime:[[:space:]]*["'\'']?([^"'\'', #]+).*/\1/p' |
        head -1
    )
    computation_value=$(
      echo "$frontmatter" |
        sed -nE 's/^computation:[[:space:]]*["'\'']?([^"'\'', #]+).*/\1/p' |
        head -1
    )
    has_inline=0
    if echo "$body" | awk '
      /^# Computation[[:space:]]*$/ { active=1; next }
      active && /^# / { exit }
      active && (/^```/ || /^~~~/ || /^    [^[:space:]]/) { found=1 }
      END { exit(found ? 0 : 1) }
    '; then
      has_inline=1
    fi

    if [ -z "$runtime_value" ]; then
      echo -e "${RED}E4: $relative — Attested Computation requires non-empty 'runtime'${NC}"
      ERRORS=$((ERRORS + 1))
    fi
    if [ -z "$computation_value" ] && [ "$has_inline" -eq 0 ]; then
      echo -e "${RED}E4: $relative — provide inline '# Computation' code or a 'computation' path${NC}"
      ERRORS=$((ERRORS + 1))
    elif [ -n "$computation_value" ] && [ "$has_inline" -eq 1 ]; then
      echo -e "${RED}E4: $relative — provide computation inline or by path, not both${NC}"
      ERRORS=$((ERRORS + 1))
    fi
  fi

done < <(find "$BUNDLE" -name "*.md" -type f -print0 | sort -z)

# Summary
echo "---"
echo "Files scanned: $TOTAL"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Bundle passes the checked OKF v0.2 conformance rules${NC}"
else
  echo -e "${RED}❌ $ERRORS error(s) — bundle is NOT conformant${NC}"
fi
if [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}⚠  $WARNINGS warning(s)${NC}"
fi

exit $ERRORS
