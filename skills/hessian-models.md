---
description: Hessian (TUD/TU Darmstadt) models available via this plugin.
---

# Hessian TUD LLM Service Models

This plugin registers the TUD provider with 7 models hosted at TU Darmstadt's LLM service.

## Available Models

| Model ID | Name | Context | Vision | Reasoning |
|----------|------|---------|--------|-----------|
| `tud/gpt-oss-120b` | GPT-OSS 120B | 128K | — | ✅ |
| `tud/gemma-4-31B-it` | Gemma 4 31B IT | 256K | ✅ | ✅ |
| `tud/GLM-5.2-AWQ-INT4` | GLM 5.2 AWQ INT4 | 128K | — | ✅ |
| `tud/Mistral-Medium-3.5-128B` | Mistral Medium 3.5 | 128K | — | ✅ |
| `tud/Qwen3.6-35B-A3B` | Qwen 3.6 35B A3B | 128K | — | ✅ |
| `tud/Ministral-3-14B-Instruct-2512` | Ministral 3 14B | 128K | — | ✅ |
| `tud/qwen3-vl-30b-a3b-instruct-awq` | Qwen 3 VL 30B | 128K | ✅ | ✅ |

## Usage

```bash
# Switch to a TUD model
/model tud/gpt-oss-120b

# Gemma 4 with thinking
/model tud/gemma-4-31B-it:high

# Vision model for images
/model tud/qwen3-vl-30b-a3b-instruct-awq

# Fast lightweight model
/model tud/Ministral-3-14B-Instruct-2512
```

## API Key

The API key is resolved from `auth.json` (`tud` key), `models.json` provider config, or `$TUD_API_KEY` environment variable.

Set it via:
```bash
/login tud
```

Or add to `auth.json`:
```json
{
  "tud": { "type": "api_key", "key": "your-key" }
}
```
