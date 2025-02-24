# 刷新cron配置,并输出当前cron配置
MODDIR=${0%/*}

SPOOLDIR="$MODDIR/webroot/spool"
CONFIGDIR="$MODDIR/webroot/etc"
CRON_LOG="$MODDIR/webroot/cron.log"

$MODDIR/service.sh

echo "刷新完成"