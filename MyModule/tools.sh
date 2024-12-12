MODDIR=${0%/*}
CRONDIR="$MODDIR/cron"
CRONTAB_DIR="$CRONDIR/crontabs"
API_DIR="$MODDIR/API"
TASKS_DIR="$API_DIR/cron_tasks"
TMP_FILE="$API_DIR/tmp.cron"
BAK_FILE="$API_DIR/bak.cron"
CRON_TASKS_DIR="$API_DIR/cron_tasks"
MODULES_DIR="/data/adb/modules"
LOG_FILE="$MODDIR/UniCron.log"
SKIP_FILE="$MODDIR/skip"
MODULE_PROP="$MODDIR/module.prop"

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

set_module_description(){
    local new_description="$1"
    sed -i "s/^description=.*/description=$(printf '%s' "${new_description//\//\\/}")/" "${MODULE_PROP}"
}

cron_kill(){
    pkill -f "crond"  # 使用 pkill 根据进程名杀死所有 crond 进程
}
crontab_kill(){
    pkill -f "crontab"  # 杀死可能存在的 crontab 进程   
}

crond(){
    init=$1
    # 检查 crontab 配置是否需要更新
    if [ -f "$TMP_FILE" -o init]; then   
        # 强制杀死已有的 crond 进程，避免进程堆积
        cron_kill
        # 启动新的 crond 进程
        log INFO "cron启动"
        busybox crond -b -c "$CRONTAB_DIR"  # 启动 crond          
    fi
}

crontab(){
    # 检查 crontab 配置是否需要更新
    if [ -f "$TMP_FILE" ]; then       
        # 强制杀死正在运行的 crontab 进程，以确保不会有多个 crontab 进程
        crontab_kill
        log INFO "crontab更新配置"
        busybox crontab -c "$CRONTAB_DIR" "$TMP_FILE"  # 更新 crontab 配置
    fi
}

check(){
    busybox crontab -c "$CRONTAB_DIR" -l  # 检查
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
    # 比较两个文件的内容是否一致
    if ! cmp -s "$TMP_FILE" "$BAK_FILE"; then
        # 文件内容不一致，仅执行备份操作，不删除TMP_FILE，作为更新的信号📶
        log INFO "文件内容不一致，执行备份：$TMP_FILE -> $BAK_FILE"
        cat "$TMP_FILE" > "$BAK_FILE"  # 备份文件
    else
        # 文件内容一致，删除 TMP_FILE，无需重启小程序
        rm -f "$TMP_FILE"  # 删除文件
    fi
}