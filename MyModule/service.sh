#!/system/bin/sh

# 获取模块目录
MODDIR=${0%/*}

# 创建必要的目录
mkdir -p "$MODDIR/webroot"
mkdir -p "$MODDIR/webroot/spool"
mkdir -p "$MODDIR/webroot/etc"

# 定义日志和配置路径
ERROR_LOG="$MODDIR/webroot/error.log"
SPOOLDIR="$MODDIR/webroot/spool"
CONFIGDIR="$MODDIR/webroot/etc"
CRON_LOG="$MODDIR/webroot/cron.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ERROR_LOG"
}

update_pid_status() {
    local name="$1"
    local file="$2"
    local pid=$(pgrep -f "$name" 2>/dev/null)
    if [ -n "$pid" ]; then
        echo "$pid" > "$file"
    else
        echo "未运行" > "$file"
    fi
}

# 更新模块描述
update() {
    # 获取当前任务列表
    cron_list="$(unicrontab -l -c "$CONFIGDIR" 2>/dev/null)"
    echo "$cron_list" > "$MODDIR/webroot/cron_list"
    
    # 准备描述文本
    base_desc="UniCron-统一Cron前置模块"
    if [ -n "$cron_list" ]; then
        current_tasks=" | 当前定时任务: | $(echo "$cron_list" | tr '\n' '|')"
    else
        current_tasks=" | 当前无定时任务"
    fi
    
    # 直接修改 description 值
    if [ -f "$MODDIR/module.prop" ]; then
        awk -v desc="$base_desc$current_tasks" '
        /^description=/ {print "description=" desc; next}
        {print}
        ' "$MODDIR/module.prop" > "$MODDIR/module.prop.new" && \
        mv "$MODDIR/module.prop.new" "$MODDIR/module.prop"
    fi

    update_pid_status "crond" "$MODDIR/webroot/crond_pid"
    update_pid_status "unicrond" "$MODDIR/webroot/unicrond_pid"
    
}

# 主要执行流程
main() {
    log "服务启动"
    
    until [ "$(getprop sys.boot_completed)" = "1" ]; do
        sleep 1
    done
    log "系统已启动"

    chmod 755 "$SPOOLDIR"
    chmod 755 "$CONFIGDIR"
    
    pkill -f unicrond
    
    unicrond -b -c "$CONFIGDIR" -S "$SPOOLDIR" -L "$CRON_LOG" -l 0
    sleep 2
    log "unicrond 已启动"

    TEMP_CRON="$MODDIR/temp_cron"
    rm -f "$TEMP_CRON"
    touch "$TEMP_CRON"
    
    find /data/adb/modules/*/UniCron -name "*.cron" -type f 2>/dev/null | while read -r cron_file; do
        if [ -f "$cron_file" ]; then
            {
                echo "# From file: $(basename "$cron_file")"
                cat "$cron_file"
                echo ""
            } >> "$TEMP_CRON"
        fi
    done

    if [ -s "$TEMP_CRON" ]; then
        unicrontab -c "$CONFIGDIR" "$TEMP_CRON"
        log "crontab 已更新"
    fi

    rm -f "$TEMP_CRON"
    update
    log "配置更新完成"
}

# 启动主函数
main 2>> "$ERROR_LOG"