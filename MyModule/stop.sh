MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
crond_kill
crontab_kill