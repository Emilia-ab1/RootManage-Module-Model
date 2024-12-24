#!/system/bin/sh
MODDIR=${0%/*}


until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "等待开机完成"
    sleep 1
done

$MODDIR/bin/UniTimecron

