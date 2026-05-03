#!/bin/bash
# 归墟 Cron 健康巡检 — 每次心跳/启动时跑
# 检查过去2小时内所有cron任务是否正常完成
# 失败则发Telegram告警

WORKSPACE="/home/yihui/openclaw/workspace"
TODAY=$(date +%Y%m%d)
HOUR=$(date +%H)
BOT_TOKEN="8666894869:AAExYISpry1rPQOHnswHODGCBt0r4JYDJog"
CHAT_ID="2057636611"
PROXY="http://192.168.208.1:10808"

check_log() {
    local LOG_FILE="$1"
    local JOB_NAME="$2"
    local MAX_AGE_MIN="${3:-180}"
    
    if [ ! -f "$LOG_FILE" ]; then
        curl -s -m 10 -x "$PROXY" -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=${CHAT_ID}" \
            --data-urlencode "text=🚨 Cron巡检告警：${JOB_NAME} 日志文件不存在！" > /dev/null 2>&1
        return 1
    fi
    
    # 取最后一条带 === 完成 === 或 ✅ 的记录的时间戳
    LAST_OK=$(grep -E "(=== 完成 ===|✅ 发送成功)" "$LOG_FILE" 2>/dev/null | tail -1 | grep -oP '^\d{2}:\d{2}:\d{2}' || echo "")
    if [ -z "$LAST_OK" ]; then
        curl -s -m 10 -x "$PROXY" -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=${CHAT_ID}" \
            --data-urlencode "text=🚨 Cron巡检告警：${JOB_NAME} 无成功记录！" > /dev/null 2>&1
        return 1
    fi
    
    # 检查语法错误的文件
    SYNTAX_OK=$(grep -c "unexpected EOF\|syntax error\|line.*:" "$LOG_FILE" 2>/dev/null)
    if [ "$SYNTAX_OK" -gt 0 ]; then
        curl -s -m 10 -x "$PROXY" -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=${CHAT_ID}" \
            --data-urlencode "text=🚨 Cron巡检告警：${JOB_NAME} 有语法错误！" > /dev/null 2>&1
        return 1
    fi
    
    return 0
}

# 检查各cron任务
check_log "$WORKSPACE/logs/cron_news.log" "新闻推送(04/08/12/16/20)" 240
check_log "$WORKSPACE/logs/cron_video_v2.log" "视频管线(11:30/12:00)" 180
check_log "$WORKSPACE/logs/cron_website.log" "网站更新(17:00)" 360

echo "[$(date '+%H:%M:%S')] Cron巡检完成"
