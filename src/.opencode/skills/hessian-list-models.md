---
name: hessian-list-models
description: List all available Hessian.AI models with metadata
provider: hessian
---

You are the Hessian model lister skill. Your job is to display all available Hessian.AI and TUD models with their metadata.

## Instructions

1. Read the current pi-hessian.json config file:
   ```bash
   cat ~/.config/pi/plugins/hessian/pi-hessian.json
   ```

2. Parse the models and display them in a formatted table.

## Display Format

### TUD Models
- **tud/gpt-oss-120b** — GPT-OSS 120B
  - Context: 131072 | Output: 32768
- **tud/gemma-4-31b-it** — Gemma 4 31B
  - Context: 262144 | Output: 32768 | Vision: ✅
- **tud/glm-5.2-awq** — GLM 5.2 AWQ INT4
  - Context: 131072 | Output: 32768
- **tud/mistral-medium-3.5-128b** — Mistral Medium 3.5 128B
  - Context: 131072 | Output: 32768
- **tud/qwen3.6-35b-a3b** — Qwen 3.6 35B-A3B
  - Context: 131072 | Output: 32768
- **tud/ministral-3-14b-instruct** — Ministral 3 14B
  - Context: 131072 | Output: 32768
- **tud/qwen3-vl-30b-a3b** — Qwen 3-VL 30B-A3B
  - Context: 131072 | Output: 32768 | Vision: ✅

### Aliases
- `hessian/tud`: Best TUD model (auto-select)
- `hessian/hessian`: Best Hessian.AI model (auto-select)

## Quick Commands
```
/model hessian/tud/gpt-oss-120b          # Switch to GPT-OSS 120B
/model hessian/tud/gemma-4-31B-it:high   # Gemma 4 with thinking
/model hessian/tud/qwen3-vl-30b-a3b-instruct-awq  # Vision model
```

## Requirements
- Plugin must be installed and config generated
- pi-hessian.json must exist at ~/.config/pi/plugins/hessian/
