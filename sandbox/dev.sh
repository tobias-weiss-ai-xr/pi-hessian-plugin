#!/usr/bin/env bash
set -euo pipefail

# Hessian.AI Plugin Sandbox - Development Mode
# Runs with live file mounting for active development

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[DEV]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
  log_error "Docker is not installed or not in PATH"
  exit 1
fi

# Set default values
API_KEY="${HESSIAN_API_KEY:-}"
PROFILE="${HESSIAN_PROFILE:-development}"  # Use development profile by default

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --api-key KEY    Hessian.AI API key"
            echo "  --profile NAME   Profile: production, development, budget"
            echo "  --help, -h       Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

log_info "Starting development sandbox..."
log_info "Profile: $PROFILE"

# Build or use existing image
IMAGE_NAME="ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest-dev"

if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
  log_info "Building development image..."
  docker build -t "$IMAGE_NAME" -f Dockerfile.dev "$PROJECT_ROOT" 2>&1 || \
    docker build -t "$IMAGE_NAME" "$PROJECT_ROOT"
fi

# Mount current directory for live editing
exec docker run -it --rm \
  -e HESSIAN_API_KEY="$API_KEY" \
  -e HESSIAN_PROFILE="$PROFILE" \
  -v "$PROJECT_ROOT:/home/pluginuser/app" \
  -v "$PROJECT_ROOT/pi-config:/home/pluginuser/.config/pi" \
  -w /home/pluginuser/app \
  "$IMAGE_NAME" sh
