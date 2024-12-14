#!/bin/sh
# filepath: /D:/HOME/ARCHLINNUX/GitHub/RootManage-Module-Model/data/adb/modules/UniCron/init.sh

# 初始化程序
MODDIR=$(dirname "$0")
echo "MODDIR: $MODDIR"
# set -x
# 切换到脚本所在目录
cd "$MODDIR" || { echo "无法切换到目录 $MODDIR"; exit 1; }

# 确保 utils.sh 文件存在
if [ ! -f "./utils.sh" ]; then
    echo "utils.sh 文件不存在"
    exit 1
fi

# 加载 utils.sh 文件
. ./utils.sh

# 确保 INIT_LOG 变量已初始化
INIT_LOG="$MODDIR/init.log"

# 新建目录/文件的步骤在 utils.sh 已经完成
# API  存放符号链接
# cron 存放 crond/crontab 运行配置
# logs 存放日志
# ...
echo "开始初始化 UniCron" >> "$INIT_LOG"

# 检查
if [ -f "$MODDIR/disable" ]; then
    echo "检测到本模块被禁用，终止脚本" >> "$INIT_LOG"
    exit 1
fi

> $unknown_process
# 检查是否有 crond/crontab 进程正在运行
if pgrep -x "crond" > /dev/null; then
    echo "检测到未知 crond 进程，加入名单：unknown_process" >> "$INIT_LOG"
    echo "$(pgrep -x crond)" >> $unknown_process
else
    echo "好耶！未发现未知 crond 进程" >> "$INIT_LOG"
fi

if pgrep -x "crontab" > /dev/null; then
    echo "检测到未知 crontab 进程，加入名单：unknown_process" >> "$INIT_LOG"
    echo "$(pgrep -x crond)" >> $unknown_process
else
    echo "好耶！未发现未知 crontab 进程" >> "$INIT_LOG"
fi

if [ ! -s "$UniCrond_cron" ]; then #检查守护程序 cron 配置是否正常
    echo "$UniCrond_cron 异常，尝试恢复" >> "$INIT_LOG"
    URL="https://github.com/LIghtJUNction/RootManage-Module-Model/blob/UniCron/MyModule/UniCron/UniCrond.cron"
    DEST="$MODDIR/UniCrond.cron"
    if curl -o "$DEST" "$URL" 2>> "$ERROR_LOG"; then
        chmod 755 "$DEST" 2>> "$ERROR_LOG"
    else
        echo "下载 UniCrond.cron 失败" >> "$ERROR_LOG"
        exit 1
    fi
fi

# 继续执行脚本的其他部分
echo "初始化脚本执行中..." >> "$INIT_LOG"

# 调用 RUN 函数
RUN init

# 设置属性值
set_prop_value "description" "UniCron 初始化完成" >> "$INIT_LOG"