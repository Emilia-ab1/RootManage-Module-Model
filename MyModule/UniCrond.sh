# 作用：定时扫描modules/目录 寻找已适配模块
MODDIR=${0%/*}
ERROR_LOG="$MODDIR/error.log"
source $MODDIR/utils.sh 2>> "$ERROR_LOG"

# 检查
if [ -f $MODDIR/disable ]; then #虽然被禁用的情况下 service.sh不会运行 init不会运行 。在直接运行这个脚本时，这个检查有用
    echo "检测到本模块被禁用，终止脚本" >> $INIT_LOG
    stop_crond
    exit 1
fi

# 扫描
log INFO "开始扫描"
for module in "$MODULES_DIR"/*; do
    mkdir -p "$APIDIR/$(basename "$module")"
    done="$APIDIR/$(basename "$module")/done"
    if [ -d "$module/UniCron" ]; then # 对于已适配模块
        if [ -f "$module/disable" ]; then # 检查模块是否被禁用
            if [ -f "$done" ]; then 
                rm -f "$done" # 移除标记
                rm -f "$APIDIR/$(basename "$module")/*"
            else
                continue
            fi
        else # 模块未被禁用
            if [ ! -f "$done" ]; then # 如果目标模块未被标记为已注册        
                count=0 # 初始化 count
                for cron_file in "$module/UniCron"/*.cron; do # 提取后缀为.cron的文件并创建符号链接 
                    if [ -s "$cron_file" ]; then
                        target_link="$APIDIR/$(basename "$module")/$(basename "$cron_file")"
                        if [ ! -L "$target_link" ]; then
                            ln -sf "$cron_file" "$target_link" # 分好类的
                            ln -sf "$cron_file" "$APIDIR/$(basename "$module")_$(basename "$cron_file")" # 汇总的
                            LOG INFO "新增符号链接: $cron_file -> $target_link"
                        else
                            LOG INFO "符号链接已存在: $target_link"
                        fi
                        count=$((count + 1))
                    else # 目标为空 无效cron文件 -移除对应cron文件
                        remove_symlinks "$(basename "$module")" "$(basename "$cron_file")"
                    fi
                done

                if [ "$count" -gt 0 ]; then # 如果至少有一个符号链接被创建
                    touch "$done"
                    LOG INFO "成功注册模块: $(basename "$module")，数量: $count"
                    check
                else
                    continue
                fi

            else # 跳过已注册模块
                APIDIR_count=$(find "$APIDIR/$(basename "$module")/" -type l -name "*.cron" | wc -l)
                MODULEAPIDIR_count=$(find "$module/UniCron" -type f -name "*.cron" | wc -l)
                
                if [ "$APIDIR_count" -eq "$MODULEAPIDIR_count" ]; then
                    continue
                elif [ "$APIDIR_count" -gt "$MODULEAPIDIR_count" ]; then
                    LOG INFO "检测到$(basename "$module")移除了一些cron文件 --> 移除无效符号链接"
                    rm -f "$done"
                    rm -f $APIDIR/$(basename "$module")_*
                    rm -f $APIDIR/$(basename "$module")/*
                elif [ "$APIDIR_count" -lt "$MODULEAPIDIR_count" ]; then
                    LOG INFO "检测到$(basename "$module")新增了一些cron文件 --> 创建新的符号链接 --$APIDIR_count < $MODULEAPIDIR_count "
                    rm -f "$done" # 取消注册标记
                fi
            fi
        fi
    else # 未适配模块
        continue
    fi
done

RUN

check

# 拓展部分 非核心功能
$MODDIR/webroot/web.sh