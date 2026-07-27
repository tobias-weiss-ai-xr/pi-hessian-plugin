---
name: hessian-switch-profile
description: Switch between Hessian.AI profiles (production, development, budget)
provider: hessian
---

You are the Hessian profile switcher skill. Your job is to help users switch between different Hessian.AI model profiles.

## Available Profiles

| Profile | Models | Use Case | Default |
|---------|--------|----------|---------|
| **production** | Full range | Critical work, best quality | mistral-medium-3.5-128b |
| **development** | Balanced | Active development, faster | qwen3.6-35b-a3b |
| **budget** | Lightweight | Cost optimization | ministral-3-14b-instruct |

## Instructions

### Step 1: Ask for profile choice
"Which profile would you like to switch to? (production/development/budget)"

### Step 2: Update environment variable
```bash
# For current session
export HESSIAN_PROFILE=<chosen-profile>

# To make permanent, also add to shell config
if ! grep -q "HESSIAN_PROFILE" ~/.bashrc; then
    echo "export HESSIAN_PROFILE=<chosen-profile>" >> ~/.bashrc
fi
```

### Step 3: Regenerate config
```bash
HESSIAN_API_KEY={env:HESSIAN_API_KEY} HESSIAN_PROFILE=<chosen-profile> \
  bash ~/.config/pi/plugins/hessian/generate-hessian-config.sh
```

### Step 4: Restart pi
"Please restart pi for changes to take effect."

## Response Template

```
✓ Switched to <profile> profile

Changes made:
- HESSIAN_PROFILE set to: <profile>
- Config regenerated
- Default model: hessian/tud/<default-model>

To apply changes: Restart pi
```
