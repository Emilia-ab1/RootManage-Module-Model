# 刷新cron配置,并输出当前cron配置
MODDIR=${0%/*}

$MODDIR/service.sh

unicrontab -l

ui_print "刷新完成"