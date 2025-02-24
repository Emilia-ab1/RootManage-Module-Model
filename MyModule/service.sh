MODDIR=${0%/*}

CRONDIR="$MODDIR/cron.d"
SPOOLDIR="$MODDIR/spool"
CONFIGDIR="$MODDIR/etc"

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

mkdir -p "$SPOOLDIR"
mkdir -p "$CONFIGDIR"
mkdir -p "$CRONDIR"

chmod -R 755 "$SPOOLDIR"
chmod -R 755 "$CONFIGDIR"
chmod -R 755 "$CRONDIR"

pkill -f unicrond # 以防万一

unicrond -b -c "$CONFIGDIR" -s "$SPOOLDIR"

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

