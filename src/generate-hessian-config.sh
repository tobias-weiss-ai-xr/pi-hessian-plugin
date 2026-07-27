#!/usr/bin/env bash
set -euo pipefail

# Hessian.AI Configuration Generator for pi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

# ============= HELPER FUNCTIONS =============
get_default_model() {
  case "$1" in
    production) echo "tud/mistral-medium-3.5-128b" ;;
    budget)     echo "tud/ministral-3-14b-instruct" ;;
    *)          echo "tud/qwen3.6-35b-a3b" ;;
  esac
}

get_model_description() {
  local id="$1"
  case "$id" in
    tud/glm-5.2-awq)               echo "GLM 5.2 AWQ INT4" ;;
    tud/gpt-oss-120b)              echo "GPT-OSS 120B" ;;
    tud/gemma-4-31b-it)            echo "Gemma 4 31B" ;;
    tud/mistral-medium-3.5-128b)   echo "Mistral Medium 3.5 128B" ;;
    tud/qwen3.6-35b-a3b)           echo "Qwen 3.6 35B-A3B" ;;
    tud/ministral-3-14b-instruct)  echo "Ministral 3 14B" ;;
    tud/qwen3-vl-30b-a3b)          echo "Qwen 3-VL 30B-A3B" ;;
    mistral-7b)                    echo "Mistral 7B" ;;
    mixtral-8x7b)                  echo "Mixtral 8x7B" ;;
    mistral-80b)                   echo "Mistral 80B" ;;
    llama-3-8b)                    echo "Llama 3 8B Instruct" ;;
    llama-3-70b)                   echo "Llama 3 70B Instruct" ;;
    *)                             echo "$id" ;;
  esac
}

categorize_model() {
  local id="$1"
  if [[ "$id" == tud/* ]]; then
    if [[ "$id" == *vl* || "$id" == *vision* ]]; then
      echo "tud-vision"
    else
      echo "tud"
    fi
  elif [[ "$id" == *mistral* || "$id" == *mixtral* ]]; then
    echo "mistral"
  elif [[ "$id" == *llama* ]]; then
    echo "meta"
  elif [[ "$id" == *qwen* ]]; then
    echo "qwen"
  elif [[ "$id" == *gemma* ]]; then
    echo "google"
  else
    echo "general"
  fi
}

get_context_window() {
  local id="$1"
  if [[ "$id" == *128b* || "$id" == *120b* ]]; then echo 131072
  elif [[ "$id" == *70b* || "$id" == *80b* ]]; then echo 32768
  elif [[ "$id" == *35b* || "$id" == *30b* ]]; then echo 16384
  elif [[ "$id" == *14b* ]]; then echo 8192
  else echo 4096
  fi
}

get_output_window() {
  local id="$1"
  if [[ "$id" == *128b* || "$id" == *120b* ]]; then echo 32768
  elif [[ "$id" == *70b* || "$id" == *80b* ]]; then echo 8192
  else echo 2048
  fi
}

get_latency() {
  local id="$1"
  if [[ "$id" == *7b* ]]; then echo "fast"
  elif [[ "$id" == *14b* ]]; then echo "moderate"
  elif [[ "$id" == *70b* || "$id" == *80b* || "$id" == *128b* ]]; then echo "slow"
  else echo "moderate"
  fi
}

can_reason() {
  local id="$1"
  [[ "$id" == *80b* || "$id" == *70b* || "$id" == *mixtral* || "$id" == *llama-3-70b* || "$id" == *llama-3-8b* ]]
}

# ============= MAIN EXECUTION =============
# Check for API key
HESSIAN_API_KEY="${HESSIAN_API_KEY:-}"

if [[ -z "$HESSIAN_API_KEY" ]]; then
  log_error "HESSIAN_API_KEY environment variable is not set."
  log_info "Please set it before running this script:"
  log_info "  export HESSIAN_API_KEY=\"your-api-key-here\""
  exit 1
fi

# Profile
HESSIAN_PROFILE="${HESSIAN_PROFILE:-production}"
log_info "Using profile: $HESSIAN_PROFILE"

# API endpoint
API_ENDPOINT="https://api.hessian.ai/v1"

log_info "Fetching models from Hessian.AI..."
FETCH_START=$(date +%s)

MODELS_JSON=$(curl -s --max-time 30 "${API_ENDPOINT}/models" \
  -H "Authorization: Bearer $HESSIAN_API_KEY" 2>/dev/null)

FETCH_END=$(date +%s)
FETCH_ELAPSED=$((FETCH_END - FETCH_START))

if [[ -z "$MODELS_JSON" ]] || ! echo "$MODELS_JSON" | jq -e '.data' >/dev/null 2>&1; then
  log_error "Failed to fetch models from Hessian.AI API"
  log_error "Endpoint: $API_ENDPOINT"
  exit 1
fi

log_info "Fetched $(echo "$MODELS_JSON" | jq '.data | length') models in ${FETCH_ELAPSED}s"

# TUD models (static, part of Hessian.AI)
TUD_MODELS=(
  "tud/glm-5.2-awq"
  "tud/gpt-oss-120b"
  "tud/gemma-4-31b-it"
  "tud/mistral-medium-3.5-128b"
  "tud/qwen3.6-35b-a3b"
  "tud/ministral-3-14b-instruct"
  "tud/qwen3-vl-30b-a3b"
)

# Create pi.json
OUTPUT_FILE="${1:-$PROJECT_ROOT/pi-hessian.json}"

log_info "Generating configuration: $OUTPUT_FILE"

# Use jq to construct the JSON (more reliable than string concatenation)
jq -n \
  --arg endpoint "$API_ENDPOINT" \
  --arg api_key_env "{env:HESSIAN_API_KEY}" \
  --arg default_model "$(get_default_model "$HESSIAN_PROFILE")" \
  '{
    "$schema": "https://pi.code/config.json",
    "permission": {
      "bash": "allow", "edit": "allow", "read": "allow", "grep": "allow",
      "glob": "allow", "lsp": "allow", "skill": "allow", "task": "allow",
      "webfetch": "allow", "websearch": "allow", "question": "allow",
      "external_directory": "ask", "doom_loop": "ask"
    },
    "model": ("hessian/" + $default_model),
    "provider": {
      "hessian": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Hessian.AI",
        "options": {
          "baseURL": $endpoint,
          "apiKey": $api_key_env
        },
        "models": {}
      }
    }
  }' > "$OUTPUT_FILE.tmp"

# Add models from API
echo "$MODELS_JSON" | jq '.data[] | .id' | while read -r model_id; do
  # Skip if already added (unlikely but possible)
  if ! jq -e --arg id "$model_id" '.provider.hessian.models | has($id)' "$OUTPUT_FILE.tmp" >/dev/null 2>&1; then
    description=$(get_model_description "$model_id")
    category=$(categorize_model "$model_id")
    context=$(get_context_window "$model_id")
    output=$(get_output_window "$model_id")
    latency=$(get_latency "$model_id")
    can_reason=$(can_reason "$model_id" && echo "true" || echo "false")

    jq --arg id "$model_id" \
       --arg name "$description" \
       --arg cat "$category" \
       --argjson ctx "$context" \
       --argjson out "$output" \
       --arg lat "$latency" \
       --argjson reason "$can_reason" \
       '.provider.hessian.models[$id] = {
         "name": $name,
         "category": $cat,
         "limit": {"context": $ctx, "output": $out},
         "metadata": {"estimated_latency": $lat},
         "can_reason": $reason
       }' "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE.tmp.new" && mv "$OUTPUT_FILE.tmp.new" "$OUTPUT_FILE.tmp"
  fi
done

# Add TUD models
for model_id in "${TUD_MODELS[@]}"; do
  if ! jq -e --arg id "$model_id" '.provider.hessian.models | has($id)' "$OUTPUT_FILE.tmp" >/dev/null 2>&1; then
    description=$(get_model_description "$model_id")
    category="tud"
    context=$(get_context_window "$model_id")
    output=$(get_output_window "$model_id")
    latency=$(get_latency "$model_id")
    can_reason=$(can_reason "$model_id" && echo "true" || echo "false")

    jq --arg id "$model_id" \
       --arg name "$description" \
       --arg cat "$category" \
       --argjson ctx "$context" \
       --argjson out "$output" \
       --arg lat "$latency" \
       --argjson reason "$can_reason" \
       '.provider.hessian.models[$id] = {
         "name": $name,
         "category": $cat,
         "limit": {"context": $ctx, "output": $out},
         "metadata": {"estimated_latency": $lat},
         "can_reason": $reason
       }' "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE.tmp.new" && mv "$OUTPUT_FILE.tmp.new" "$OUTPUT_FILE.tmp"
  fi
done

# Add aliases
jq '.provider.hessian.models += {
  "tud": {"name": "Best TUD model", "category": "alias", "limit": {"context": 0, "output": 0}, "metadata": {"estimated_latency": "fast"}, "alias": true},
  "hessian": {"name": "Best Hessian.AI model", "category": "alias", "limit": {"context": 0, "output": 0}, "metadata": {"estimated_latency": "fast"}, "alias": true}
}' "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE.tmp.new" && mv "$OUTPUT_FILE.tmp.new" "$OUTPUT_FILE.tmp"

# Finalize
mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
log_info "Configuration generated successfully: $OUTPUT_FILE"


