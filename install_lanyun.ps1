# Simplified Windows PowerShell installer for Claude Code with Lanyun
# This version has better error handling and progress indication

param(
    [switch]$SkipNodeCheck
)

# Basic setup
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude Code Lanyun Installer" -ForegroundColor Cyan
Write-Host " 蓝云 Claude Code 安装程序" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to test if running as admin
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check admin rights
if (-not (Test-Administrator)) {
    Write-Host "⚠️  需要管理员权限来设置环境变量" -ForegroundColor Yellow
    Write-Host "⚠️  This script needs Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请以管理员身份重新运行 PowerShell" -ForegroundColor Cyan
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 1: Check Node.js
if (-not $SkipNodeCheck) {
    Write-Host "📋 Checking Node.js installation..." -ForegroundColor Yellow
    
    try {
        $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
        if ($nodeCmd) {
            $nodeVersion = & node -v 2>$null
            Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
            
            $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($majorVersion -lt 18) {
                Write-Host "⚠️  Node.js version is less than 18. Please update manually." -ForegroundColor Yellow
                Write-Host "   Download from: https://nodejs.org/" -ForegroundColor Gray
                Read-Host "Press Enter to exit"
                exit 1
            }
        } else {
            throw "Node.js not found"
        }
    } catch {
        Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
        Write-Host "   Download from: https://nodejs.org/" -ForegroundColor Gray
        Write-Host "   推荐下载 LTS 版本" -ForegroundColor Gray
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Step 2: Install Claude Code
Write-Host ""
Write-Host "📦 Installing Claude Code CLI..." -ForegroundColor Yellow

try {
    # Check if claude is already installed
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        Write-Host "✅ Claude Code is already installed" -ForegroundColor Green
    } else {
        Write-Host "   Running: npm install -g @anthropic-ai/claude-code" -ForegroundColor Gray
        $output = & npm install -g @anthropic-ai/claude-code 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Claude Code installed successfully" -ForegroundColor Green
        } else {
            throw "npm install failed: $output"
        }
    }
} catch {
    Write-Host "❌ Failed to install Claude Code: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 3: Configure Claude settings
Write-Host ""
Write-Host "⚙️  Configuring Claude Code..." -ForegroundColor Yellow

$claudeConfigPath = "$env:USERPROFILE\.claude.json"
try {
    $config = @{ hasCompletedOnboarding = $true }
    
    if (Test-Path $claudeConfigPath) {
        $existingConfig = Get-Content $claudeConfigPath -Raw | ConvertFrom-Json
        $existingConfig | Add-Member -MemberType NoteProperty -Name hasCompletedOnboarding -Value $true -Force
        $config = $existingConfig
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $claudeConfigPath -Encoding UTF8
    Write-Host "✅ Configuration updated" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Could not update configuration file" -ForegroundColor Yellow
}

# Step 4: Get API Key
Write-Host ""
Write-Host "🔑 API Key Configuration" -ForegroundColor Cyan
Write-Host "   获取 API Key: https://maas.lanyun.net/" -ForegroundColor Gray
Write-Host ""

$apiKey = Read-Host -Prompt "请输入您的 API Key (Enter your API key)" -AsSecureString
$apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))

if ([string]::IsNullOrWhiteSpace($apiKeyPlain)) {
    Write-Host "❌ API key cannot be empty" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 5: Get Model
Write-Host ""
$model = Read-Host -Prompt "请输入模型名称 (Enter model name) [默认/default: k2]"
if ([string]::IsNullOrWhiteSpace($model)) {
    $model = "k2"
}
Write-Host "✅ Using model: $model" -ForegroundColor Green

# Step 6: Set Environment Variables
Write-Host ""
Write-Host "🔧 Setting environment variables..." -ForegroundColor Yellow

try {
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://maas-api.lanyun.net/anthropic-k2/", "Machine")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKeyPlain, "Machine")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $model, "Machine")
    
    # Also set for current session
    $env:ANTHROPIC_BASE_URL = "https://maas-api.lanyun.net/anthropic-k2/"
    $env:ANTHROPIC_API_KEY = $apiKeyPlain
    $env:ANTHROPIC_MODEL = $model
    
    Write-Host "✅ Environment variables set successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to set environment variables: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Success
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " 🎉 Installation Completed! 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  请关闭并重新打开终端来使用 claude 命令" -ForegroundColor Yellow
Write-Host "⚠️  Please close and reopen your terminal to use 'claude' command" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usage: claude" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
