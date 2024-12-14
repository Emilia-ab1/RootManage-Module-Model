MODDIR="/data/adb/modules/UniCron"
# 非核心脚本-硬编码无所谓
# 设置网页目录
WEB_DIR="$MODDIR/webroot"  # 这里需要设置为实际网页目录
LOG_DIR="$MODDIR/logs" # 日志文件的存储目录

# 设置文件路径
CRONTAB_FILE="$MODDIR/cron/crontabs/root"
LOG_FILE="$LOG_DIR/UniCron.log"

# 检查crontab文件是否存在
if [ -f "$CRONTAB_FILE" ]; then
    cp "$CRONTAB_FILE" "$WEB_DIR/status"
else
    echo "模块已暂停" > "$WEB_DIR/status"
fi

# 检查日志文件是否存在
if [ -f "$LOG_FILE" ]; then
    cp "$LOG_FILE" "$WEB_DIR/log"
else
    echo "模块已损坏！" > "$WEB_DIR/status"
fi
