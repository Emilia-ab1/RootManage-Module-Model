# 刷新cron配置,并输出当前cron配置
MODDIR=${0%/*}

$MODDIR/service.sh

unicrontab -c $CONFIGDIR -l

echo "刷新完成"