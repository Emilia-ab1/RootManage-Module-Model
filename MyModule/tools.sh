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

set_module_description() {
    local new_description="$1"
    sed -i "s/^description=.*/description=$(printf '%s' "${new_description//\//\\/}")/" "${MODULE_PROP}"
}

crond() {
    init=$1
    # 检查 crontab 配置是否需要更新，只有当 $init 为非0 或 $TMP_FILE 存在时才更新
    if [ -f "$TMP_FILE" ] || [ "$init" -ne 0 ]; then
        # 强制杀死已有的 crond 进程，避免进程堆积
        crond_kill
        # 启动新的 crond 进程
        log INFO "crond运行"
        busybox crond -b -c "$CRONTAB_DIR"  # 启动 crond
    fi
}

crontab() {
    init=$1
    # 检查 crontab 配置是否需要更新，只有当 $init 为非0 或 $TMP_FILE 存在时才更新
    if [ -f "$TMP_FILE" ] || [ "$init" -ne 0 ]; then
        # 强制杀死正在运行的 crontab 进程，以确保不会有多个 crontab 进程
        crontab_kill
        log INFO "crontab运行"
        busybox crontab -c "$CRONTAB_DIR" "$TMP_FILE"  # 更新 crontab 配置
    fi
}

crond_kill() {
    log INFO "杀死crond"
    pkill -f "crond"  # 使用 pkill 根据进程名杀死所有 crond 进程
}

crontab_kill() {
    log INFO "杀死crontab"
    pkill -f "crontab"  # 使用 pkill 根据进程名杀死所有 crond 进程
}

check() {
    crontab_output="$(busybox crontab -c "$CRONTAB_DIR" -l)"
    
    if [ -z "$crontab_output" ]; then
        echo -n "目前没有设置任何定时任务。"
    else
        while read -r line; do
            # 忽略注释和空行
            echo "$line" | grep -q "^#" || [ -z "$line" ] && continue
            
            # 提取 Cron 时间表达式和命令
            schedule=$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')
            command=$(echo "$line" | awk '{for (i=6; i<=NF; i++) printf $i " "; print ""}')
            
            # 分解 Cron 表达式
            IFS=' ' read -r minute hour day month weekday <<< "$schedule"
            
            # 转换为简化的自然语言描述
            time_desc=""
            if [ "$minute" == "*" ]; then
                time_desc="每分钟执行"
            elif [[ "$minute" == */* ]]; then
                time_desc="每${minute#*/}分钟执行"
            else
                time_desc="每小时第$minute分钟执行"
            fi

            if [ "$hour" != "*" ]; then
                time_desc="$time_desc 每天$hour点执行"
            fi
            if [ "$day" != "*" ]; then
                time_desc="$time_desc 每月$day号执行"
            fi
            if [ "$month" != "*" ]; then
                time_desc="$time_desc 每年$month月执行"
            fi
            if [ "$weekday" != "*" ]; then
                case "$weekday" in
                    "0"|"7") time_desc="$time_desc 每周日执行" ;;
                    "1") time_desc="$time_desc 每周一执行" ;;
                    "2") time_desc="$time_desc 每周二执行" ;;
                    "3") time_desc="$time_desc 每周三执行" ;;
                    "4") time_desc="$time_desc 每周四执行" ;;
                    "5") time_desc="$time_desc 每周五执行" ;;
                    "6") time_desc="$time_desc 每周六执行" ;;
                esac
            fi

            # 输出简化的定时任务描述
            echo -n "$time_desc ：$(basename "$command") "
        done <<< "$crontab_output"
    fi
}

# 合并函数：合并所有模块的定时任务到 crontab
merge_crontabs() {
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
        cat "$TMP_FILE" > "$BAK_FILE"  # 备份文件 -- 需要更新！
        crontab 0
        rm -f $TMP_FILE

    else
        # 文件内容一致，删除 TMP_FILE，无需重启小程序
        rm -f "$TMP_FILE"  # 删除文件
    fi
}

UniCronMain() {
    log INFO “开始扫描”
    for module in "$MODULES_DIR"/*; do
    
        if [ -d "$module/UniCron" ]; then
            if [ -f "$module/disable" ]; then # 检查模块是否被禁用
                if [ -f "$module/UniCron/done" ]; then 
                    rm -f "$module/UniCron/done"
                    for cron_file in "$module/UniCron"/*.cron; do
                        if [ -f "$cron_file" ]; then
                            target_link="$CRON_TASKS_DIR/$(basename "$cron_file")"
                            if [ -L "$target_link" ]; then
                                rm "$target_link"
                                log INFO "删除符号链接: $target_link"
                            fi
                        fi
                    done
                else
                    continue
                fi
            else # 模块未被禁用
                if [ ! -f "$module/UniCron/done" ]; then # 提取后缀为.cron的文件并创建符号链接               
                    count=0
                    for cron_file in "$module/UniCron"/*.cron; do
                        if [ -f "$cron_file" ]; then
                            target_link="$CRON_TASKS_DIR/$(basename "$cron_file")"
                            if [ ! -L "$target_link" ]; then
                                ln -sf "$cron_file" "$target_link"
                                log INFO "新增符号链接: $cron_file -> $target_link"
                            else
                                log INFO "符号链接已存在: $target_link"
                            fi
                            count=$((count + 1))
                        fi
                    done
                                    
                    if ((count > 0)); then # 如果至少有一个符号链接被创建
                        touch "$module/UniCron/done"
                        log INFO "成功注册模块: $module，数量: $count"
                    else
                        log ERROR "$module/UniCron/为空"
                    fi
                else # 跳过已注册模块
                    continue
                fi
            fi
        else # 未适配模块
            continue
        fi
    done

    # 遍历 cron_tasks 目录，删除无效的符号链接
    for cron_link in "$CRON_TASKS_DIR"/*.cron; do
        if [ -L "$cron_link" ]; then
            target=$(readlink "$cron_link")
            if [ ! -f "$target" ]; then
                rm "$cron_link"
                log INFO "删除无效符号链接: $cron_link"
            fi
        fi
    done

    merge_crontabs
}
