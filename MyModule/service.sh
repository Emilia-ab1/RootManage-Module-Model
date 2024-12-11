#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数

merge_crontabs
crontab
crond

