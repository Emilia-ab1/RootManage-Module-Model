#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done
> $MODDIR/init
init
set_module_description "正在检查模块状态"
sleep 3
if [ -s "$MODDIR/cron/crontabs/root" ];then
    log INFO "顺利启动！"
    rm -f "$MODDIR/init"
else
    while true ; do
        if [ -s "$MODDIR/cron/crontabs/root" ];then
            log INFO "启动成功！"
            rm -f "$MODDIR/init"
            break
        else
            init
            sleep 1
        fi
    done
fi
