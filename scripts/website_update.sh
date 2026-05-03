#!/bin/bash
# ======================================================
# 归墟网站更新脚本 v1 — 2026-05-02
# 基于 MEMORY.md 中的 curl POST 方式，无需SSH
# cron: 0 17 * * *
# ======================================================

WORKSPACE="/home/yihui/openclaw/workspace"
TODAY=$(date '+%Y-%m-%d')
DATE_STR=$(date '+%Y年%m月%d日')
LOG="$WORKSPACE/logs/cron_website.log"
COOKIE_JAR="/tmp/tc_jar.txt"
BOT_TOKEN="8666894869:AAExYISpry1rPQOHnswHODGCBt0r4JYDJog"
CHAT_ID="2057636611"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }
tel_msg() { curl -s -m 15 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" -d "text=$1" > /dev/null 2>&1; }

log "=== 归墟网站更新 | ${TODAY} ==="

# 先看看今天的新闻摘要，作为文章素材
NEWS_FILE="$WORKSPACE/logs/news_latest.md"
if [ ! -f "$NEWS_FILE" ]; then
    log "⚠️ 今日新闻摘要不存在，跳过"
    tel_msg "⚠️ 网站更新跳过：今日新闻摘要未找到"
    exit 0
fi

# 用千问生成今日新闻文章
log "→ 生成新闻文章..."
QWEN_KEY="sk-6eb7e47eaeba4a8ab734c8855f61488f"
NEWS_CONTENT=$(cat "$NEWS_FILE")

# 用python安全构建JSON payload（避免shell变量展开破坏JSON）
PAYLOAD_FILE="/tmp/tc_article_payload_$$.json"
python3 -c "
import json
with open('${NEWS_FILE}') as f:
    news = f.read()[:1500]
payload = {
    'model': 'qwen-plus',
    'input': {
        'messages': [
            {'role': 'system', 'content': '你是一个新闻编辑。基于提供的新闻摘要，写一篇简短精炼的今日国际新闻综述。Markdown格式。包含小标题。每条新闻附来源。字数300-500字。'},
            {'role': 'user', 'content': f\"以下是今日新闻摘要，请写一篇新闻综述：\\n\\n{news}\"}
        ]
    },
    'parameters': {'enable_search': True, 'result_format': 'text'}
}
with open('${PAYLOAD_FILE}', 'w', encoding='utf-8') as f:
    json.dump(payload, f, ensure_ascii=False)
" 2>/dev/null

ARTICLE_RESP=$(curl -s -m 60 "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
    -H "Authorization: Bearer ${QWEN_KEY}" \
    -H "Content-Type: application/json" \
    --data-binary @"${PAYLOAD_FILE}")
rm -f "${PAYLOAD_FILE}"

ARTICLE_TEXT=$(echo "$ARTICLE_RESP" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('output',{}).get('text',''))
except:
    print('')
" 2>/dev/null)

if [ -z "$ARTICLE_TEXT" ]; then
    log "❌ 文章生成失败"
    tel_msg "⚠️ 网站更新：文章生成失败"
    exit 1
fi

# 清理多余的markdown包裹
ARTICLE_TEXT=$(echo "$ARTICLE_TEXT" | sed 's/^```markdown//;s/^```//;s/```$//')

log "✅ 文章已生成 ($(echo "$ARTICLE_TEXT" | wc -c)字)"
echo "$ARTICLE_TEXT" > "$WORKSPACE/logs/article_${TODAY}.md"

# === 登录并发布到博客 ===
log "→ 登录博客..."
rm -f "$COOKIE_JAR"

# 1) 获取登录页面token
curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -L -m 10 \
    -H "User-Agent: Mozilla/5.0" \
    "https://me.baohui88.top/admin/login.php" > /tmp/tc_login.html 2>/dev/null

TOKEN=$(grep -oP 'action="[^"]*\\?_=\K[0-9a-f]+' /tmp/tc_login.html | head -1)
if [ -z "$TOKEN" ]; then
    log "❌ 登录页面token获取失败"
    tel_msg "⚠️ 网站更新：登录失败"
    exit 1
fi

# 2) 登录
curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -L -m 15 \
    -H "User-Agent: Mozilla/5.0" \
    -H "Referer: https://me.baohui88.top/admin/login.php" \
    -d "name=yihui" -d "password=ybh78520" -d "remember=1" \
    "https://me.baohui88.top/index.php/action/login?_=$TOKEN" > /dev/null 2>&1

# 3) 获取写文章token
PAGE=$(curl -s -b "$COOKIE_JAR" -m 10 \
    -H "User-Agent: Mozilla/5.0" \
    "https://me.baohui88.top/admin/write-post.php" 2>/dev/null)

POST_TOKEN=$(echo "$PAGE" | grep -oP 'contents-post-edit\?_=\K[0-9a-f]+' | head -1)
if [ -z "$POST_TOKEN" ]; then
    POST_TOKEN=$(echo "$PAGE" | python3 -c "
import sys, re
sys.stdin.reconfigure(errors='replace')
page = sys.stdin.read()
m = re.search(r'contents-post-edit\?=([0-9a-f]+)', page)
print(m.group(1) if m else '')" 2>/dev/null)
fi
if [ -z "$POST_TOKEN" ]; then
    log "❌ 文章token获取失败"
    tel_msg "⚠️ 网站更新：获取发布token失败"
    exit 1
fi

# 4) 发布文章（新闻分类=4）
TITLE="国际新闻速递 · ${DATE_STR}"

# 发布文章（shell curl + 完整参数，已验证可行）
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" -m 15 \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    -H "Referer: https://me.baohui88.top/admin/write-post.php" \
    -H "Origin: https://me.baohui88.top" \
    -d "title=${TITLE}" \
    -d "text=${ARTICLE_TEXT}" \
    -d "do=publish" \
    -d "markdown=1" \
    -d "category[]=4" \
    -d "tags=国际新闻,今日热点,${TODAY}" \
    "https://me.baohui88.top/index.php/action/contents-post-edit?_=${POST_TOKEN}" > /tmp/tc_publish_result.html 2>&1

# 检查发布结果
if [ -s /tmp/tc_publish_result.html ] && grep -q "manage-posts\|Location" /tmp/tc_publish_result.html 2>/dev/null; then
    log "✅ 文章发布成功: ${TITLE}"
    tel_msg "🌐 网站已更新
📰 ${TITLE}
https://me.baohui88.top/"
else
    log "⚠️ 发布结果未知，检查页面确认"
    tel_msg "🌐 网站更新执行完毕，请检查 https://me.baohui88.top/ 确认"
fi

log "=== 完成 ==="
