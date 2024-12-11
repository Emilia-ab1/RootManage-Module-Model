MODDIR=${0%/*}
source $MODDIR/tools.sh # 导入工具函数
# 本内置项目1分钟检查一次
# for循环读取data/adb/modules/里面的每一个模块，除了(UniCron本身)。如果有Unicron文件夹，则提取里面后缀为.cron的文件创建一个符号链接到$MODDIR/API/cron_tasks/

# 遍历所有模块目录
for module in "$MODULES_DIR"/*; do
    # 跳过UniCron本身的目录
    if [ "$(basename "$module")" = "UniCron" ]; then
        continue
    fi

    if [ -d "$module/UniCron" ];   then
        # 检查done文件
        if [ -f "$module/UniCron/done" -o -f "$module/UniCron/null" ]; then
            continue
        
        else
            log INFO "发现UniCron文件夹: $module/UniCron"
            
            # 提取后缀为.cron的文件并创建符号链接
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
                fi
            done
            # 如果至少有一个符号链接被创建
            if ((count > 0)); then
                touch "$module/UniCron/done"
                log INFO "成功注册模块！: $module，数量：$count"
            else
                log ERROR "$module/UniCron/为空，是不是忘记了？"
            fi
        fi

    else
        if [ -f "$module/UniCron/null" ]; then
            continue
        else
            mkdir "${module}/UniCron/"
            touch "${module}/UniCron/null"
            log INFO "$module模块未适配!"
        fi
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
crontab
crond