#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数

mkdir -p $MODDIR/cron/crontabs
mkdir -p $MODDIR/API/cron_tasks
touch $MODDIR/cron/crontabs/root
chmod +x $MODDIR/cron/crontabs/root
chmod +x $MODDIR/API/cron_tasks

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done
set_module_description "模块即将启动"
sleep 3

log INFO "开机运行"
$MODDIR/UniCron.sh
crontabs 1
crond 1