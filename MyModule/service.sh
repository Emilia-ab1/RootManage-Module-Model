#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
log INFO "开机运行"
crond 1
$MODDIR/UniCron.sh
