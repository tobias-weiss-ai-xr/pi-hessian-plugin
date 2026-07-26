# pi-hessian-plugin

**Hessian.AI Integration for pi Coding Agent**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/pkgs/container/pi-hessian-plugin)
[![GitHub Issues](https://img.shields.io/github/issues/tobias-weiss-ai-xr/pi-hessian-plugin.svg)](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/issues)

This plugin integrates [Hessian.AI](https://hessian.ai) models into the [pi coding agent](https://github.com/Earendil-Works/pi), providing seamless access to Hessian.AI's model catalog, including TUD (Technische Universitaet Darmstadt) specialized models.

## Features

- **Full Hessian.AI Model Support** – Access all available models including TUD's specialized offerings
- **Automatic Configuration** – Generates and maintains pi configuration automatically
- **Profile System** – Switch between production, development, and budget profiles
- **Caching** – Efficient model list caching with automatic refresh (24h TTL)
- **Type-Safe** – Fully typed TypeScript implementation
- **Docker Ready** – Pre-configured Docker images for easy deployment
- **Command Interface** – Built-in commands for model management
- **Showcase Mode** – Demonstrate pi's capabilities with Hessian.AI models

## Supported Models

### TUD Models (Technische Universitaet Darmstadt)
Hessian.AI includes specialized models from TUD:

| Model ID | Description | Context Window |
|----------|-------------|----------------|
| `tud/glm-5.2-awq` | GLM 5.2 AWQ INT4 | 131,072 |
| `tud/gpt-oss-120b` | GPT-OSS 120B | 131,072 |
| `tud/gemma-4-31b-it` | Gemma 4 31B | 32,768 |
| `tud/mistral-medium-3.5-128b` | Mistral Medium 3.5 128B | 131,072 |
| `tud/qwen3.6-35b-a3b` | Qwen 3.6 35B-A3B | 16,384 |
| `tud/ministral-3-14b-instruct` | Ministral 3 14B | 8,192 |
| `tud/qwen3-vl-30b-a3b` | Qwen 3-VL 30B-A3B (Vision) | 16,384 |

### Hessian.AI Models
All models available through the [Hessian.AI API](https://api.hessian.ai/v1/models) are automatically included:
- Mistral family models
- Llama 3 models
- Qwen models
- Gemma models
- And more...

## Installation

### Option 1: Manual Installation

```bash
# Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin

# Install dependencies
npm install

# Generate configuration (requires API key)
export HESSIAN_API_KEY="your-api-key"
npm run generate

# Copy to pi plugins directory
mkdir -p ~/.config/pi/plugins/hessian
cp pi-hessian.json ~/.config/pi/plugins/hessian/
cp src/*.ts ~/.config/pi/plugins/hessian/
```

### Option 2: Using Docker (Recommended)

```bash
# Pull the pre-built image
docker pull ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest

# Run with your API key
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  -v $(pwd)/pi-config:/home/pluginuser/.config/pi \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

### Option 3: Using Make

```bash
# Clone and build
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin

# Build and run sandbox
make sandbox
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `HESSIAN_API_KEY` | ✅ Yes | - | Your Hessian.AI API key |
| `HESSIAN_PROFILE` | ❌ No | `production` | Profile: `production`, `development`, or `budget` |
| `LITELLM_PROXY_URL` | ❌ No | - | Optional: Custom LiteLLM proxy URL |

### Profiles

| Profile | Default Model | Use Case |
|---------|---------------|----------|
| `production` | `tud/mistral-medium-3.5-128b` | Best performance, largest context windows |
| `development` | `tud/qwen3.6-35b-a3b` | Balanced performance and resource usage |
| `budget` | `tud/ministral-3-14b-instruct` | Fast, efficient for testing and development |

## Usage

### Generate Configuration

```bash
# Set your API key
export HESSIAN_API_KEY="your-api-key"

# Generate configuration
npm run generate

# Or use the command directly
./src/generate-hessian-config.sh
```

### Refresh Models

```bash
# Refresh the model list
npx pi-hessian-plugin refresh
```

### List Models

```bash
docker run --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest \
  bash -c "node -p 'require(\"./src/hessian.ts\")'"