#!/bin/bash
# 客户调研大纲生成 Skill - 一键安装脚本
# 使用方法：bash <(curl -fsSL https://raw.githubusercontent.com/Tencent-docx-CSM/customer-research-skill/main/install.sh)
# 或手动下载后运行：bash install.sh

set -e

SKILL_NAME="客户调研大纲生成"
SKILL_DIR="$HOME/.workbuddy/skills/$SKILL_NAME"
REPO_URL="https://github.com/Tencent-docx-CSM/customer-research-skill.git"

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
    echo "   是否需要更新？运行 update.sh 来更新"
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

# 克隆仓库
echo "📦 正在克隆仓库..."
git clone "$REPO_URL" "$SKILL_DIR"

echo ""
echo "✅ 安装完成！"
echo ""
echo "📍 安装位置：$SKILL_DIR"
echo "🎉 现在你可以在 WorkBuddy 中使用「客户调研大纲生成」skill 了"
echo ""
echo "💡 后续更新：运行 update.sh"
echo "   bash $SKILL_DIR/update.sh"
