# pi-hessian-plugin

> **Hessian.AI Integration for pi Coding Agent**
>
> *Seamless integration of Hessian.AI models (including TUD models) into the pi coding agent*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Image](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/pkgs/container/pi-hessian-plugin)](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/pkgs/container/pi-hessian-plugin)
[![GitHub Issues](https://img.shields.io/github/issues/tobias-weiss-ai-xr/pi-hessian-plugin.svg)](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/issues)
[![GitHub Stars](https://img.shields.io/github/stars/tobias-weiss-ai-xr/pi-hessian-plugin.svg)](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/stargazers)

---

## Overview

This plugin integrates **Hessian.AI** models into the **[pi coding agent](https://github.com/Earendil-Works/pi)**, providing seamless access to Hessian.AI's comprehensive model catalog. It includes specialized support for **TUD (Technische Universitat Darmstadt)** models, which are part of the Hessian.AI ecosystem.

Built with TypeScript and optimized for both local development and Docker-based deployments, this plugin offers automatic configuration generation, intelligent caching, and a flexible profile system.

---

## Features

### Core Capabilities

| Feature | Description |
|---------|-------------|
| **Model Access** | Access all Hessian.AI models, including TUD's specialized offerings |
| **Auto-Configuration** | Automatic generation and maintenance of pi configuration |
| **Profile System** | Pre-configured profiles: `production`, `development`, `budget` |
| **Intelligent Caching** | Model list caching with automatic 24-hour refresh |
| **Type Safety** | Fully typed TypeScript implementation |

### Technical Features

| Feature | Description |
|---------|-------------|
| **Multi-Architecture** | Docker images for `linux/amd64` and `linux/arm64` |
| **Small Footprint** | Production image ~50MB |
| **CI/CD Ready** | Automatic builds via GitHub Actions |
| **Command Interface** | Built-in pi commands for model management |
| **Showcase Mode** | Demonstration mode with built-in fallbacks |

---

## Supported Models

### TUD Models (Technische Universitat Darmstadt)

Hessian.AI includes the following specialized models from TUD:

| Model ID | Name | Description | Context Window | Output Window | Latency |
|----------|------|-------------|----------------|---------------|---------|
| `tud/mistral-medium-3.5-128b` | Mistral Medium 3.5 | High-performance mistral variant | 131,072 | 32,768 | Slow |
| `tud/gpt-oss-120b` | GPT-OSS 120B | Open-source GPT variant | 131,072 | 32,768 | Slow |
| `tud/qwen3.6-35b-a3b` | Qwen 3.6 | Alibaba's Qwen model | 16,384 | 2,048 | Moderate |
| `tud/gemma-4-31b-it` | Gemma 4 | Google's lightweight gemma | 32,768 | 8,192 | Moderate |
| `tud/ministral-3-14b-instruct` | Ministral 3 | Compact mistral variant | 8,192 | 2,048 | Fast |
| `tud/glm-5.2-awq` | GLM 5.2 | Quantized GLM model | 4,096 | 2,048 | Fast |
| `tud/qwen3-vl-30b-a3b` | Qwen 3-VL | Vision-capable model | 16,384 | 2,048 | Moderate |

### Hessian.AI Models

All models available through the Hessian.AI API are automatically discovered and configured:

- **Mistral Family**: mistral-7b, mixtral-8x7b, mistral-80b
- **Meta Llama**: llama-3-8b, llama-3-70b
- **Qwen**: qwen-7b, qwen-14b, qwen-72b
- **Google Gemma**: gemma-7b, gemma-2-9b
- And all future Hessian.AI models

---

## Quick Start

### Using Docker (Recommended)

```bash
# Pull the pre-built image
docker pull ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest

# Run with your API key
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

### Using Make

```bash
# Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin

# Start the sandbox
make sandbox
```

### Using npm

```bash
# Install globally
npm install -g tobias-weiss-ai-xr/pi-hessian-plugin

# Generate configuration
export HESSIAN_API_KEY="your-api-key"
pi-hessian-plugin generate
```

---

## Installation

### Option 1: Manual Installation

```bash
# 1. Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin

# 2. Install dependencies
npm install

# 3. Generate configuration
export HESSIAN_API_KEY="your-api-key"
npm run generate

# 4. Install plugin in pi
mkdir -p ~/.config/pi/plugins/hessian
cp pi-hessian.json ~/.config/pi/plugins/hessian/
cp src/*.ts ~/.config/pi/plugins/hessian/
```

### Option 2: Using the Setup Wizard

```bash
# Run the interactive setup
./src/setup-wizard.sh

# Follow the prompts to configure your API key and settings
```

### Option 3: Docker Installation

```bash
# Build the image
docker build -t ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest .

# Run with persistent configuration
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  -v $(pwd)/pi-config:/home/pluginuser/.config/pi \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

---

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `HESSIAN_API_KEY` | ✅ Yes | - | Your Hessian.AI API key |
| `HESSIAN_API_URL` | ❌ No | `https://api.hessian.ai/v1` | Hessian.AI API endpoint URL |
| `HESSIAN_PROFILE` | ❌ No | `production` | Profile: `production`, `development`, `budget` |

### Profiles

| Profile | Default Model | Use Case | Context Size |
|---------|---------------|----------|--------------|
| `production` | `tud/mistral-medium-3.5-128b` | Best performance, largest context | 131,072 |
| `development` | `tud/qwen3.6-35b-a3b` | Balanced performance and resources | 16,384 |
| `budget` | `tud/ministral-3-14b-instruct` | Fast, efficient for testing | 8,192 |

### pi.json Configuration

Add the following to your `~/.config/pi/pi.json`:

```json
{
  "plugin": ["hessian"],
  "model": "hessian/tud/qwen3.6-35b-a3b",
  "permission": {
    "bash": "allow",
    "edit": "allow",
    "read": "allow",
    "grep": "allow"
  }
}
```

The plugin will automatically generate a comprehensive configuration file with all available models.

---

## Usage

### In pi

Once installed, use these commands in pi:

| Command | Description |
|---------|-------------|
| `refresh-hessian-models` | Refresh the list of available Hessian.AI models |
| `list-hessian-models` | List all available Hessian.AI models with metadata |

Example:
```
> refresh-hessian-models
Hessian.AI models refreshed successfully

> list-hessian-models
**Hessian.AI Models (25 total):**

### TUD Models
- `tud/mistral-medium-3.5-128b`: Mistral Medium 3.5 128B
- `tud/gpt-oss-120b`: GPT-OSS 120B
...
```

### From Command Line

```bash
# Generate configuration
export HESSIAN_API_KEY="your-api-key"
npm run generate

# Validate configuration
npm run validate

# Copy configuration to pi directory
npm run copy
```

---

## Sandbox Environment

The sandbox provides a complete, isolated environment for testing and development.

### Available Commands

| Command | Description |
|---------|-------------|
| `make sandbox` | Start interactive sandbox |
| `make sandbox-dev` | Start development sandbox with live reloading |
| `make sandbox-test` | Run comprehensive test suite |
| `make sandbox-ascii` | Show ASCII art showcase |
| `make sandbox-joke` | Tell a programming joke |
| `make sandbox-story` | Generate a text adventure story |
| `make sandbox-wisdom` | Share programming wisdom |

### Showcase Mode

The showcase mode demonstrates the plugin's capabilities:

```bash
# ASCII art (works without API key)
./sandbox/showcase.sh ascii

# Programming joke (works without API key)
./sandbox/showcase.sh joke

# Wise advice (works without API key)
./sandbox/showcase.sh wisdom

# Story (requires API key)
export HESSIAN_API_KEY="your-api-key"
./sandbox/showcase.sh story

# Custom prompt (requires API key)
export HESSIAN_API_KEY="your-api-key"
./sandbox/showcase.sh custom "Write a Python function to sort a list"

# With specific model
export HESSIAN_API_KEY="your-api-key"
./sandbox/showcase.sh -m tud/qwen3.6-35b-a3b story
```

---

## Docker

### Build Images

```bash
# Production image (~50MB)
make build

# Development image (~200MB)
make build-dev

# Both images
make build-all
```

### Push to Registry

```bash
# Push production image
docker push ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest

# Push development image
docker push ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest-dev

# Push all images
make push-all
```

### Run Container

```bash
# Basic container
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh

# With configuration persistence
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  -v $(pwd)/pi-config:/home/pluginuser/.config/pi \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh

# With custom API URL
docker run -it --rm \
  -e HESSIAN_API_KEY="your-api-key" \
  -e HESSIAN_API_URL="https://custom-endpoint.example.com/v1" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

---

## Development

### Prerequisites

- Node.js 20.0.0 or higher
- Docker (optional)
- Hessian.AI API key (for testing)

### Setup

```bash
# Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin

# Install dependencies
npm install
```

### Commands

| Command | Description |
|---------|-------------|
| `npm run tsc` | TypeScript type checking |
| `npm run generate` | Generate configuration |
| `npm run validate` | Validate configuration |
| `npm run sandbox` | Start sandbox |
| `npm run docker` | Build Docker image |
| `npm run docker-push` | Push Docker image |

### Project Structure

```
pi-hessian-plugin/
├── src/
│   ├── hessian.ts           # Main plugin file
│   ├── hessian-memory.ts    # Caching and memory layer
│   ├── types.ts             # TypeScript type definitions
│   ├── generate-hessian-config.sh  # Configuration generator
│   ├── copy-hessian-config.sh      # Configuration copier
│   ├── validate-config.sh         # Configuration validator
│   └── setup-wizard.sh            # Interactive setup
├── sandbox/
│   ├── run.sh               # Interactive sandbox
│   ├── dev.sh               # Development sandbox
│   ├── test.sh              # Test suite
│   └── showcase.sh          # Showcase mode
├── schema/
│   └── placeholder.json     # Schema placeholder
├── Dockerfile               # Production Docker image
├── Dockerfile.dev           # Development Docker image
├── .github/workflows/
│   └── docker-build-push.yml # CI/CD pipeline
├── package.json             # Node.js configuration
├── tsconfig.json            # TypeScript configuration
├── Makefile                 # Convenience commands
└── README.md                # This file
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **API connection failed** | Verify `HESSIAN_API_KEY` and `HESSIAN_API_URL` |
| **No models available** | Check API endpoint and network connection |
| **Permission denied** | Run with proper user permissions or use `sudo` |
| **Docker build failed** | Ensure Docker is installed and running |
| **TypeScript errors** | Run `npm install` and `npm run tsc` |

### Debug Mode

```bash
# Enable verbose logging
export DEBUG=hessian:*
npm run generate

# Or in Docker
docker run -it --rm \
  -e DEBUG=hessian:* \
  -e HESSIAN_API_KEY="your-api-key" \
  ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin:latest sh
```

### Manual API Test

```bash
# Test API connectivity
curl -H "Authorization: Bearer your-api-key" \
  https://api.hessian.ai/v1/models | jq .

# Or with custom endpoint
curl -H "Authorization: Bearer your-api-key" \
  "$HESSIAN_API_URL/models" | jq .
```

---

## API Reference

### Environment Variables

```bash
# Required
HESSIAN_API_KEY="your-api-key"

# Optional
HESSIAN_API_URL="https://api.hessian.ai/v1"  # Default endpoint
HESSIAN_PROFILE="development"                # production, development, budget
```

### Plugin Commands

```bash
# In pi
refresh-hessian-models
list-hessian-models
```

### Showcase Commands

```bash
# Without API key
showcase.sh ascii
showcase.sh joke
showcase.sh wisdom

# With API key
showcase.sh story
showcase.sh riddle
showcase.sh custom "Your prompt here"
```

---

## Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Clone** your fork
3. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

### Contribution Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and well-described

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Hessian.AI** - For providing the AI infrastructure
- **TUD (Technische Universitat Darmstadt)** - For specialized models
- **pi Coding Agent** - For the excellent agent framework
- **All Contributors** - For their valuable contributions

---

## Contact

For questions, issues, or suggestions:

- **GitHub Issues**: [https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/issues](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin/issues)
- **Repository**: [https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin)

---

<p align="center">
  Built with ❤️ for the Hessian.AI community
</p>

<p align="center">
  <a href="https://hessian.ai">Hessian.AI</a> • 
  <a href="https://github.com/Earendil-Works/pi">pi Coding Agent</a> • 
  <a href="https://www.tu-darmstadt.de">TU Darmstadt</a>
</p>
