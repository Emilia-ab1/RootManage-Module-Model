MODDIR=${0%/*}
ERROR_LOG="$MODDIR/error.log"
> $ERROR_LOG
if [ ! -s $MODDIR/utils.sh ]; then
    echo "模块不完整-缺少关键utils.sh，尝试修复..." > "$ERROR_LOG"
    URL="https://github.com/LIghtJUNction/RootManage-Module-Model/blob/UniCron/MyModule/utils.sh"
    DEST="$MODDIR/utils.sh"
    if curl -o $DEST $URL 2>> "$ERROR_LOG"; then
        chmod 755 $DEST 2>> "$ERROR_LOG"
    else
        echo "下载 utils.sh 失败" >> "$ERROR_LOG"
        exit 1
    fi
fi


source $MODDIR/utils.sh 2>> "$ERROR_LOG"
echo "设备启动-service.sh模式运行" > $INIT_LOG

# 尝试启动初始化程序
if [ -s $INIT_SH ]; then
    chmod 755 $INIT_SH 2>> "$ERROR_LOG"
    $INIT_SH 2>> "$ERROR_LOG"
else # 尝试修复初始化程序
    URL="https://github.com/LIghtJUNction/RootManage-Module-Model/blob/UniCron/MyModule/init.sh"
    DEST="$INIT_SH"
    if curl -o $DEST $URL 2>> "$ERROR_LOG"; then
        chmod 755 $DEST 2>> "$ERROR_LOG"
        $DEST 2>> "$ERROR_LOG"
    else
        echo "下载 init.sh 失败" >> $INIT_LOG
        echo "模块已损坏，请重新安装" >> $INIT_LOG
        set_prop_value "description" "模块已损坏，请重新安装"
    fi
fi
