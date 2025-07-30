# Windows PowerShell script for installing Claude Code with Lanyun settings
# Requires Administrator privileges for environment variable settings

# Set error action preference
$ErrorActionPreference = "Stop"

function Install-NodeJS {
    Write-Host "🚀 Installing Node.js on Windows..." -ForegroundColor Green
    
    # Download Node.js installer (v22 LTS)
    $nodeVersion = "22.17.0"
    $nodeUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-x64.msi"
    $installerPath = "$env:TEMP\nodejs.msi"
    
    Write-Host "📥 Downloading Node.js v$nodeVersion..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
    } catch {
        Write-Host "❌ Failed to download Node.js: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📦 Installing Node.js..." -ForegroundColor Yellow
    try {
        Start-Process msiexec.exe -Wait -ArgumentList "/i", $installerPath, "/quiet", "/qn", "/norestart"
        Remove-Item $installerPath -Force
    } catch {
        Write-Host "❌ Failed to install Node.js: $_" -ForegroundColor Red
        exit 1
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ Node.js installation completed!" -ForegroundColor Green
}

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  This script requires Administrator privileges to set system environment variables." -ForegroundColor Yellow
    Write-Host "⚠️  Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or use the following command in an elevated PowerShell:" -ForegroundColor Cyan
    Write-Host "iwr -useb https://raw.githubusercontent.com/LanyunAI-labs/lanyun-cc/main/install_lanyun.ps1 | iex" -ForegroundColor White
    exit 1
}

# Check if Node.js is already installed
try {
    $nodeVersion = & node -v 2>$null
    if ($nodeVersion) {
        $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        if ($majorVersion -ge 18) {
            Write-Host "Node.js is already installed: $nodeVersion" -ForegroundColor Green
        } else {
            Write-Host "Node.js $nodeVersion is installed but version < 18. Upgrading..." -ForegroundColor Yellow
            Install-NodeJS
        }
    }
} catch {
    Write-Host "Node.js not found. Installing..." -ForegroundColor Yellow
    Install-NodeJS
}

# Refresh PATH again to ensure npm is available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Check if Claude Code is already installed
try {
    $claudeVersion = & claude --version 2>$null
    if ($claudeVersion) {
        Write-Host "Claude Code is already installed: $claudeVersion" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "Claude Code not found. Installing..." -ForegroundColor Yellow
    try {
        & npm install -g @anthropic-ai/claude-code
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed"
        }
    } catch {
        Write-Host "❌ Failed to install Claude Code: $_" -ForegroundColor Red
        exit 1
    }
}

# Configure Claude Code to skip onboarding
Write-Host "Configuring Claude Code to skip onboarding..." -ForegroundColor Yellow
$claudeConfigPath = "$env:USERPROFILE\.claude.json"
try {
    if (Test-Path $claudeConfigPath) {
        $config = Get-Content $claudeConfigPath | ConvertFrom-Json
        $config.hasCompletedOnboarding = $true
        $config | ConvertTo-Json | Set-Content $claudeConfigPath -Encoding UTF8
    } else {
        @{ hasCompletedOnboarding = $true } | ConvertTo-Json | Set-Content $claudeConfigPath -Encoding UTF8
    }
} catch {
    Write-Host "⚠️  Warning: Could not configure Claude Code settings: $_" -ForegroundColor Yellow
}

# Prompt user for API key
Write-Host ""
Write-Host "🔑 Please enter your lanyun API key:" -ForegroundColor Cyan
Write-Host "🔑 请输入您的蓝云 API 密钥：" -ForegroundColor Cyan
Write-Host "   You can get your API key from: https://maas.lanyun.net/" -ForegroundColor Gray
Write-Host "   您可以从这里获取 API 密钥：https://maas.lanyun.net/" -ForegroundColor Gray
Write-Host ""

$apiKey = Read-Host -AsSecureString "API Key"
$apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))

if ([string]::IsNullOrWhiteSpace($apiKeyPlain)) {
    Write-Host "⚠️  API key cannot be empty. Please run the script again." -ForegroundColor Red
    exit 1
}

# Prompt user for model
Write-Host ""
Write-Host "🤖 Please enter the Claude model to use (press Enter for default 'k2'):" -ForegroundColor Cyan
Write-Host "🤖 请输入要使用的 Claude 模型（按回车使用默认值 'k2'）：" -ForegroundColor Cyan
Write-Host ""

$model = Read-Host "Model"
if ([string]::IsNullOrWhiteSpace($model)) {
    $model = "k2"
    Write-Host "ℹ️  Using default model: k2" -ForegroundColor Blue
}

# Set environment variables
Write-Host ""
Write-Host "📝 Setting system environment variables..." -ForegroundColor Yellow

try {
    # Set system environment variables (requires admin)
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://maas-api.lanyun.net/anthropic-k2/", "Machine")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKeyPlain, "Machine")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $model, "Machine")
    
    # Also set for current session
    $env:ANTHROPIC_BASE_URL = "https://maas-api.lanyun.net/anthropic-k2/"
    $env:ANTHROPIC_API_KEY = $apiKeyPlain
    $env:ANTHROPIC_MODEL = $model
    
    Write-Host "✅ Environment variables set successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to set environment variables: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Installation completed successfully!" -ForegroundColor Green
Write-Host "🎉 安装成功完成！" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANT: Close and reopen your terminal/PowerShell to use Claude Code" -ForegroundColor Yellow
Write-Host "⚠️  重要：关闭并重新打开您的终端/PowerShell 以使用 Claude Code" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 After that, you can use: claude" -ForegroundColor Cyan
Write-Host "🚀 之后即可使用：claude" -ForegroundColor Cyan
