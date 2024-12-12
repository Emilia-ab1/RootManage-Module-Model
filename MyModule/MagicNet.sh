# 本脚本由UniCron驱动
# 请查看UniCron/MagicNet.cron 安装配置好之前每分钟执行一次，设置完毕正常运行时每小时运行一次
MODDIR=${0%/*}
source $MODDIR/tools # 导入工具函数

if [ -f $MODDIR/init ];then
  set_module_description "引导模式-请前往data/adb/modules/MagicNet/env填写订阅链接"
  init
else
  set_module_description "欢迎使用本模块！稍后切换至守护模式"
  echo "* 0 * * * data/adb/modules/MagicNet.sh" > $MODDIR/UniCron/MagicNet.cron
  update
fi
