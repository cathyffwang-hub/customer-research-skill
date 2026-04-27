#!/bin/bash
# 客户调研大纲生成 Skill - 一键安装脚本
# 使用方法：bash <(curl -fsSL https://raw.githubusercontent.com/Tencent-docx-CSM/customer-research-skill/main/install.sh)
# 或手动下载后运行：bash install.sh

set -e

SKILL_NAME="客户调研大纲生成"
SKILL_DIR="$HOME/.workbuddy/skills/$SKILL_NAME"
REPO_HTTPS="https://github.com/Tencent-docx-CSM/customer-research-skill.git"
REPO_SSH="git@github.com:Tencent-docx-CSM/customer-research-skill.git"

echo "🚀 开始安装 $SKILL_NAME ..."
echo ""

# 检查 git 是否安装
if ! command -v git &> /dev/null; then
    echo "❌ 错误：未检测到 git，请先安装 git"
    echo "   macOS: brew install git"
    echo "   Ubuntu/Debian: sudo apt install git"
    exit 1
fi

# 检查目录是否已存在
if [ -d "$SKILL_DIR" ]; then
    echo "⚠️  目录已存在：$SKILL_DIR"
    echo "   运行更新脚本："
    echo "   bash $SKILL_DIR/update.sh"
    echo ""
    read -p "是否删除并重新安装？(y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  删除旧版本..."
        rm -rf "$SKILL_DIR"
    else
        echo "❌ 安装已取消"
        exit 0
    fi
fi

# 尝试克隆（优先 HTTPS，失败则提示 SSH）
echo "📦 正在克隆仓库..."
echo ""

# 检查是否已配置 credential helper
if git config --global credential.helper &> /dev/null; then
    echo "   使用 HTTPS 克隆（将提示输入 GitHub 账号密码）..."
    git clone "$REPO_HTTPS" "$SKILL_DIR"
else
    echo "   提示：未检测到 Git 凭据管理器"
    echo "   将尝试 HTTPS 克隆，如果失败请配置 SSH Key"
    echo "   SSH Key 配置指南：https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
    echo ""
    git clone "$REPO_HTTPS" "$SKILL_DIR" 2>/dev/null || {
        echo ""
        echo "⚠️  HTTPS 克隆失败，尝试 SSH..."
        git clone "$REPO_SSH" "$SKILL_DIR"
    }
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "📍 安装位置：$SKILL_DIR"
echo "🎉 现在你可以在 WorkBuddy 中使用「客户调研大纲生成」skill 了"
echo ""
echo "💡 后续更新：运行 update.sh"
echo "   bash $SKILL_DIR/update.sh"

