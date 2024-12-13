#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done
init

set_module_description "模块即将启动"
sleep 3

log INFO "开机运行"
$MODDIR/UniCron.sh
crontab 1
crond 1