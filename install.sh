#!/bin/bash
# 客户调研大纲生成 Skill - 安装脚本（含自动更新）
# 使用方法：
#   1. 先 clone 仓库：
#     git clone git@github.com:Tencent-docx-CSM/customer-research-skill.git ~/.workbuddy/skills/客户调研大纲生成
#   2. 运行本脚本注册自动更新：
#     bash ~/.workbuddy/skills/客户调研大纲生成/install.sh

set -e

SKILL_NAME="客户调研大纲生成"
SKILL_DIR="$HOME/.workbuddy/skills/$SKILL_NAME"
PLIST_LABEL="com.workbuddy.skill.customer-research"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "🚀 开始安装 $SKILL_NAME ..."
echo ""

# ========== 步骤 1：检查仓库 ==========
if [ ! -d "$SKILL_DIR/.git" ]; then
    echo "❌ 未检测到仓库目录：$SKILL_DIR"
    echo ""
    echo "请先 clone 仓库："
    echo "  git clone git@github.com:Tencent-docx-CSM/customer-research-skill.git ~/.workbuddy/skills/客户调研大纲生成"
    echo ""
    echo "或者使用 HTTPS（需输入 GitHub 账号密码）："
    echo "  git clone https://github.com/Tencent-docx-CSM/customer-research-skill.git ~/.workbuddy/skills/客户调研大纲生成"
    exit 1
fi

echo "✅ 检测到仓库：$SKILL_DIR"
cd "$SKILL_DIR"

# 检查远程地址是否匹配
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE_URL" ]; then
    echo "⚠️  未检测到远程仓库地址，请检查"
    exit 1
fi
echo "   远程地址：$REMOTE_URL"
echo ""

# ========== 步骤 2：注册自动更新任务 ==========
echo "🔄 正在注册自动更新任务（每 1 分钟检查一次）..."
echo ""

# 创建自动更新脚本
AUTO_UPDATE_SCRIPT="$SKILL_DIR/auto_update.sh"
cat > "$AUTO_UPDATE_SCRIPT" << 'AUTOUPDATE_EOF'
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
AUTOUPDATE_EOF

chmod +x "$AUTO_UPDATE_SCRIPT"

# 检测操作系统并注册相应任务
if [ "$(uname)" = "Darwin" ]; then
    # macOS - 使用 launchd
    cat > "$PLIST_FILE" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${AUTO_UPDATE_SCRIPT}</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${SKILL_DIR}/auto_update.log</string>
    <key>StandardErrorPath</key>
    <string>${SKILL_DIR}/auto_update.log</string>
</dict>
</plist>
PLIST_EOF

    # 卸载旧任务（如果存在）
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    # 加载新任务
    launchctl load "$PLIST_FILE"
    echo "✅ macOS 自动更新任务已注册（launchd）"
    echo "   Plist 位置：~/Library/LaunchAgents/${PLIST_LABEL}.plist"
    echo "   检查间隔：每 60 秒"

elif [ "$(expr substr $(uname -s) 1 5 2>/dev/null)" = "Linux" ]; then
    # Linux - 使用 cron
    CRON_JOB="* * * * * $AUTO_UPDATE_SCRIPT >/dev/null 2>&1"
    # 检查是否已存在
    if ! crontab -l 2>/dev/null | grep -F "$AUTO_UPDATE_SCRIPT" >/dev/null; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "✅ Linux 自动更新任务已注册（cron）"
        echo "   检查间隔：每 1 分钟"
    else
        echo "⚠️  自动更新任务已存在（cron）"
    fi
else
    echo "⚠️  未识别的操作系统，跳过自动更新注册"
    echo "   请手动运行更新：bash $SKILL_DIR/update.sh"
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "📍 安装位置：$SKILL_DIR"
echo "🎉 现在你可以在 WorkBuddy 中使用「客户调研大纲生成」skill 了"
echo ""
echo "💡 自动更新已启用，管理员推送代码后最多 1 分钟自动同步"
echo "   查看更新日志：cat $SKILL_DIR/auto_update.log"
echo "   手动更新：bash $SKILL_DIR/update.sh"
echo "   卸载自动更新：bash $SKILL_DIR/uninstall_auto_update.sh"
