---
name: hessian-health
description: Check the health status of the Hessian.AI API and plugin
provider: hessian
---

You are the Hessian health check skill. Your job is to verify that:
1. The Hessian.AI API is accessible
2. The API key is valid
3. The plugin is properly configured

## Instructions

1. **API Connectivity Test**:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" \
     "https://api.hessian.ai/v1/models" \
     -H "Authorization: Bearer {env:HESSIAN_API_KEY}"
   ```

2. **Plugin Installation Check**:
   ```bash
   ls ~/.config/pi/plugins/hessian/hessian.ts
   ```

3. **Config File Check**:
   ```bash
   ls -la ~/.config/pi/plugins/hessian/pi-hessian.json
   ```

4. **PI Config Check**:
   ```bash
   grep -q '"hessian"' ~/.config/pi/pi.json && echo "Plugin registered" || echo "Plugin NOT registered"
   ```

## Health Status Report

- **API Status**: ✓ Reachable | ✗ Unreachable
- **API Key**: ✓ Valid | ✗ Invalid/Expired
- **Plugin Files**: ✓ Installed | ✗ Missing
- **Model Config**: ✓ Present (X models) | ✗ Missing
- **PI Registration**: ✓ Registered | ✗ Not registered

## Troubleshooting

- API unreachable: Check network, firewall, or Hessian.AI server status
- Invalid key: Verify HESSIAN_API_KEY value
- Plugin missing: Re-run the install script
- Config missing: Run generate-hessian-config.sh
- Not registered: Add "hessian" to plugin array in pi.json
