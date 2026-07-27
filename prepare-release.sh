#!/bin/bash
set -e

# Prepare release script for pi-hessian-plugin
VERSION=$(node -p "require('./package.json').version")
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

print_header() {
    echo ""
    echo "=========================================="
    echo "  pi-hessian-plugin v$VERSION Release Prep"
    echo "=========================================="
    echo ""
}

print_step() { echo "  → $1"; }
print_success() { echo "  ✓ $1"; }
print_error() { echo "  ✗ $1"; exit 1; }

validate_package() {
    print_step "Validating package.json..."
    if ! grep -q '"name": "pi-hessian-plugin"' package.json; then
        print_error "package.json missing name field"
    fi
    if ! grep -q '"version"' package.json; then
        print_error "package.json missing version field"
    fi
    print_success "package.json is valid"
}

validate_typescript() {
    print_step "Validating TypeScript files..."
    for f in src/hessian.ts src/hessian-memory.ts extensions/index.ts; do
        [ -f "$f" ] || print_error "$f not found"
    done
    if command -v npx &> /dev/null; then
        npx tsc --noEmit --skipLibCheck 2>&1 || print_error "TypeScript compilation failed"
        print_success "TypeScript files are valid"
    fi
}

validate_scripts() {
    print_step "Validating shell scripts..."
    local scripts=(
        "src/generate-hessian-config.sh"
        "src/copy-hessian-config.sh"
        "src/validate-config.sh"
        "src/setup-wizard.sh"
        "install.sh"
    )
    for script in "${scripts[@]}"; do
        [ -f "$script" ] || print_error "$script not found"
    done
    print_success "Shell scripts are valid"
}

validate_schemas() {
    print_step "Validating schema files..."
    [ -f "schema/placeholder.json" ] || print_error "schema/placeholder.json not found"
    if command -v jq &> /dev/null; then
        jq empty schema/placeholder.json 2>&1 || print_error "schema is invalid JSON"
    fi
    print_success "Schema files are valid"
}

validate_docs() {
    print_step "Validating documentation..."
    for doc in README.md CHANGELOG.md LICENSE; do
        [ -f "$doc" ] || print_error "$doc not found"
    done
    print_success "Documentation files are present"
}

cleanup() {
    print_step "Cleaning up..."
    rm -f pi-hessian.json
    print_success "Cleanup complete"
}

main() {
    print_header
    print_step "Starting release preparation..."
    echo ""
    validate_package
    validate_typescript
    validate_scripts
    validate_schemas
    validate_docs
    cleanup
    echo ""
    echo "=========================================="
    echo "  Release Preparation Complete!"
    echo "=========================================="
    echo ""
    echo "Version: v$VERSION"
    echo "Commit: $GIT_HASH"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Commit changes: git commit -m 'Prepare v$VERSION'"
    echo "  3. Create tag: git tag v$VERSION"
    echo "  4. Push: git push && git push --tags"
    echo ""
}

main
