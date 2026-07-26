#!/usr/bin/env bash
# Hessian.AI Plugin - Copy Configuration
# Copies generated configuration to pi plugins directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

# Check if source file exists
SOURCE_FILE="${1:-$PROJECT_ROOT/pi-hessian.json}"
if [[ ! -f "$SOURCE_FILE" ]]; then
  log_error "Source file not found: $SOURCE_FILE"
  log_error "Please generate configuration first with: npm run generate"
fi

# Target directory
TARGET_DIR="${2:-$HOME/.config/pi/plugins/hessian}"
log_info "Copying configuration to: $TARGET_DIR"

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy files
cp "$SOURCE_FILE" "$TARGET_DIR/"
log_info "Configuration copied successfully"

# Set permissions
chmod 600 "$TARGET_DIR/$(basename "$SOURCE_FILE")"
log_info "Permissions set to 600"

echo "Done!"
