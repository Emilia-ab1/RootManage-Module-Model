#!/system/bin/sh
MODDIR=${0%/*}

CRONDIR="$MODDIR/cron"
CRONTAB_DIR="$CRONDIR/crontabs"
LOG_FILE="$MODDIR/Cron.log"

crond(){
    busybox crond -b -c "$CRONTAB_DIR"
}
crontab(){
    busybox crontab -b -c "$CRONTAB_DIR"
}

# 合并函数：合并所有模块的定时任务到 crontab
merge_crontabs(){
    CRONTAB_FILE="$CRONTAB_DIR/root"
    # 清空旧的 crontab 文件
    : > "$CRONTAB_FILE"
    # 合并所有任务
    for task in $TASKS_DIR/*; do
        if [ -f "$task" ]; then
            cat "$task" >> "$CRONTAB_FILE"
            echo "" >> "$CRONTAB_FILE"
        fi
    done
}

log() {
    [ ! -f "${LOG_FILE}" ] && touch "${LOG_FILE}"
    case $1 in
        INFO) color="${blue}" ;;
        Error) color="${red}" ;;
        Warning) color="${yellow}" ;;
        *) color="${green}" ;;
    esac
    current_time=$(formatted_date)
    message="${current_time} [$1]: $2"
    if [ -t 1 ]; then
        echo -e "${color}${message}${normal}"
    else
        echo "${message}" >> "${LOG_FILE}" 2>&1
    fi
}

merge_crontabs
crond

log DEBUG "测试"