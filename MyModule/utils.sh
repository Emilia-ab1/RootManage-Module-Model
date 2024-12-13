MODDIR=${0%/*}
LOGS=$MODDIR/logs
CRONDIR=$MODDIR/cron
CRONTABSDIR=$CRONDIR/crontabs
APIDIR=$MODDIR/API
UNICRONDIR=$MODDIR/UniCron
MODULES_DIR="/data/adb/modules"

mkdir -p $LOGS
mkdir -p $CRONDIR
mkdir -p $CRONTABSDIR
mkdir -p $APIDIR
mkdir -p $UNICRONDIR

INIT_SH=$MODDIR/init.sh # 初始化程序
INIT_LOG=$LOGS/init.log # 初始化日志
MODULE_LOG=$LOGS/UniCron.log #模块日志
unknown_process=$LOGS/unknown_process

UniCrond=$MODDIR/UniCrond.sh # 守护程序
UniCrond_cron=$UNICRONDIR/UniCrond.cron # 守护程序cron配置

MODULE_PROP=$MODDIR/module.prop

initialize_files() {
    local file=$1
    local permissions=$2
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    chmod "$permissions" "$file"
}

initialize_files "$INIT_SH" 755 
initialize_files "$UniCrond" 755 
initialize_files "$UniCrond_cron" 755 

initialize_files "$INIT_LOG" 777 # 确保日志可读
initialize_files "$MODULE_LOG" 777 #确保日志可读

initialize_files "$unknown_process" 644 # 未知crond/crontab进程，可能是其他模块的
initialize_files "$MODULE_PROP" 644 # 确保可读写

# 完成

# 读取 module.prop 文件中的值
get_prop_value() {
    local key=$1
    grep "^$key=" "$MODULE_PROP" | cut -d'=' -f2
}

# 修改 module.prop 文件中的值
set_prop_value() {
    local key="$1"
    local value="$2"
    
    # 将所有换行符替换为；
    value=$(echo "$value" | tr '\n' ';')
    
    if grep -q "^$key=" "$MODULE_PROP"; then
        # 使用 | 作为分隔符，避免与 / 冲突
        sed -i "s|^$key=.*|$key=$value|" "$MODULE_PROP"
    else
        echo "$key=$value" >> "$MODULE_PROP"
    fi
}
add_to_list() {
    local list_file=$1
    local data=$2
    # 确保名单文件存在
    if [ ! -f "$list_file" ]; then
        touch "$list_file"
        chmod 644 "$list_file"
    fi

    # 将数据添加到名单文件
    echo "$data" >> "$list_file"
    echo "数据 '$data' 已加入名单文件 '$list_file'" >> "$MODULE_LOG"
}

# 查询函数，检查文件的某一行是否包含指定字符串
is_in_list() {
    local list_file=$1
    local data=$2
    if grep -q "$data" "$list_file"; then
        return 0 # 真
    else
        return 1 # 假
    fi
}
# 解释: 这里的0/1表示退出状态码 正常退出是0 异常是1 

LOG() {
    local log_level=$1
    local log_content=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] $log_content" >> "$MODULE_LOG"
}

crond(){
    local pid_file="$LOGS/crond.pid"

    # 检查 crond 是否已经在运行
    if pgrep -f "busybox crond" >/dev/null; then
        echo "crond 已经在运行" >> "$MODULE_LOG"
        return 0
    fi

    # 启动 crond 并记录 PID
    busybox crond -b -c "$CRONTABSDIR"
    sleep 1  # 等待 crond 启动
    PID=$(pgrep -f "busybox crond")
    if [ -n "$PID" ]; then
        add_to_list "$pid_file" "$PID"
        echo "启动 crond，PID: $PID" >> "$MODULE_LOG"
    else
        echo "crond 启动失败" >> "$MODULE_LOG"
    fi
}

crontab(){
    local file="$1"
    # 安装 crontab 文件，无需记录 PID
    busybox crontab -c "$CRONTABSDIR" "$file"
    echo "刷新配置: $file" >> "$MODULE_LOG"
    cat $file >> "$MODULE_LOG"
}

stop_crond(){
    local pid_file="$LOGS/crond.pid"

    # 检查 pid 文件是否存在
    if [ ! -f "$pid_file" ]; then
        echo "crond pid 文件不存在" >> "$MODULE_LOG"
        return 1
    fi

    # 读取 pid 文件中的 PID
    local pid=$(cat "$pid_file")

    # 检查进程是否存在并终止
    if [ -n "$pid" ] && kill -0 "$pid" ; then
        kill "$pid"
        if [ $? -eq 0 ]; then
            echo "成功终止 crond 进程，PID: $pid" >> "$MODULE_LOG"
            rm -f "$pid_file"
        else
            echo "无法终止 crond 进程，PID: $pid" >> "$MODULE_LOG"
            return 1
        fi
    else
        echo "crond 进程不存在或已终止，PID: $pid" >> "$MODULE_LOG"
        rm -f "$pid_file"
        return 1
    fi
}


check(){
    if [ -s $CRONTABSDIR/root ]; then
        local Wow=$(cat "$CRONTABSDIR/root")
        set_prop_value "description" "$Wow"
    else
        set_prop_value "模块未正常启动！"
    fi
}

merge_cron() {
    local output_file="$CRONDIR/Unicron_merged.cron"
    local temp_file="$CRONDIR/temp_merged.cron"

    # 清空临时文件
    : > "$temp_file"

    # 检查是否有 .cron 文件
    if ls "$APIDIR"/*.cron >/dev/null 2>&1; then
        # 遍历 $APIDIR 目录下所有 .cron 文件并合并到临时文件中
        for cron_file in "$APIDIR"/*.cron; do
            cat "$cron_file" >> "$temp_file"
            echo >> "$temp_file"  # 添加实际的换行符以确保文件之间有分隔
        done
    else
        LOG INFO "未找到任何 .cron 文件"
        rm -f "$temp_file"
        return 1
    fi

    # 获取现有内容并比较
    if [ -f "$output_file" ]; then
        if cmp -s "$temp_file" "$output_file"; then
            # 文件相同，无需更新
            LOG INFO "无需更新"
            rm -f "$temp_file"
            return 1
        else
            # 文件不同，更新输出文件
            mv "$temp_file" "$output_file"
            LOG INFO "合并的 cron 文件已更新"
            return 0
        fi
    else
        # 输出文件不存在，直接移动临时文件到输出文件
        mv "$temp_file" "$output_file"
        LOG INFO "合并的 cron 文件已创建"
        return 0
    fi
}

RUN() {
    local init=$1
    if [ "$init" = "init" ];then
        crontab "$UniCrond_cron"
        crond # 初始化的时候运行一次
    else
        merge_cron
        if [ $? -eq 0 ]; then
            crontab "$CRONDIR/Unicron_merged.cron"
            return 1
        else
            return 0
        fi
    fi
}

remove_symlinks() {
    local moduleid="$1"
    local cron_file_name="$2"

    # 定义符号链接路径
    local module_cron_link="$APIDIR/$moduleid/$cron_file_name"
    local cron_link="$APIDIR/${moduleid}_${cron_file_name}"

    # 删除单个链接的函数
    delete_link() {
        local link_path="$1"
        if [ -e "$link_path" ]; then
            if [ -f "$link_path" ] || [ -L "$link_path" ]; then
                rm -f "$link_path"
                LOG INFO "移除符号链接: $link_path"
            else
                LOG ERROR "尝试删除文件 $link_path，但文件不是普通文件或符号链接。"
            fi
        else
            LOG ERROR "尝试删除文件 $link_path，但文件不存在。"
        fi
    }

    # 删除模块特定的 cron 链接
    delete_link "$module_cron_link"

    # 删除组合的 cron 链接
    delete_link "$cron_link"
}



