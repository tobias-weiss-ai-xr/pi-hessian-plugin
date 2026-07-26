#!/usr/bin/env bash
# Hessian.AI Plugin - Setup Wizard
# Interactive setup for Hessian.AI plugin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_question() {
  echo -e "${BLUE}[?]${NC} $1"
}

echo_header() {
  echo -e "\n${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}       Hessian.AI Plugin Setup Wizard        ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
}

echo_success() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}  Setup complete! Plugin is ready to use.     ${GREEN}║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
}

# Main setup function
setup_wizard() {
  echo_header

  log_info "Welcome to the Hessian.AI Plugin Setup Wizard!"
  log_info "This will guide you through the initial configuration."
  echo ""

  # Step 1: API Key
  while [[ -z "${API_KEY:-}" ]]; do
    log_question "Enter your Hessian.AI API key (or press Enter to set later):"
    read -r -s API_KEY
    echo ""
    if [[ -z "$API_KEY" ]]; then
      log_info "You can set the API key later via HESSIAN_API_KEY environment variable."
      API_KEY_PROMPT="not_set"
      break
    fi
    echo ""
    log_info "API key set."
    API_KEY_PROMPT="set"
  done

  # Step 2: Profile
  log_question "Select default profile:"
  echo "  1) production    - Best performance, largest models"
  echo "  2) development   - Balanced performance and resource usage"
  echo "  3) budget        - Fast, efficient for testing"
  read -r -p "Enter choice [1-3]: " PROFILE_CHOICE
  echo ""

  case "$PROFILE_CHOICE" in
    1|""|production) PROFILE="production" ;;
    2|development) PROFILE="development" ;;
    3|budget) PROFILE="budget" ;;
    *) PROFILE="development" ;;
  esac

  log_info "Selected profile: $PROFILE"

  # Step 3: API URL
  log_question "Enter Hessian.AI API URL [https://api.hessian.ai/v1]:"
  read -r API_URL
  API_URL="${API_URL:-https://api.hessian.ai/v1}"
  log_info "API URL: $API_URL"

  # Step 4: Generate configuration
  log_info "Generating configuration..."
  
  if [[ "$API_KEY_PROMPT" == "set" ]]; then
    export HESSIAN_API_KEY="$API_KEY"
  fi
  export HESSIAN_PROFILE="$PROFILE"
  export HESSIAN_API_URL="$API_URL"

  # Generate config
  if (cd "$PROJECT_ROOT" && bash src/generate-hessian-config.sh 2>&1); then
    log_info "Configuration generated successfully!"
  else
    log_error "Failed to generate configuration."
    log_info "Please check your API key and network connection."
    exit 1
  fi

  # Step 5: Install plugin
  log_info "Installing plugin..."
  bash "$SCRIPT_DIR/copy-hessian-config.sh" 2>&1 || \
    log_info "Manual installation: Copy pi-hessian.json to ~/.config/pi/plugins/hessian/"

  # Step 6: Summary
  echo ""
  echo_header
  log_info "Setup Summary:"
  log_info "─────────────────────────────────────────────"
  log_info "  API Key:    ${API_KEY_PROMPT}"
  log_info "  Profile:    $PROFILE"
  log_info "  API URL:    $API_URL"
  log_info ""
  log_info "Next Steps:"
  log_info "  1. Add to pi.json: \"plugin\": [\"hessian\"]"
  log_info "  2. Set model: \"model\": \"hessian/tud/qwen3.6-35b-a3b\""
  log_info "  3. Start pi with: HESSIAN_API_KEY=your_key pi"
  log_info ""

  echo_success
}

# Run setup
setup_wizard
