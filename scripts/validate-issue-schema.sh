#!/usr/bin/env bash
set -euo pipefail

# validate-issue-schema.sh
# Validates Samverk dispatcher issue frontmatter (schema v1.1.0).
# Usage:
#   validate-issue-schema.sh issue.md
#   cat issue.md | validate-issue-schema.sh

VALID_TYPES="task question result block coordination"
VALID_AGENT_TYPES="orchestrator dispatcher code-gen test docs research qc human infra pc"
VALID_PRIORITIES="critical high normal low"

errors=()

# Read input from file arg or stdin
if [[ $# -gt 0 ]]; then
  if [[ ! -f "$1" ]]; then
    echo "ERROR: file not found: $1" >&2
    exit 1
  fi
  content="$(cat "$1")"
else
  content="$(cat)"
fi

# Check frontmatter delimiters
first_line="$(printf '%s\n' "$content" | head -n1)"
if [[ "$first_line" != "---" ]]; then
  echo "ERROR: frontmatter not found (file must start with ---)" >&2
  exit 1
fi

# Extract frontmatter block between first and second ---
frontmatter="$(printf '%s\n' "$content" | awk '/^---$/{n++; if(n==2) exit; next} n==1{print}')"

if [[ -z "$frontmatter" ]]; then
  echo "ERROR: frontmatter block is empty or closing --- is missing" >&2
  exit 1
fi

# Helper: extract value for a key from frontmatter
get_field() {
  local key="$1"
  printf '%s\n' "$frontmatter" | grep -E "^${key}:" | head -n1 | sed "s/^${key}:[[:space:]]*//" | tr -d '"'"'"
}

# Helper: check if a value is in a space-separated list
in_list() {
  local val="$1"
  local list="$2"
  for item in $list; do
    [[ "$item" == "$val" ]] && return 0
  done
  return 1
}

# --- Validate schema_version ---
schema_version="$(get_field schema_version)"
if [[ -z "$schema_version" ]]; then
  errors+=("missing required field: schema_version")
elif [[ "$schema_version" != "1.1.0" ]]; then
  errors+=("invalid schema_version: \"${schema_version}\" (expected \"1.1.0\")")
fi

# --- Validate type ---
type_val="$(get_field type)"
if [[ -z "$type_val" ]]; then
  errors+=("missing required field: type")
elif ! in_list "$type_val" "$VALID_TYPES"; then
  errors+=("invalid type: \"${type_val}\" (valid: ${VALID_TYPES})")
fi

# --- Validate agent_type ---
agent_type_val="$(get_field agent_type)"
if [[ -z "$agent_type_val" ]]; then
  errors+=("missing required field: agent_type")
elif ! in_list "$agent_type_val" "$VALID_AGENT_TYPES"; then
  errors+=("invalid agent_type: \"${agent_type_val}\" (valid: ${VALID_AGENT_TYPES})")
fi

# --- Validate priority ---
priority_val="$(get_field priority)"
if [[ -z "$priority_val" ]]; then
  errors+=("missing required field: priority")
elif ! in_list "$priority_val" "$VALID_PRIORITIES"; then
  errors+=("invalid priority: \"${priority_val}\" (valid: ${VALID_PRIORITIES})")
fi

# --- Report results ---
if [[ ${#errors[@]} -gt 0 ]]; then
  echo "ERROR: issue frontmatter validation failed:" >&2
  for err in "${errors[@]}"; do
    echo "  - ${err}" >&2
  done
  exit 1
fi

echo "OK: frontmatter is valid (schema_version=${schema_version}, type=${type_val}, agent_type=${agent_type_val}, priority=${priority_val})"
exit 0
