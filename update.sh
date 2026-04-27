#!/bin/bash
# 客户调研大纲生成 Skill - 一键更新脚本
# 使用方法：bash ~/.workbuddy/skills/客户调研大纲生成/update.sh
# 或直接：bash update.sh（在 skill 目录下运行）

set -e

SKILL_NAME="客户调研大纲生成"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🭃 开始更新 $SKILL_NAME ..."
echo ""

# 检查是否在正确的目录
if [ ! -d "$SKILL_DIR/.git" ]; then
    echo "❌ 错误：未检测到 git 仓库"
    echo "   请先运行 install.sh 安装 skill"
    exit 1
fi

# 进入 skill 目录
cd "$SKILL_DIR"

# 拉取最新代码
echo "📡 正在拉取最新代码..."
git pull origin main

echo ""
echo "✅ 更新完成！"
echo ""
echo "📍 当前版本："
git log -1 --oneline
