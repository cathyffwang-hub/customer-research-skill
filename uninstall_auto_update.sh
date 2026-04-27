#!/bin/bash
# 客户调研大纲生成 Skill - 卸载自动更新任务
# 使用方法：bash ~/.workbuddy/skills/客户调研大纲生成/uninstall_auto_update.sh

set -e

PLIST_LABEL="com.workbuddy.skill.customer-research"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "🔄 正在卸载自动更新任务..."
echo ""

# 检测操作系统
if [ "$(uname)" = "Darwin" ]; then
    # macOS - 卸载 launchd 任务
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
        echo "✅ macOS 自动更新任务已卸载（launchd）"
    else
        echo "⚠️  未找到 launchd 任务配置文件"
    fi

elif [ "$(expr substr $(uname -s) 1 5 2>/dev/null)" = "Linux" ]; then
    # Linux - 卸载 cron 任务
    SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
    AUTO_UPDATE_SCRIPT="$SKILL_DIR/auto_update.sh"
    if crontab -l 2>/dev/null | grep -F "$AUTO_UPDATE_SCRIPT" >/dev/null; then
        crontab -l 2>/dev/null | grep -v -F "$AUTO_UPDATE_SCRIPT" | crontab -
        echo "✅ Linux 自动更新任务已卸载（cron）"
    else
        echo "⚠️  未找到 cron 任务"
    fi
else
    echo "⚠️  未识别的操作系统"
fi

echo ""
echo "💡 自动更新已停用"
echo "   如需重新启用，请运行：bash $0/install.sh"
