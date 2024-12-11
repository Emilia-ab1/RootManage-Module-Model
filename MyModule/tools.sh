MODDIR=${0%/*}
CRONDIR="$MODDIR/cron"
CRONTAB_DIR="$CRONDIR/crontabs"
API_DIR="$MODDIR/API"
TASKS_DIR="$MODDIR/API/cron_tasks"
TMP_FILE="$API_DIR/tmp.cron"
CRON_TASKS_DIR="$MODDIR/API/cron_tasks"
MODULES_DIR="/data/adb/modules"

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
normal='\033[0m'

formatted_date() {
    date +"%Y-%m-%d %H:%M:%S.%3N"
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
    fi
    echo "${message}" >> "${LOG_FILE}" 2>&1
}

crond(){
    busybox crond -b -c "$CRONTAB_DIR"
}
crontab(){
    busybox crontab -c "$CRONTAB_DIR" $TMP_FILE
}
# 合并函数：合并所有模块的定时任务到 crontab
merge_crontabs(){
    # 清空旧的 crontab 文件
    > "$TMP_FILE"
    # 合并所有任务
    for task in "$TASKS_DIR"/*; do
        if [ -f "$task" ]; then
            cat "$task" >> "$TMP_FILE"
            echo "" >> "$TMP_FILE"
        fi
    done
}