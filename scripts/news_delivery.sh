#!/bin/bash
# 归墟新闻推送 v5 — 千问 API 智能版
# cron: 0 4,8,12,16,20 * * *

WORKSPACE="/home/yihui/openclaw/workspace"
TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOUR=$(date '+%H:00')
DATE_STR=$(date '+%Y年%m月%d日')
BOT_TOKEN="8666894869:AAExYISpry1rPQOHnswHODGCBt0r4JYDJog"
CHAT_ID="2057636611"
PROXY="http://192.168.208.1:10808"
QWEN_KEY="sk-6eb7e47eaeba4a8ab734c8855f61488f"

mkdir -p "$WORKSPACE/logs"
LOG_FILE="$WORKSPACE/logs/news_${TODAY}_${HOUR//:/}.log"
log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log "=== 归墟新闻 v5 - ${HOUR} | ${DATE_STR} ==="

# 用千问 API 联网搜新闻 + 生成报告（直连，无需代理）
log "千问联网搜索中..."
QWEN_RESULT=$(curl -s -m 45 "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
  -H "Authorization: Bearer ${QWEN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-plus",
    "input": {
      "messages": [
        {"role": "system", "content": "你是一个实时新闻聚合助手。基于联网搜索结果，按以下格式输出今天最重要的国际新闻：\n\n🌍 中东/伊朗\n• 新闻1\n• 新闻2\n\n⚔️ 俄乌\n• ...\n\n🌏 亚太\n• ...\n\n🇺🇸 美国\n• ...\n\n💰 财经/币圈\n• ...\n\n每条新闻一句话。来源标注（新华/路透/法新/美联社）。如果某分类没有新闻就跳过该分类。"},
        {"role": "user", "content": "今天是${TODAY}，搜索今天最新的国际新闻，重点关注：中东伊朗局势、俄乌战争、台海南海、美国政治、加密货币。"}
      ]
    },
    "parameters": {
      "enable_search": true
    }
  }' 2>/dev/null)

NEWS_TEXT=$(echo "$QWEN_RESULT" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('output',{}).get('text',''))
except: print('')
" 2>/dev/null)

if [ -z "$NEWS_TEXT" ]; then
    log "❌ 千问API失败"
    REPORT="🚨 ${HOUR} 全球监控 | ${DATE_STR}\n\n⏰ ${NOW}\n\n⚠️ 新闻API暂不可用\n\n---\n📡 归墟监控"
    echo "❌ 千问API搜索失败: ${NOW}" > "$WORKSPACE/logs/news_latest.md"
else
    REPORT=$(printf "🚨 ${HOUR} 全球监控 | ${DATE_STR}\n\n⏰ ${NOW}\n\n%s\n\n---\n📡 归墟监控 v5 | 千问·百炼" "$NEWS_TEXT")
    # 同时存一份本地给归墟用，省得重复搜索浪费钱
    echo "# 新闻快讯 - ${DATE_STR} ${HOUR}" > "$WORKSPACE/logs/news_latest.md"
    echo "" >> "$WORKSPACE/logs/news_latest.md"
    echo "$NEWS_TEXT" >> "$WORKSPACE/logs/news_latest.md"
    log "📝 新闻内容已保存至 logs/news_latest.md"
fi

log "发送到 Telegram..."
RESPONSE=$(curl -m 20 -s -x "$PROXY" -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --connect-timeout 5 \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${REPORT}")
if echo "$RESPONSE" | grep -q '"ok":true'; then
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d: -f2)
    log "✅ 发送成功 ID:$MSG_ID"
    echo -e "\n## 📰 ${HOUR} 新闻推送\n- **时间**: ${NOW}\n- **状态**: ✅ (ID:$MSG_ID)" >> "$WORKSPACE/memory/${TODAY}.md"
else
    ERR=$(echo "$RESPONSE" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
    log "❌ 发送失败: ${ERR}"
fi
# 浏览器素材采集（静默追加）
log "浏览器素材采集..."
bash "$WORKSPACE/scripts/browser_collect.sh" 2>> "$LOG_FILE"
bash "$WORKSPACE/scripts/browser_summarize.sh" 2>> "$LOG_FILE"
log "=== 完成 ==="
