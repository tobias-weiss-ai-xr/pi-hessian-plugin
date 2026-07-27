# pi-hessian-plugin
> **⚠️ Migrated from Codeberg → GitHub**: This repository has moved permanently to [GitHub](https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin). The Codeberg mirror is deprecated.


> Hessian (TUD / TU Darmstadt LLM Service) provider for the [pi coding agent](https://pi.dev)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pi Package](https://img.shields.io/badge/pi-package-blue)](https://pi.dev/packages)

A [pi package](https://pi.dev/docs/packages) that auto-registers all **Hessian TUD LLM Service** models as a provider — no manual configuration needed.

Following the same pattern as [pi-saia-plugin](https://github.com/tobias-weiss-ai-xr/pi-saia-plugin) and [pi-memory](https://github.com/tobias-weiss-ai-xr/pi-memory): an extension registers the provider via `pi.registerProvider()`, and a skill documents usage. See the [agent-memory-research](https://github.com/tobias-weiss-ai-xr/agent-memory-research) survey [[arXiv 2512.13564](https://arxiv.org/abs/2512.13564)] for the research foundation behind our memory architecture.

## Features

- **Auto-registration** — `pi.registerProvider()` adds all 7 TUD models on startup
- **Zero config** — API key from `auth.json`, `$TUD_API_KEY` env var, or `/login tud`
- **Skill included** — `/skill:hessian-models` documents available models and usage
- **OpenAI-compatible** — Uses standard `openai-completions` API
- **Vision support** — Gemma 4 31B and Qwen 3 VL handle image inputs

## Installation

```bash
# From git (recommended)
pi install git:github.com/tobias-weiss-ai-xr/pi-hessian-plugin

# Or local
pi install /path/to/pi-hessian-plugin
```

Then reload or restart pi:

```bash
/reload
```

## Available Models

| Model ID | Name | Context | Vision | Reasoning |
|----------|------|---------|--------|-----------|
| `tud/gpt-oss-120b` | GPT-OSS 120B | 128K | — | ✅ |
| `tud/gemma-4-31B-it` | Gemma 4 31B IT | 256K | ✅ | ✅ |
| `tud/GLM-5.2-AWQ-INT4` | GLM 5.2 AWQ INT4 | 128K | — | ✅ |
| `tud/Mistral-Medium-3.5-128B` | Mistral Medium 3.5 128B | 128K | — | ✅ |
| `tud/Qwen3.6-35B-A3B` | Qwen 3.6 35B A3B | 128K | — | ✅ |
| `tud/Ministral-3-14B-Instruct-2512` | Ministral 3 14B | 128K | — | ✅ |
| `tud/qwen3-vl-30b-a3b-instruct-awq` | Qwen 3 VL 30B | 128K | ✅ | ✅ |

## Usage

```bash
# List available models
pi --list-models | grep ^tud

# Switch to a model
/model tud/gpt-oss-120b

# With thinking level
/model tud/gemma-4-31B-it:high

# Vision model for images
/model tud/qwen3-vl-30b-a3b-instruct-awq

# Fast lightweight model
/model tud/Ministral-3-14B-Instruct-2512

# Load the skill for documentation
/skill:hessian-models
```

## API Key

The API key is resolved from (in order):

1. `auth.json` — `"tud": { "type": "api_key", "key": "..." }`
2. `$TUD_API_KEY` environment variable
3. `/login tud` interactive prompt

## Package Structure

```
pi-hessian-plugin/
├── package.json          # Pi package manifest
├── extensions/
│   └── index.ts          # Provider registration via registerProvider()
└── skills/
    └── hessian-models.md # Model documentation skill
```

## Architecture

This plugin follows the same pi package pattern established by [pi-memory](https://github.com/tobias-weiss-ai-xr/pi-memory):

- **Extension** (`extensions/index.ts`): Calls `pi.registerProvider()` during startup to dynamically register the `tud` provider and its models. The extension factory is synchronous — models are static, so no async fetch is needed.
- **Skill** (`skills/hessian-models.md`): Provides user-facing documentation of available models, usage examples, and API key setup instructions.
- **package.json**: Declares `peerDependencies` for pi SDK types, and a `pi` manifest that points to extensions and skills directories.

No shell scripts, no Docker, no sandbox — just a self-contained pi package.

## Development

```bash
git clone https://github.com/tobias-weiss-ai-xr/pi-hessian-plugin.git
cd pi-hessian-plugin
npm install
```

Test locally:

```bash
pi install /path/to/pi-hessian-plugin
pi --list-models | grep ^tud
```

## License

MIT
