# 刷新cron配置,并输出当前cron配置
MODDIR=${0%/*}

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

update() {
    # 获取当前任务列表
    cron_list="$(unicrontab -l -c "$CONFIGDIR" 2>/dev/null)"
   
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
    update_pid_status "crond -b -c $CONFIGDIR" "$MODDIR/webroot/unicrond_pid"
}

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

echo "刷新完成"