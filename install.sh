#!/bin/bash

set -e

install_nodejs() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS..."
            
            echo "📥 Downloading and installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            
            echo "🔄 Loading nvm environment..."
            \. "$HOME/.nvm/nvm.sh"
            
            echo "📦 Downloading and installing Node.js v22..."
            nvm install 22
            
            echo -n "✅ Node.js installation completed! Version: "
            node -v # Should print "v22.17.0".
            echo -n "✅ Current nvm version: "
            nvm current # Should print "v22.17.0".
            echo -n "✅ npm version: "
            npm -v # Should print "10.9.2".
            ;;
        *)
            echo "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

# Check if Node.js is already installed and version is >= 18
if command -v node >/dev/null 2>&1; then
    current_version=$(node -v | sed 's/v//')
    major_version=$(echo $current_version | cut -d. -f1)
    
    if [ "$major_version" -ge 18 ]; then
        echo "Node.js is already installed: v$current_version"
    else
        echo "Node.js v$current_version is installed but version < 18. Upgrading..."
        install_nodejs
    fi
else
    echo "Node.js not found. Installing..."
    install_nodejs
fi

# Check if Claude Code is already installed
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed: $(claude --version)"
else
    echo "Claude Code not found. Installing..."
    npm install -g @anthropic-ai/claude-code
fi

# Configure Claude Code to skip onboarding
echo "Configuring Claude Code to skip onboarding..."
node --eval '
    const homeDir = os.homedir(); 
    const filePath = path.join(homeDir, ".claude.json");
    if (fs.existsSync(filePath)) {
        const content = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        fs.writeFileSync(filePath,JSON.stringify({ ...content, hasCompletedOnboarding: true }, 2), "utf-8");
    } else {
        fs.writeFileSync(filePath,JSON.stringify({ hasCompletedOnboarding: true }), "utf-8");
    }'

# Prompt user for API key
echo "🔑 Please enter your lanyun API key:"
echo "🔑 请输入您的蓝云 API 密钥："
echo "   You can get your API key from: https://maas.lanyun.net/"
echo "   您可以从这里获取 API 密钥：https://maas.lanyun.net/"
echo "   Note: The input is hidden for security. Please paste your API key directly."
echo "   注意：为了安全起见，输入内容将被隐藏。请直接粘贴您的 API 密钥。"
echo ""
read -s api_key
echo ""

if [ -z "$api_key" ]; then
    echo "⚠️  API key cannot be empty. Please run the script again."
    exit 1
fi

# Prompt user for model (optional, default is k2)
echo ""
echo "🤖 Please enter the Claude model to use (press Enter for default 'k2'):"
echo "🤖 请输入要使用的 Claude 模型（按回车使用默认值 'k2'）："
echo ""
read model
echo ""

# Set default model if not provided
if [ -z "$model" ]; then
    model="k2"
    echo "ℹ️  Using default model: k2"
fi

# Detect current shell and determine rc file
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash)
        rc_file="$HOME/.bashrc"
        ;;
    zsh)
        rc_file="$HOME/.zshrc"
        ;;
    fish)
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    *)
        rc_file="$HOME/.profile"
        ;;
esac

# Add environment variables to rc file
echo ""
echo "📝 Adding environment variables to $rc_file..."

# Check if variables already exist to avoid duplicates
if [ -f "$rc_file" ] && grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY\|ANTHROPIC_MODEL" "$rc_file"; then
    echo "⚠️ Environment variables already exist in $rc_file. Skipping..."
else
    # Append new entries
    echo "" >> "$rc_file"
    echo "# Claude Code environment variables" >> "$rc_file"
    echo "export ANTHROPIC_BASE_URL=https://maas-api.lanyun.net/anthropic-k2/" >> "$rc_file"
    echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
    echo "export ANTHROPIC_MODEL=$model" >> "$rc_file"
    echo "✅ Environment variables added to $rc_file"
fi

# If script is being sourced, load the environment variables
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo ""
    echo "🔄 Loading environment variables..."
    source "$rc_file"
    echo "✅ Environment variables loaded in current shell!"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo "🎉 安装成功完成！"
echo ""

# Check if script was sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "🚀 You can now start using Claude Code with:"
    echo "🚀 现在您可以开始使用 Claude Code 了："
    echo "   claude"
else
    echo "⚠️  IMPORTANT: To use the environment variables in your current shell, please run:"
    echo "⚠️  重要提示：要在当前 shell 中使用环境变量，请运行："
    echo "   source $rc_file"
    echo ""
    echo "   Or restart your terminal."
    echo "   或者重启您的终端。"
    echo ""
    echo "🚀 After that, you can start using Claude Code with:"
    echo "🚀 之后，您可以使用以下命令启动 Claude Code："
    echo "   claude"
fi
