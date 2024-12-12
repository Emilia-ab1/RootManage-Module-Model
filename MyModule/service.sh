#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done
set_module_description "模块将在20秒后启动"
sleep 20

log INFO "开机运行"
crond 1
$MODDIR/UniCron.sh
