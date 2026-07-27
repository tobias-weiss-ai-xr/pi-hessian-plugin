#!/bin/bash
set -e

if [ -z "$HESSIAN_API_KEY" ]; then
  echo "Error: HESSIAN_API_KEY is not set."
  echo "Get your key from https://llm-service.ai.tu-darmstadt.de then run:"
  echo "  export HESSIAN_API_KEY=your_key_here"
  exit 1
fi

# PI config directory
PI_CONFIG_DIR="${HOME}/.config/pi"
PLUGIN_DIR="${PI_CONFIG_DIR}/plugins/hessian"

# Create directories
mkdir -p "$PLUGIN_DIR"

# Copy plugin files
cp -r src/* "$PLUGIN_DIR/"
chmod +x "$PLUGIN_DIR"/*.sh 2>/dev/null || true

# Create pi.json if it doesn't exist
PI_CONFIG="${PI_CONFIG_DIR}/pi.json"
if [ ! -f "$PI_CONFIG" ]; then
  mkdir -p "$(dirname "$PI_CONFIG")"
  cat > "$PI_CONFIG" <<'EOF'
{
  "$schema": "https://pi.code/config.json",
  "plugin": ["hessian"]
}
EOF
   echo "✓ Created $PI_CONFIG with plugin registration"
 else
   echo "⚠ Config exists at $PI_CONFIG"
   echo "  Add 'plugin' registration if not already present:"
   echo '  "plugin": ["hessian"]'
 fi

echo ""
echo "✓ Plugin installed to $PLUGIN_DIR"
echo "  pi will automatically load Hessian.AI models on startup"
echo ""
echo "To test: run pi and use /model tud/<model-name>"
echo "Example: /model tud/mistral-medium-3.5-128b"
