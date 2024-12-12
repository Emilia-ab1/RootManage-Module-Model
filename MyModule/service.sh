#!/system/bin/sh

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done

MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
log INFO "开机运行"
crond 1
$MODDIR/UniCron.sh
