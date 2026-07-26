# Hessian.AI Sandbox

Docker-based sandbox environment for testing and developing the Hessian.AI plugin for pi coding agent.

## Quick Start

### 1. Build the Docker Image

```bash
# From the project root
docker build -t ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest .

# Or pull the pre-built image
docker pull ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest
```

### 2. Run the Sandbox

```bash
# Basic sandbox
docker run -it --rm \
  -e HESSIAN_API_KEY="your_api_key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh

# With your API key
HESSIAN_API_KEY=your_key docker run -it --rm \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh

# With volume mount for config persistence
docker run -it --rm \
  -e HESSIAN_API_KEY="your_api_key" \
  -v $(pwd)/pi-config:/home/pluginuser/.config/pi \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

### 3. Run Specific Commands

```bash
# Generate configuration
docker run -it --rm \
  -e HESSIAN_API_KEY="your_api_key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest \
  bash src/generate-hessian-config.sh

# Run TypeScript check
docker run -it --rm \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest \
  npm run tsc
```

## Available Images

| Image Tag | Description | Size |
|-----------|-------------|------|
| `latest` | Production-ready image | ~50MB |
| `X.Y.Z` | Version-specific image | ~50MB |

## Usage Examples

### Basic Shell
```bash
./sandbox/run.sh
```

### Development Mode
```bash
./sandbox/dev.sh
```

### Run Tests
```bash
./sandbox/test.sh
```

### Showcase Mode
```bash
# ASCII art (works without API key)
./sandbox/showcase.sh ascii

# Generate story (requires API key)
HESSIAN_API_KEY=your_key ./sandbox/showcase.sh story

# Tell a joke
HESSIAN_API_KEY=your_key ./sandbox/showcase.sh joke
```

## Configuration

The sandbox automatically configures pi with Hessian.AI support:

- Plugin directory: `~/.config/pi/plugins/hessian/`
- Configuration: `~/.config/pi/plugins/hessian/pi-hessian.json`
- Models: All Hessian.AI and TUD models

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `HESSIAN_API_KEY` | Your Hessian.AI API key | ✅ Yes |
| `HESSIAN_PROFILE` | Profile: production, development, budget | ❌ No |
| `LITELLM_PROXY_URL` | Optional: Custom LiteLLM proxy | ❌ No |
