MODDIR=${0%/*}
ERROR_LOG="$MODDIR/webroot/error.log"

# 清空错误日志
echo "Starting service at $(date '+%Y-%m-%d %H:%M:%S')" > "$ERROR_LOG"

SPOOLDIR="$MODDIR/webroot/spool"
CONFIGDIR="$MODDIR/webroot/etc"
CRON_LOG="$MODDIR/webroot/cron.log"

update_module_description() {
    # 获取当前定时任务列表
    local cron_list=$(unicrontab -l -c "$CONFIGDIR" 2>/dev/null)
    echo "$cron_list" > "$MODDIR/webroot/cron_list" # 方便网页展示
    # 准备基础描述信息
    local base_desc="UniCron-统一Cron前置模块"
    local current_tasks=""
    
    # 如果有定时任务，则添加到描述中
    if [ -n "$cron_list" ]; then
        current_tasks=" | 当前定时任务: | $(echo "$cron_list" | tr '\n' '|')"
    else
        current_tasks=" | 当前无定时任务"
    fi
    
    # 更新 module.prop 文件的描述
    local prop_file="$MODDIR/module.prop"
    if [ -f "$prop_file" ]; then
        local temp_file="$MODDIR/module.prop.tmp"
        sed "/^description=/c\description=$base_desc$current_tasks" "$prop_file" > "$temp_file"
        mv "$temp_file" "$prop_file"
    fi
}

# 将所有错误重定向到日志文件
{
    until [ "$(getprop sys.boot_completed)" = "1" ]; do
        sleep 1
    done

    mkdir -p "$SPOOLDIR"
    mkdir -p "$CONFIGDIR"

    chmod -R 755 "$SPOOLDIR"
    chmod -R 755 "$CONFIGDIR"

    pkill -f unicrond # 以防万一

    unicrond -b -c "$CONFIGDIR" -S "$SPOOLDIR" -L "$CRON_LOG" -l 0

    sleep 2

    TEMP_CRON="$MODDIR/temp_cron"
    rm -f "$TEMP_CRON"

    # 读取所有模块的 cron 文件
    find /data/adb/modules/*/UniCron -name "*.cron" -type f 2>/dev/null | while read -r cron_file; do
        if [ -f "$cron_file" ]; then
            echo "# From file: $(basename "$cron_file")" >> "$TEMP_CRON"
            cat "$cron_file" >> "$TEMP_CRON"
            echo "" >> "$TEMP_CRON"  # 保留一个空行用于分隔
        fi
    done

    # 如果发现有配置文件，则更新 crontab
    if [ -s "$TEMP_CRON" ]; then
        unicrontab -c $CONFIGDIR "$TEMP_CRON"
    fi

    # 清理临时文件
    rm -f "$TEMP_CRON"

    update_module_description()

} 2> "$ERROR_LOG"