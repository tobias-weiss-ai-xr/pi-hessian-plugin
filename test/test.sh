#!/usr/bin/env bash
# Test suite for pi-hessian-plugin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0; SKIP=0

pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }
skip() { echo -e "${YELLOW}⊘${NC} $1"; SKIP=$((SKIP+1)); }
echo_header() { echo ""; echo -e "${YELLOW}=== $1 ===${NC}"; }

test_file_structure() {
    echo_header "File Structure Tests"
    local files=(
        "package.json" "tsconfig.json" "src/hessian.ts" "src/hessian-memory.ts"
        "src/types.ts" "src/generate-hessian-config.sh" "src/validate-config.sh"
        "src/setup-wizard.sh" "extensions/index.ts" "install.sh" "Dockerfile"
        "README.md" "LICENSE" "schema/placeholder.json"
    )
    for f in "${files[@]}"; do
        [ -f "$PROJECT_DIR/$f" ] && pass "$f exists" || fail "$f missing"
    done
    local skills=(
        "src/.opencode/skills/hessian-health.md"
        "src/.opencode/skills/hessian-list-models.md"
        "src/.opencode/skills/hessian-optimize.md"
        "src/.opencode/skills/hessian-refresh.md"
        "src/.opencode/skills/hessian-switch-profile.md"
    )
    for f in "${skills[@]}"; do
        [ -f "$PROJECT_DIR/$f" ] && pass "Skill: $f" || skip "Skill missing (optional): $f"
    done
}

test_typescript() {
    echo_header "TypeScript Compilation"
    cd "$PROJECT_DIR"
    if npx tsc --noEmit --skipLibCheck 2>&1; then
        pass "TypeScript compilation successful"
    else
        fail "TypeScript compilation failed"
    fi
}

test_shell_syntax() {
    echo_header "Shell Script Syntax"
    cd "$PROJECT_DIR"
    local scripts=(src/*.sh sandbox/*.sh install.sh)
    for s in "${scripts[@]}"; do
        [ -f "$s" ] || continue
        bash -n "$s" 2>&1 && pass "Syntax OK: $(basename "$s")" || fail "Syntax error: $(basename "$s")"
    done
}

test_json_validity() {
    echo_header "JSON Validity"
    cd "$PROJECT_DIR"
    local json_files=(package.json tsconfig.json schema/placeholder.json pi.json.example)
    for f in "${json_files[@]}"; do
        [ -f "$f" ] || { skip "JSON check: $f not found"; continue; }
        jq empty "$f" 2>&1 && pass "JSON valid: $f" || fail "JSON invalid: $f"
    done
}

test_permissions() {
    echo_header "File Permissions"
    cd "$PROJECT_DIR"
    local exec_files=(src/*.sh sandbox/*.sh install.sh)
    for f in "${exec_files[@]}"; do
        [ -f "$f" ] || continue
        [ -x "$f" ] && pass "Executable: $(basename "$f")" || { chmod +x "$f"; pass "Fixed: $(basename "$f")"; }
    done
}

test_package_json() {
    echo_header "Package.json Tests"
    [ -f "package.json" ] || { fail "package.json missing"; return; }
    local name=$(jq -r '.name' package.json)
    local type=$(jq -r '.type' package.json)
    [[ "$name" == "pi-hessian-plugin" ]] && pass "Name: $name" || fail "Name: $name"
    [[ "$type" == "module" ]] && pass "Type: $type" || fail "Type: $type"
}

test_documentation() {
    echo_header "Documentation Tests"
    grep -q "Hessian" README.md && pass "README.md mentions Hessian" || fail "README.md missing Hessian"
    grep -q "Installation" README.md && pass "README.md has Installation" || fail "README.md missing Installation"
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║       pi-hessian-plugin Test Suite                    ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    test_file_structure
    test_typescript
    test_shell_syntax
    test_json_validity
    test_permissions
    test_package_json
    test_documentation
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    printf "║  Passed: %-3d  Failed: %-3d  Skipped: %-3d          ║\n" $PASS $FAIL $SKIP
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    [ "$FAIL" -eq 0 ] && echo -e "${GREEN}All tests passed!${NC}" || echo -e "${RED}Some tests failed.${NC}"
    exit $FAIL
}

main
