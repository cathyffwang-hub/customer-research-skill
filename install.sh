#!/bin/bash
# 客户调研大纲生成 Skill - 一键安装脚本（含自动更新）
# 使用方法：bash <(curl -fsSL https://raw.githubusercontent.com/Tencent-docx-CSM/customer-research-skill/main/install.sh)
# 或手动下载后运行：bash install.sh

set -e

SKILL_NAME="客户调研大纲生成"
SKILL_DIR="$HOME/.workbuddy/skills/$SKILL_NAME"
REPO_HTTPS="https://github.com/Tencent-docx-CSM/customer-research-skill.git"
REPO_SSH="git@github.com:Tencent-docx-CSM/customer-research-skill.git"
PLIST_LABEL="com.workbuddy.skill.customer-research"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

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
        # 同时卸载旧的自动更新任务
        if [ -f "$PLIST_FILE" ]; then
            launchctl unload "$PLIST_FILE" 2>/dev/null || true
            rm -f "$PLIST_FILE"
        fi
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

# ===== 注册自动更新任务 =====
echo ""
echo "🔄 正在注册自动更新任务（每 1 分钟检查一次）..."

# 创建自动更新脚本
AUTO_UPDATE_SCRIPT="$SKILL_DIR/auto_update.sh"
cat > "$AUTO_UPDATE_SCRIPT" << 'AUTOUPDATE_EOF'
#!/bin/bash
# 自动更新脚本 - 由 launchd 定时调用

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SKILL_DIR/auto_update.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 检查更新..." >> "$LOG_FILE"

cd "$SKILL_DIR"

# 检查是否有远程更新
git remote update >/dev/null 2>&1
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no_remote")

if [ "$LOCAL" != "$REMOTE" ] && [ "$REMOTE" != "no_remote" ]; then
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

elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
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
echo "🎉 现在你可以在 WorkBuddy 中使用「客户调研大纲生成」skill 了"
echo ""
echo "💡 自动更新已启用，你推送代码后最多 1 分钟自动同步"
echo "   查看更新日志：cat $SKILL_DIR/auto_update.log"
echo "   手动更新：bash $SKILL_DIR/update.sh"
