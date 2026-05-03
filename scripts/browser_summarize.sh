#!/bin/bash
# 归墟·浏览器素材摘要生成
# 每天12:00和20:00各跑一次，把 raw 数据精炼成文案参考
# 输出到 workspace/data/material/daily_summary_YYYY-MM-DD.md

WORKSPACE="/home/yihui/openclaw/workspace"
CACHE_DIR="$WORKSPACE/data/browser_cache"
SUMMARY_DIR="$WORKSPACE/data/material"
LOG="$WORKSPACE/logs/browser_summarize.log"
TODAY=$(date '+%Y-%m-%d')
HOUR=$(date '+%H:00')
mkdir -p "$SUMMARY_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

OUTFILE="${SUMMARY_DIR}/daily_summary_${TODAY}.md"

log "=== 素材摘要生成 ${TODAY} ${HOUR} ==="

# 收集今天所有缓存文件
FILES=$(ls -t "$CACHE_DIR"/*_${TODAY}_*.txt 2>/dev/null)

if [ -z "$FILES" ]; then
  log "⚠️ 今天没有缓存文件"
  echo "# 📡 浏览器素材采集 — ${TODAY}" > "$OUTFILE"
  echo "" >> "$OUTFILE"
  echo "_暂无数据_" >> "$OUTFILE"
  exit 0
fi

{
  echo "# 📡 浏览器素材采集 — ${TODAY}"
  echo ""
  echo "_生成时间: $(date '+%Y-%m-%d %H:%M:%S')_"
  echo ""
  
  for f in $FILES; do
    basename=$(basename "$f" .txt)
    # 从文件名解析类型和标签：type_tag_date_time
    IFS='_' read -r ftype ftag fdate ftime <<< "$basename"
    
    echo "---"
    echo "## [${ftype}] ${ftag}"
    echo "_${fdate} ${ftime}_"
    echo ""
    
    # 提取正文前50行做摘要（去掉开头元信息）
    content=$(tail -n +5 "$f" 2>/dev/null | head -80)
    if [ -n "$content" ]; then
      echo '```'
      echo "$content"
      echo '```'
    else
      echo "_(空)_"
    fi
    echo ""
  done
} > "$OUTFILE"

log "✅ 摘要已生成: $OUTFILE ($(wc -c < "$OUTFILE")字节)"
