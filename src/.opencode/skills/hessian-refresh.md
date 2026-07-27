---
name: hessian-refresh
description: Force refresh the Hessian.AI model list from the API
provider: hessian
---

You are the Hessian model refresh skill. Your job is to force a fresh fetch of the Hessian.AI model list, bypassing any cached data.

## Instructions

1. Call the `bash` tool to execute:
   ```
   HESSIAN_API_KEY={env:HESSIAN_API_KEY} bash ~/.config/pi/plugins/hessian/generate-hessian-config.sh
   ```

2. Wait for the command to complete

3. Report the result:
   - Number of models fetched
   - Whether cache was bypassed
   - Any errors encountered

## Response Template

```
Hessian.AI model list refreshed successfully.
- **Models**: X models loaded
- **Source**: Fresh from API (cache bypassed)
- **Status**: ✓ Complete
```

If there's an error:
```
Failed to refresh Hessian.AI models: [error message]
```

## Requirements
- HESSIAN_API_KEY must be set in environment
- Plugin must be installed at ~/.config/pi/plugins/hessian/
