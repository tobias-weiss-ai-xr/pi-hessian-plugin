#!/usr/bin/env bash
set -euo pipefail

# Hessian.AI Plugin Sandbox - Interactive Shell
# Runs pi with Hessian.AI plugin in a Docker container

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

# Check if Docker is available
if ! command -v docker &> /dev/null; then
  log_error "Docker is not installed or not in PATH"
  exit 1
fi

# Build image if it doesn't exist
IMAGE_NAME="ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest"
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
  log_info "Building Docker image..."
  docker build -t "$IMAGE_NAME" "$PROJECT_ROOT"
fi

# Set default values
API_KEY="${HESSIAN_API_KEY:-}"
PROFILE="${HESSIAN_PROFILE:-production}"
VOLUME_MOUNT=""
IMAGE_TAG="latest"

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
        --dev|-d)
            # Use development image if available
            if docker image inspect "$IMAGE_NAME-dev" &> /dev/null; then
                IMAGE_TAG="-dev"
            fi
            shift
            ;;
        --volume|-v)
            VOLUME_MOUNT="-v $2:/home/pluginuser/.config/pi"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --api-key KEY       Hessian.AI API key"
            echo "  --profile PROFILE   Profile: production, development, budget"
            echo "  --dev, -d           Use development image"
            echo "  --volume, -v PATH   Mount config volume"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Environment Variables:"
            echo "  HESSIAN_API_KEY     Hessian.AI API key"
            echo "  HESSIAN_PROFILE     Profile: production, development, budget"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Warn if no API key
if [[ -z "$API_KEY" ]]; then
  log_error "HESSIAN_API_KEY is not set!"
  log_info "Some features will not work without an API key."
  log_info "Set it with: export HESSIAN_API_KEY=your_key"
  log_info "Or use: --api-key your_key"
  read -rp "Continue anyway? [y/N] " -n 1 REPLY
  echo
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Run the container
log_info "Starting Hessian.AI Sandbox..."
log_info "Profile: $PROFILE"
if [[ -n "$API_KEY" ]]; then
  log_info "API Key: Set"
else
  log_info "API Key: Not set"
fi

exec docker run -it --rm \
  -e HESSIAN_API_KEY="$API_KEY" \
  -e HESSIAN_PROFILE="$PROFILE" \
  $VOLUME_MOUNT \
  "$IMAGE_NAME$IMAGE_TAG" sh
