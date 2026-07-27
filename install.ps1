# pi Hessian.AI Plugin Installer for Windows PowerShell

if (-not (Test-Path env:HESSIAN_API_KEY)) {
    Write-Error "HESSIAN_API_KEY environment variable not set"
    Write-Host "Get your key from https://llm-service.ai.tu-darmstadt.de then run:"
    Write-Host "  [Environment]::SetEnvironmentVariable('HESSIAN_API_KEY', 'your_key_here', 'User')"
    exit 1
}

# PI config directory
$piConfigDir = Join-Path $HOME ".config\pi"
$pluginDir = Join-Path $piConfigDir "plugins\hessian"

# Create directories
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
}

# Copy plugin files
Copy-Item -Path "src\*" -Destination $pluginDir -Recurse -Force

# Make shell scripts executable (Unix-like systems via WSL)
Get-ChildItem -Path "$pluginDir\*.sh" | ForEach-Object {
    try {
        Invoke-Expression "chmod +x '$($_.FullName)'"
    } catch {
        # Ignore on native Windows
    }
}

# Create pi.json if it doesn't exist
$piConfig = Join-Path $piConfigDir "pi.json"
if (-not (Test-Path $piConfig)) {
    @{
        `$schema = "https://pi.code/config.json"
        plugin = @("hessian")
    } | ConvertTo-Json | Out-File -FilePath $piConfig -Encoding UTF8
    Write-Host "✓ Created $piConfig with plugin registration"
} else {
    Write-Host "⚠ Config exists at $piConfig"
    Write-Host "  Add plugin registration if not already present:"
    Write-Host '  "plugin": ["hessian"]'
}

Write-Host "`n✓ Plugin installed to $pluginDir"
Write-Host "  pi will automatically load Hessian.AI models on startup"
Write-Host "`nTo test: run pi and use /model tud/<model-name>"
Write-Host "Example: /model tud/mistral-medium-3.5-128b"
