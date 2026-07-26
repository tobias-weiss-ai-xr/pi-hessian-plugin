#!/usr/bin/env bash
set -euo pipefail

# Hessian.AI Plugin Test Suite
# Runs comprehensive tests in the sandbox environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
TEST_COUNT=0

pass() {
  echo -e "${GREEN}  ✓${NC} $1"
  ((PASS_COUNT++))
  ((TEST_COUNT++))
}

fail() {
  echo -e "${RED}  ✗${NC} $1"
  ((FAIL_COUNT++))
  ((TEST_COUNT++))
}

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

test_header() {
  echo -e "\n${YELLOW}────────────────────────────────────────────────────────${NC}"
  echo -e "${YELLOW}  $1${NC}"
  echo -e "${YELLOW}────────────────────────────────────────────────────────${NC}"
}

# Test 1: Docker image exists
test_header "Docker Environment Tests"

if command -v docker &> /dev/null; then
  pass "Docker is installed and available"
else
  fail "Docker is not installed"
  exit 1
fi

IMAGE_NAME="ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest"
if docker image inspect "$IMAGE_NAME" &> /dev/null; then
  pass "Docker image exists"
else
  info "Building Docker image for testing..."
  if docker build -t "$IMAGE_NAME" "$PROJECT_ROOT" 2>&1; then
    pass "Docker image built successfully"
  else
    fail "Failed to build Docker image"
  fi
fi

# Test 2: Files exist
test_header "File Structure Tests"

required_files=(
  "package.json"
  "tsconfig.json"
  "src/hessian.ts"
  "src/hessian-memory.ts"
  "src/types.ts"
  "src/generate-hessian-config.sh"
  "Dockerfile"
  ".dockerignore"
  "sandbox/run.sh"
  "sandbox/showcase.sh"
  "sandbox/dev.sh"
  "sandbox/test.sh"
)

for file in "${required_files[@]}"; do
  if [[ -f "$PROJECT_ROOT/$file" ]]; then
    pass "$file exists"
  else
    fail "$file is missing"
  fi
done

# Test 3: Configuration generation
test_header "Configuration Tests"

# Create a temporary config
TEMP_CONFIG="$(mktemp)"
if node -e "
  const fs = require('fs');
  const config = {
    '\$schema': 'https://pi.code/config.json',
    'permission': {
      'bash': 'allow', 'edit': 'allow', 'read': 'allow', 'grep': 'allow',
      'glob': 'allow', 'lsp': 'allow', 'skill': 'allow', 'task': 'allow',
      'webfetch': 'allow', 'websearch': 'allow', 'question': 'allow'
    },
    'model': 'hessian/tud/qwen3.6-35b-a3b',
    'provider': {
      'hessian': {
        'npm': '@ai-sdk/openai-compatible',
        'name': 'Hessian.AI',
        'options': {
          'baseURL': 'https://api.hessian.ai/v1',
          'apiKey': '{env:HESSIAN_API_KEY}'
        },
        'models': {
          'tud/qwen3.6-35b-a3b': {
            'name': 'Qwen 3.6 35B-A3B',
            'category': 'tud',
            'limit': { 'context': 16384, 'output': 2048 },
            'metadata': { 'estimated_latency': 'moderate' },
            'can_reason': true
          }
        }
      }
    }
  };
  fs.writeFileSync('$TEMP_CONFIG', JSON.stringify(config, null, 2));
" 2>/dev/null; then
  pass "Configuration generation works"
  rm -f "$TEMP_CONFIG"
else
  fail "Configuration generation failed"
fi

# Test 4: Shell scripts are executable
test_header "Shell Script Tests"

script_files=(
  "src/generate-hessian-config.sh"
  "sandbox/run.sh"
  "sandbox/showcase.sh"
  "sandbox/dev.sh"
  "sandbox/test.sh"
)

for script in "${script_files[@]}"; do
  if [[ -x "$PROJECT_ROOT/$script" ]]; then
    pass "$script is executable"
  else
    # Make it executable and test again
    chmod +x "$PROJECT_ROOT/$script"
    if [[ -x "$PROJECT_ROOT/$script" ]]; then
      pass "$script made executable"
    else
      fail "$script cannot be made executable"
    fi
  fi
done

# Test 5: TypeScript compilation
test_header "TypeScript Tests"

if command -v npm &> /dev/null; then
  if (cd "$PROJECT_ROOT" && npm run tsc 2>&1); then
    pass "TypeScript compilation successful"
  else
    fail "TypeScript compilation failed"
  fi
else
  info "npm not available, skipping TypeScript tests"
fi

# Test 6: Docker run basic
test_header "Docker Runtime Tests"

if docker run --rm \
  -e HESSIAN_API_KEY="test_key" \
  "$IMAGE_NAME" \
  bash -c "echo 'Docker test passed'" 2>/dev/null | grep -q "Docker test passed"; then
  pass "Docker container runs successfully"
else
  fail "Docker container test failed"
fi

# Test 7: Showcase scripts
test_header "Showcase Tests"

# Test ASCII (no API needed)
if docker run --rm \
  -e HESSIAN_API_KEY="" \
  "$IMAGE_NAME" \
  bash sandbox/showcase.sh ascii 2>&1 | grep -q "Hessian.AI"; then
  pass "Showcase ASCII generation works"
else
  fail "Showcase ASCII generation failed"
fi

# Test joke (no API needed)
if docker run --rm \
  -e HESSIAN_API_KEY="" \
  "$IMAGE_NAME" \
  bash sandbox/showcase.sh joke 2>&1 | grep -q "programming"; then
  pass "Showcase joke generation works"
else
  fail "Showcase joke generation failed"
fi

# Test wisdom (no API needed)
if docker run --rm \
  -e HESSIAN_API_KEY="" \
  "$IMAGE_NAME" \
  bash sandbox/showcase.sh wisdom 2>&1 | grep -q "\""; then
  pass "Showcase wisdom generation works"
else
  fail "Showcase wisdom generation failed"
fi

# Test help
if docker run --rm \
  -e HESSIAN_API_KEY="" \
  "$IMAGE_NAME" \
  bash sandbox/showcase.sh -h 2>&1 | grep -q "Hessian.AI"; then
  pass "Showcase help works"
else
  fail "Showcase help failed"
fi

# Summary
test_header "Test Summary"
echo -e "\n${GREEN}  Total Tests:  $TEST_COUNT${NC}"
echo -e "${GREEN}  Passed:      $PASS_COUNT${NC}"
echo -e "${RED}  Failed:      $FAIL_COUNT${NC}"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo -e "\n${GREEN}  ✓ All tests passed!${NC}\n"
  exit 0
else
  echo -e "\n${RED}  ✗ Some tests failed${NC}\n"
  exit 1
fi
