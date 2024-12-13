# 初始化程序
MODDIR=${0%/*}
source $MODDIR/utils.sh
# 新建目录/文件的步骤在utils.sh已经完成
# API  存放符号链接
# cron 存放crond/crontab运行配置
# logs 存放日志
# ...
echo "开始初始化UniCron" >> $INIT_LOG

# 检查

if [ -f $MODDIR/disable ]; then #虽然被禁用的情况下 service.sh不会运行 init不会运行 。在直接运行这个脚本时，这个检查有用
    echo "检测到本模块被禁用，终止脚本" >> $INIT_LOG
    exit 1
fi

# 修改为字符串比较 避免ash bad numbr报错
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    echo "检查 --- 等待系统开机完毕" >> "$INIT_LOG"
    sleep 1
done


# 检查是否有 crond/crontab 进程正在运行
if pgrep -x "crond" > /dev/null; then
    echo "检测到未知crond进程，加入名单：unknown_process" >> $unknown_process
else
    echo "好耶！未发现未知crond进程" >> $INIT_LOG
fi

if pgrep -x "crontab" > /dev/null; then
    echo "检测到未知crontab进程，加入名单：unknown_process" >> $unknown_process
else
    echo "好耶！未发现未知crontab进程" >> $INIT_LOG
fi


if [ ! -s $UniCrond_cron ]; then #检查守护程序cron配置是否正常
    echo "$UniCrond_cron 异常，尝试恢复" >> $INIT_LOG
    URL="https://github.com/LIghtJUNction/RootManage-Module-Model/blob/UniCron/MyModule/UniCron/UniCrond.cron"
    DEST="$UniCrond_cron"
    if curl -o $DEST $URL; then
        chmod 755 $DEST
    else
        echo "下载 UniCrond.cron 失败" >> $INIT_LOG
        exit 1
    fi
fi

if [ ! -s $UniCrond ]; then #检查守护程序crond是否正常
    echo "$UniCrond 异常，尝试恢复" >> $INIT_LOG
    URL="https://github.com/LIghtJUNction/RootManage-Module-Model/blob/UniCron/MyModule/UniCrond.sh"
    DEST="$UniCrond"
    if curl -o $DEST $URL; then
        chmod 755 $DEST
    else
        echo "下载 UniCrond.sh 失败" >> $INIT_LOG
        set_prop_value "description" "模块寄了（找不到UniCrond）请重新安装本模块"
        exit 1
    fi
fi



# 启动-守护进程
echo "启动守护进程......" >> $INIT_LOG
if [ -s $UniCrond_cron ]; then # 前面刚刚检查过了 ，这里以防万一再来一遍
    RUN init
else
    LOG ERROR "模块缺失$UniCrond_cron，正在尝试修复"
    echo "* * * * * /data/adb/modules/UniCron/UniCrond.sh" > $UniCrond_cron
    LOG INFO "修复完成-继续启动"
    RUN init
fi
# 立即启动UniCrond程序
$UniCrond

echo "初始化完成！" >> $INIT_LOG
set_prop_value "description" "初始化完成！"
