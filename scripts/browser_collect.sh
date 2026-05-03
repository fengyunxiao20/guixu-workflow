#!/bin/bash
# 归墟·浏览器素材采集脚本
# 调用 Windows Chrome 无头浏览器自动抓取指定页面
# 每4小时执行一次（随新闻推送一起跑）
# 用法: ./browser_collect.sh [--force]

WORKSPACE="/home/yihui/openclaw/workspace"
BROWSE="$WORKSPACE/browse.js"
DATA_DIR="$WORKSPACE/data/browser_cache"
MATERIAL_DIR="$WORKSPACE/data/material"
LOG_FILE="$WORKSPACE/logs/browser_collect.log"
mkdir -p "$DATA_DIR" "$MATERIAL_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
TODAY=$(date '+%Y-%m-%d')
HOUR=$(date '+%H:00')
NOW=$(date '+%s')

# 锁：同一小时只跑一次
LOCKFILE="/tmp/browser_collect.lock"
if [ -f "$LOCKFILE" ]; then
  lock_age=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)))
  if [ "$lock_age" -lt 3300 ]; then  # <55分钟内不重复
    log "⏭ 本小时已采集过，跳过"
    exit 0
  fi
fi
touch "$LOCKFILE"

log "=== 浏览器素材采集 ${TODAY} ${HOUR} ==="

# ========= 采集目标列表 =========
# 格式: "类型|标签|URL"

# 类型,标签,URL（用逗号分隔，避免shell解析中文坑）
# 源列表 — 优先选服务端渲染的页面，避免JS重页面
# 源列表 — 优先选服务端渲染的页面
TARGETS=(
  "depth,aljazeera,https://www.aljazeera.com/tag/middle-east/"
  "depth,bbc_ukraine,https://www.bbc.com/news/world-europe-60506682"
  "news,france24_mideast,https://www.france24.com/en/middle-east/"
  "news,cnbc_crypto,https://www.cnbc.com/cryptocurrency/"
  "news,bbc_mideast_us,https://www.bbc.com/news/topics/c302m85qenwt"
  "news,npr_iran,https://www.npr.org/sections/middle-east/"
  "news,bbc_tech,https://www.bbc.com/news/technology"
  "news,ap_mideast,https://apnews.com/hub/mideast-conflicts"
)

SUCCESS=0
FAIL=0

for entry in "${TARGETS[@]}"; do
  IFS=',' read -r type tag url <<< "$entry"
  outfile="${DATA_DIR}/${type}_${tag}_${TODAY}_${HOUR//:/}.txt"
  
  # 检查今天是否已采集
  if [ -f "$outfile" ] && [ "$(stat -c %Y "$outfile" 2>/dev/null)" -gt "$(date -d 'today 00:00' +%s)" ]; then
    log "⏭ [${tag}] 今天已采集，跳过"
    continue
  fi

  log "🌐 [${tag}] 抓取: $url"
  result=$(node "$BROWSE" --text "$url" 2>/dev/null)
  
  if [ -n "$result" ] && [ ${#result} -gt 200 ]; then
    {
      echo "=== [${tag}] ${TODAY} ${HOUR} ==="
      echo "来源: $url"
      echo "抓取时间: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "$result"
    } > "$outfile"
    SUCCESS=$((SUCCESS + 1))
    log "✅ [${tag}] 成功 (${#result}字符)"
  else
    log "❌ [${tag}] 失败或无内容"
    FAIL=$((FAIL + 1))
  fi
done

# ========= 截图采集 =========
# 每周截一次关键信息图（周报用）
DOW=$(date +%u)  # 1=周一, 7=周日
if [ "$DOW" = "1" ] && [ "$HOUR" = "08:00" ]; then
  log "📸 周一截图采集..."
  SCREENSHOT_DIR="$MATERIAL_DIR/screenshots"
  mkdir -p "$SCREENSHOT_DIR"
  SCREENSHOTS=(
    "coindesk|https://coindesk.com"
    "tradingview_btc|https://www.tradingview.com/symbols/BTCUSD/"
  )
  for s_entry in "${SCREENSHOTS[@]}"; do
    IFS='|' read -r s_name s_url <<< "$s_entry"
    sf="${SCREENSHOT_DIR}/${s_name}_${TODAY}.png"
    if [ ! -f "$sf" ]; then
      node "$BROWSE" --screenshot "$s_url" 2>/dev/null
      # 把最新截图改名
      latest=$(ls -t "$WORKSPACE/browser_output/"screenshot_*.png 2>/dev/null | head -1)
      [ -n "$latest" ] && cp "$latest" "$sf" && log "📸 [$s_name] 截图保存"
    fi
  done
fi

log "=== 采集完成: 成功${SUCCESS} 失败${FAIL} ==="
echo "$HOUR|$SUCCESS|$FAIL" >> "$WORKSPACE/logs/browser_collect_daily.csv" 2>/dev/null
