#!/bin/bash
# ======================================================
# 归墟视频管线 v2 — 带xfade转场版
# 用法: bash scripts/video_pipeline_v2.sh [武|文] [主题]
# ======================================================
set -e
WORKSPACE="/home/yihui/openclaw/workspace"
VENV="$WORKSPACE/venv"
source "$VENV/bin/activate" 2>/dev/null || true
DATE_STR=$(date +%Y%m%d)
TS=$(date +%s)
LOG="$WORKSPACE/logs/video_v2_${DATE_STR}.log"
MATERIAL_DIR="/mnt/d/归墟文件夹/素材"
OUTPUT_DIR="/mnt/d/归墟文件夹/生成视频"
FONT="/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
unset HTTP_PROXY HTTPS_PROXY

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }
tel_msg() { 
    curl -s -m 15 -X POST "https://api.telegram.org/bot8666894869:AAExYISpry1rPQOHnswHODGCBt0r4JYDJog/sendMessage" \
        -d "chat_id=2057636611" -d "text=$1" > /dev/null 2>&1 || true
}

TYPE="${1:-武}"
TOPIC="${2:-}"
mkdir -p "$WORKSPACE/logs" "$MATERIAL_DIR"

log "=== 🎬 归墟视频管线 v2 | ${TYPE} | $(date) ==="

# 1) 用千问写文案 — 优先读本地新闻，省搜索费
log "[1/4] 千问生成文案..."
QWEN_KEY="sk-6eb7e47eaeba4a8ab734c8855f61488f"
QWEN_URL="https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

TYPE_PROMPT="军事冲突/战场实况/中东局势"
SEARCH_KW="Iran war 2026 military combat news"
if [ "$TYPE" = "文" ]; then
    TYPE_PROMPT="经济影响/能源价格/地缘博弈"
    SEARCH_KW="oil price global economy supply chain crisis"
fi

# 先读本地已有新闻，有就不联网搜索（省钱）
LOCAL_NEWS=""
if [ -f "$WORKSPACE/logs/news_latest.md" ]; then
    LOCAL_NEWS=$(head -80 "$WORKSPACE/logs/news_latest.md" 2>/dev/null)
fi

if [ -n "$LOCAL_NEWS" ] && [ ${#LOCAL_NEWS} -gt 100 ]; then
    log "📖 使用本地新闻 (news_latest.md)，跳过联网搜索"
    QWEN_RESP=$(curl -s -m 30 "$QWEN_URL" \
        -H "Authorization: Bearer $QWEN_KEY" \
        -H "Content-Type: application/json" \
        -d '{"model":"qwen-plus","input":{"messages":[{"role":"system","content":"你是归墟短视频文案助手。基于今日新闻，出50秒短视频4段式文案。每段1-2句。包含具体数据。结尾固定语「风云带你看实时」。只输出纯台词，每行一段，共4行。"},{"role":"user","content":"以下是今日新闻：'$LOCAL_NEWS'。请据此写一篇'$TYPE_PROMPT'方向的50秒短视频文案，4段式，包含具体数据，结尾「风云带你看实时」。"}]},"parameters":{"enable_search":false,"result_format":"text"}}' 2>/dev/null)
else
    log "🔍 无本地新闻，触发联网搜索"
    QWEN_RESP=$(curl -s -m 60 "$QWEN_URL" \
        -H "Authorization: Bearer $QWEN_KEY" \
        -H "Content-Type: application/json" \
        -d '{"model":"qwen-plus","input":{"messages":[{"role":"system","content":"你是归墟短视频文案助手。基于今日新闻，出50秒短视频4段式文案。每段1-2句。包含具体数据。结尾固定语「风云带你看实时」。只输出纯台词，每行一段，共4行。"},{"role":"user","content":"写一篇'"'"'$TYPE_PROMPT'"'"'方向的50秒短视频文案，4段式，包含具体数据，结尾「风云带你看实时」。"}]},"parameters":{"enable_search":true,"result_format":"text"}}' 2>/dev/null)
fi

SCRIPT=$(echo "$QWEN_RESP" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    t=d.get('output',{}).get('text','')
    t=t.replace('\x60\x60\x60','').strip()
    print(t)
except: print('')" 2>/dev/null)

if [ ${#SCRIPT} -lt 20 ]; then
    log "❌ 文案生成失败"
    exit 1
fi

echo "$SCRIPT" > "$WORKSPACE/logs/script_${TYPE}_${DATE_STR}.txt"
log "✅ 文案 ($(echo "$SCRIPT" | wc -c)字)"

# 2) 用edge-tts生成配音
log "[2/4] 配音..."
mapfile -t LINES <<< "$SCRIPT"
# 只取前4行
TEXTS=("${LINES[@]:0:4}")
while [ ${#TEXTS[@]} -lt 4 ]; do TEXTS+=("风云带你看实时"); done

for i in 0 1 2 3; do
    txt="${TEXTS[$i]}"
    python3 -c "
import asyncio
from edge_tts import Communicate
async def main():
    await Communicate('$txt', 'zh-CN-YunxiNeural').save('/tmp/vp2_audio_${TS}_${i}.mp3')
asyncio.run(main())
" 2>/dev/null
    log "  配音$((i+1)) ✅"
done

# 3) 素材搜索+下载
log "[3/4] 素材..."
python3 -c "
import subprocess, json, sys, os
q = '$SEARCH_KW'
r = subprocess.run(['yt-dlp','--flat-playlist','--dump-json','ytsearch5:'+q],
    capture_output=True, text=True, timeout=30)
ids = []
for line in r.stdout.strip().split('\n'):
    if not line: continue
    try:
        d = json.loads(line)
        dur = d.get('duration',0) or 0
        if 10 <= dur <= 300:
            ids.append(d['id'])
    except: pass
print('\n'.join(ids[:4]))
" 2>/dev/null > /tmp/vp2_vids_${TS}.txt

mapfile -t VIDS < /tmp/vp2_vids_${TS}.txt
if [ ${#VIDS[@]} -lt 4 ]; then
    # fallback
    VIDS=("NMQ2dqEjk1o" "Qjr5C6uXRnw" "swrPbJI9GEg" "inD28Mdk7-Y")
fi

MATS=()
for i in 0 1 2 3; do
    vid="${VIDS[$i]}"
    out="$MATERIAL_DIR/vp2_${TYPE}_${TS}_${vid}.webm"
    MATS+=("$out")
    if [ -f "$out" ]; then
        log "  → $vid 已有"
        continue
    fi
    log "  → 下载 $vid"
    yt-dlp -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' \
        --download-sections '*00:05-00:20' --force-keyframes-at-cuts \
        --ignore-errors --no-warnings -q \
        -o "$out" "https://youtube.com/watch?v=$vid" 2>/dev/null || true
done

# 检查素材可用性
AVAILABLE_MATS=()
for m in "${MATS[@]}"; do
    [ -f "$m" ] && AVAILABLE_MATS+=("$m")
done

if [ ${#AVAILABLE_MATS[@]} -lt 4 ]; then
    log "⚠️ 素材不足(${#AVAILABLE_MATS[@]}个)，用老素材补"
    # 从老素材里找
    for m in "$MATERIAL_DIR"/vp_${TYPE}_*.webm; do
        [ -f "$m" ] && AVAILABLE_MATS+=("$m")
        [ ${#AVAILABLE_MATS[@]} -ge 4 ] && break
    done
fi

log "✅ 素材: ${#AVAILABLE_MATS[@]}个"

# 4) 合成（带xfade转场）
log "[4/4] 合成（xfade转场）..."

# 4a) 生成4段带字幕的视频（9秒，留末1秒给过渡）
for i in 0 1 2 3; do
    mat="${AVAILABLE_MATS[$i]}"
    txt="${TEXTS[$i]}"
    ffmpeg -y -ss 2 -t 9 \
        -i "$mat" \
        -i "/tmp/vp2_audio_${TS}_${i}.mp3" \
        -filter_complex "\
            [0:v]scale=608:1080:force_original_aspect_ratio=decrease,pad=608:1080:(ow-iw)/2:(oh-ih)/2:black,drawtext=text='${txt}':fontfile=$FONT:fontcolor=white:fontsize=26:x=(w-text_w)/2:y=h-100:box=1:boxcolor=black@0.4:boxborderw=6,fade=t=out:st=8.5:d=0.5[v];\
            [1:a]adelay=200|200[a]" \
        -map "[v]" -map "[a]" \
        -c:v libx264 -preset fast -crf 26 -pix_fmt yuv420p -r 30 \
        -c:a aac -b:a 96k -ar 44100 \
        -shortest \
        "/tmp/vp2_seg_${TS}_${i}.mp4" 2>/dev/null
    log "  段$((i+1)) ✅ $(ls -lh /tmp/vp2_seg_${TS}_${i}.mp4 | awk '{print $5}')"
done

# 4b) xfade视频过渡
ffmpeg -y \
    -i /tmp/vp2_seg_${TS}_0.mp4 \
    -i /tmp/vp2_seg_${TS}_1.mp4 \
    -i /tmp/vp2_seg_${TS}_2.mp4 \
    -i /tmp/vp2_seg_${TS}_3.mp4 \
    -filter_complex "\
        [0:v][1:v]xfade=transition=fade:duration=1:offset=8[v01];\
        [v01][2:v]xfade=transition=fade:duration=1:offset=16[v012];\
        [v012][3:v]xfade=transition=fade:duration=1:offset=24[outv]" \
    -map "[outv]" \
    -c:v libx264 -preset fast -crf 26 -pix_fmt yuv420p \
    "/tmp/vp2_video_${TS}.mp4" 2>/dev/null

# 4c) 音频跨淡
python3 -c "
import subprocess, os, sys
ts = '$TS'
# 直接concat音频
inputs = [f'/tmp/vp2_audio_{ts}_{i}.mp3' for i in range(4)]
# 简单concat
concat = f'/tmp/vp2_audio_concat_{ts}.txt'
with open(concat, 'w') as f:
    for p in inputs:
        f.write(f\"file '{p}'\n\")
subprocess.run(['ffmpeg','-y','-f','concat','-safe','0',
    '-i', concat, '-c', 'copy', f'/tmp/vp2_audio_{ts}.mp3'],
    capture_output=True, timeout=30)
" 2>/dev/null

# 4d) 音视频合成+输出
OUTPUT="$WORKSPACE/vp2_output_${TYPE}_${DATE_STR}.mp4"
ffmpeg -y \
    -i "/tmp/vp2_video_${TS}.mp4" \
    -i "/tmp/vp2_audio_${TS}.mp3" \
    -c:v copy -c:a aac -b:a 96k \
    -map 0:v -map 1:a -shortest \
    "$OUTPUT" 2>/dev/null

# 验证
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT" 2>/dev/null)
HAS_V=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$OUTPUT" 2>/dev/null)
HAS_A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$OUTPUT" 2>/dev/null)

if [ -f "$OUTPUT" ] && [ -n "$HAS_V" ] && [ -n "$HAS_A" ]; then
    cp "$OUTPUT" "$OUTPUT_DIR/归墟视频_${TYPE}_${DATE_STR}.mp4"
    SZ=$(ls -lh "$OUTPUT" | awk '{print $5}')
    log "✅ 完成: ${DUR}s / ${SZ}"
    tel_msg "🎬 归墟出片【${TYPE}】
时长: $(printf '%.0f' $DUR)s
大小: ${SZ}
已保存至桌面文件夹"
else
    log "❌ 合成失败"
    tel_msg "❌ 视频合成失败，请检查日志"
fi

log "=== 管线完成 ==="
