# 本脚本每天6点执行一次，避免日志文件
# 检查日志文件行数，超过500行则删除旧日志
log_lines=$(wc -l < "${LOG_FILE}")
if [ "$log_lines" -gt 500 ]; then
    tail -n 500 "${LOG_FILE}" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "${LOG_FILE}"
fi
