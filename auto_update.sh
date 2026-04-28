#!/bin/bash
# 自动更新脚本 - 由 launchd/cron 定时调用

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SKILL_DIR/auto_update.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 检查更新..." >> "$LOG_FILE"

cd "$SKILL_DIR"

# 检查是否有远程更新
git remote update >/dev/null 2>&1
LOCAL=$(git rev-parse @ 2>/dev/null || echo "no_local")
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no_remote")

if [ "$LOCAL" != "$REMOTE" ] && [ "$REMOTE" != "no_remote" ] && [ "$LOCAL" != "no_local" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 发现更新，正在拉取..." >> "$LOG_FILE"
    git pull origin main >> "$LOG_FILE" 2>&1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 更新完成" >> "$LOG_FILE"
fi
