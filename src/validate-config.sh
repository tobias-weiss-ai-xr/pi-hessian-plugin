#!/usr/bin/env bash
# Hessian.AI Plugin - Validate Configuration
# Validates the generated pi configuration file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}  ✓${NC} $1"
}

fail() {
  echo -e "${RED}  ✗${NC} $1" >&2
  exit 1
}

warn() {
  echo -e "${YELLOW}  ⚠${NC} $1"
}

# Check for config file
CONFIG_FILE="${1:-$PROJECT_ROOT/pi-hessian.json}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "Configuration file not found: $CONFIG_FILE"
fi

pass "Configuration file exists"

# Validate JSON syntax
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  fail "Invalid JSON syntax"
fi
pass "Valid JSON syntax"

# Check required fields
REQUIRED_FIELDS=("$schema" "permission" "provider")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! jq -e ".$field" "$CONFIG_FILE" >/dev/null 2>&1; then
    fail "Missing required field: $field"
  fi
  pass "Required field '$field' present"
done

# Check provider.hessian
if ! jq -e ".provider.hessian" "$CONFIG_FILE" >/dev/null 2>&1; then
  fail "Missing provider.hessian configuration"
fi
pass "Hessian.AI provider configured"

# Check hessian provider fields
HESSIAN_FIELDS=("npm" "name" "options" "models")
for field in "${HESSIAN_FIELDS[@]}"; do
  if ! jq -e ".provider.hessian.$field" "$CONFIG_FILE" >/dev/null 2>&1; then
    warn "Missing hessian.$field field"
  else
    pass "Hessian field '$field' present"
  fi
done

# Check options
if ! jq -e ".provider.hessian.options.baseURL" "$CONFIG_FILE" >/dev/null 2>&1; then
  warn "Missing baseURL in options"
else
  BASE_URL=$(jq -r ".provider.hessian.options.baseURL" "$CONFIG_FILE")
  pass "Base URL: $BASE_URL"
fi

if ! jq -e ".provider.hessian.options.apiKey" "$CONFIG_FILE" >/dev/null 2>&1; then
  warn "Missing apiKey in options"
else
  pass "API Key configuration present"
fi

# Check models
MODEL_COUNT=$(jq ".provider.hessian.models | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
if [[ "$MODEL_COUNT" -eq 0 ]]; then
  warn "No models configured"
else
  pass "$MODEL_COUNT models configured"
fi

# Check if TUD models are present
TUD_COUNT=$(jq ".provider.hessian.models | keys[] | startswith(\"tud/\") | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
if [[ "$TUD_COUNT" -gt 0 ]]; then
  pass "$TUD_COUNT TUD models configured"
else
  warn "No TUD models found"
fi

# Check default model
if jq -e ".model" "$CONFIG_FILE" >/dev/null 2>&1; then
  DEFAULT_MODEL=$(jq -r ".model" "$CONFIG_FILE")
  pass "Default model: $DEFAULT_MODEL"
else
  warn "No default model set"
fi

# Summary
echo ""
pass "Configuration validation complete!"
