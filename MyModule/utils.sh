MODDIR=${0%/*}
LOGS=$MODDIR/logs
CRONDIR=$MODDIR/cron
CRONTABSDIR=$CRONDIR/crontabs
APIDIR=$MODDIR/API
UNICRONDIR=$MODDIR/UniCron
MODULES_DIR="/data/adb/modules"

# webroot
WEBROOT=$MODDIR/webroot
# webroot

mkdir -p $LOGS
mkdir -p $CRONDIR
mkdir -p $CRONTABSDIR
mkdir -p $APIDIR
mkdir -p $UNICRONDIR
mkdir -p $WEBROOT

INIT_SH=$MODDIR/init.sh # 初始化程序
INIT_LOG=$LOGS/init.log # 初始化日志
MODULE_LOG=$LOGS/UniCron.log #模块日志
unknown_process=$LOGS/unknown_process
CROND_PID=$LOGS/crond.pid
ALL_CRON=$CRONDIR/ALL.cron

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

initialize_files "$INIT_LOG" 666 # 确保日志可读
initialize_files "$MODULE_LOG" 666 #确保日志可读

initialize_files "$unknown_process" 666 # 未知crond/crontab进程，可能是其他模块的
initialize_files "$MODULE_PROP" 666 # 确保可读写
initialize_files "$CROND_PID" 666 # 锁文件
initialize_files "$ALL_CRON" 666 # 确保可读写



# 完成

# 基础函数 #########################################################
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
    # echo "数据 '$data' 已加入名单文件 '$list_file'" >> "$MODULE_LOG"
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

kill_processes() {
    local ALL="$1"
    local white_list="$2"
    
    if [ -z "$white_list" ]; then
        # 如果白名单不存在，杀死名单ALL中的所有进程
        while IFS= read -r pid; do
            if kill -9 "$pid" 2>/dev/null; then
                LOG INFO "已杀死进程 ID: $pid"
            else
                LOG ERROR "无法杀死进程 ID: $pid"
            fi
        done < "$ALL"
    else
        # 杀死名单ALL中不在白名单中的进程
        while IFS= read -r pid; do
            if ! grep -qw "$pid" "$white_list"; then
                if kill -9 "$pid" 2>/dev/null; then
                    LOG INFO "已杀死进程 ID: $pid"
                else
                    LOG ERROR "无法杀死进程 ID: $pid"
                fi
            fi
        done < "$ALL"
    fi
}

LOG() {
    local log_level=$1
    local log_content=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] $log_content" >> $MODULE_LOG
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

delete_empty_files() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f -empty -delete
        echo "已删除目录 $dir 中的所有空文件"
    else
        echo "目录 $dir 不存在"
    fi
}

###################################################################################
# 应急函数---特殊函数 init初始化时使用
remove_done_files() {
    for dir in "$APIDIR"/*/; do
        if [ -d "$dir" ]; then
            done_file="${dir}done"
            if [ -f "$done_file" ]; then
                rm -f "$done_file" && LOG INFO "已删除文件: $done_file"
            fi
        fi
    done
}
# 判断进程数量是否合理
get_crond_process_count() {
    pgrep -f "busybox crond -b -c $CRONTABSDIR" | wc -l
}
# 避免因为某些未知原因导致cron进程创建过多
KILL_ALL(){
    for pid in $(pgrep -f "busybox cron"); do
        kill $pid
        if [ $? -eq 0 ]; then
            echo "杀死 $pid"
        else
            echo "未能杀死 $pid"
        fi
    done
}

# 核心函数################################################
merge_cron() {
    local output_file="$CRONDIR/ALL.cron"
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
    else # 意外情况！
        LOG INFO "$APIDIR 未找到任何 .cron 文件!" 
        rm -f "$temp_file"
        remove_done_files # 意外情况-移除done标记，强制更新
        set_prop_value "description" "[ $(date) ]模块出错！"
        LOG ERROR "未找到任何 .cron 文件"
        merge_cron # 递归 -- 移除done标记符号后重试一次
        return 1 
    fi

    # 获取现有内容并比较
    if [ -f "$output_file" ]; then
        if cmp -s "$temp_file" "$output_file"; then
            # 文件相同，无需更新
            # LOG INFO "无需更新" 废话日志 
            rm -f "$temp_file"
            return 0
        else
            # 文件不同，更新输出文件
            mv "$temp_file" "$output_file"
            LOG INFO "合并的 cron 文件已更新"
            return 1
        fi
    else
        # 输出文件不存在，直接移动临时文件到输出文件
        mv "$temp_file" "$output_file"
        LOG INFO "合并的 cron 文件已创建"
        return 1
    fi
}


# DO ONE THING
crond(){
    # 启动 crond 返回PID
    busybox crond -b -c "$CRONTABSDIR" 2>>"$MODDIR/error.log"
    sleep 1  # 等待进程启动
    pid=$(pgrep -f "busybox crond -b -c $CRONTABSDIR" | head -n 1)
    echo "$pid" > "$CROND_PID"
}

crontab(){
    local file="$1"
    busybox crontab -c "$CRONTABSDIR" "$file"
}

stop_crond(){
    kill_processes $CROND_PID
}

UniCron_deamon(){

    local pid=$(cat $CROND_PID)
    if [ ! -d "/proc/$pid" ];then # 进程未在运行
        LOG ERROR "UniCrond被意外杀死，尝试复活"
        > $CROND_PID
        RUN init # 起死回生术
    fi
    local crond_count=$(get_crond_process_count)
    if [ "$crond_count" -gt 5 ]; then
        KILL_ALL
        LOG INFO "超过5个 crond 进程，已杀死全部 crond 进程"
        LOG INFO "即将复活------"
        sleep 3
        $INIT_SH
    else
        LOG INFO "当前 crond 进程数: $crond_count"
    fi
}


# 以上均为函数部分 新建目录/设置权限
#####################################################################
# 首次运行--运行crond  守护运行 --crontab
RUN() {
    local init=$1
    if [ "$init" = "init" ];then # 初始化运行模式
        if [ -s $UniCrond_cron ];then
            crontab "$UniCrond_cron"
            crond # 初始化的时候运行一次
            if [ $? -eq 0 ]; then
                LOG INFO "crond顺利启动"
            else
                LOG ERROR "crond初次运行失败！"  
            fi
        else
            echo "* * * * * /data/adb/modules/UniCron/UniCrond.sh" > $UniCrond_cron
            echo "* * * * 1,3,5 rm -f /data/adb/modules/logs/UniCron.log" >> $UniCrond_cron
            crontab "$UniCrond_cron"
            crond # 尝试救回进程
            if [ $? -eq 0 ]; then
                LOG INFO "crond启动！"
            else
                LOG ERROR "未知错误！请重新安装模块！"  
            fi
        fi
        
    else # 守护运行模式
        echo "守护模式"
        crontab $ALL_CRON
    fi
}



