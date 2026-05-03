#!/bin/bash
# ======================================================
# 归墟短视频自动生成管线
# 用法: bash scripts/video_pipeline.sh [武|文] [主题]
# ======================================================

set -e
WORKSPACE="/home/yihui/openclaw/workspace"
VENV="$WORKSPACE/venv"
source "$VENV/bin/activate" 2>/dev/null || true
DATE_STR=$(date +%Y%m%d)
TS=$(date +%s)
LOG="$WORKSPACE/logs/video_${DATE_STR}.log"
MATERIAL_DIR="/mnt/d/归墟文件夹/素材"
OUTPUT_DIR="/mnt/d/归墟文件夹/生成视频"

# Telegram
BOT_TOKEN="8666894869:AAExYISpry1rPQOHnswHODGCBt0r4JYDJog"
CHAT_ID="2057636611"

# 取消代理设置 - 直连更快
# export HTTP_PROXY=http://192.168.208.1:10808
# export HTTPS_PROXY=http://192.168.208.1:10808
unset HTTP_PROXY HTTPS_PROXY

# 千问百炼
QWEN_KEY="sk-6eb7e47eaeba4a8ab734c8855f61488f"
QWEN_URL="https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

mkdir -p "$WORKSPACE/logs" "$MATERIAL_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }
tel_msg() { curl -s -m 15 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" -d "text=$1" > /dev/null 2>&1 || log "⚠️ 通知发送失败"; }

TYPE="${1:-武}"
TOPIC="${2:-}"

log "=== 🎬 归墟视频管线 | ${TYPE} ==="
log "时间: $(date)"

# ===== 步骤1: 千问写文案 =====
log "[1/5] 千问写文案..."

log "→ 搜索今日新闻..."

if [ "$TYPE" = "武" ]; then
    NEWS_QUERY="2026年$(date +%m)月$(date +%d)日 国际军事冲突 最新战况 关键数据"
else
    NEWS_QUERY="2026年$(date +%m)月$(date +%d)日 全球经济 能源 地缘政治 影响数据"
fi

NEWS_RESP=$(curl -s -m 60 "$QWEN_URL"     -H "Authorization: Bearer $QWEN_KEY"     -H "Content-Type: application/json"     -d '{
        "model": "qwen-plus",
        "input": {
            "messages": [
                {"role": "system", "content": "你是新闻摘要助手。列出当天最重要的3条相关新闻，每条给出具体数据（数字、金额、百分比）和来源。"},
                {"role": "user", "content": "搜索最新新闻: '"$NEWS_QUERY"'. 只返回3条最重要的，每条包含关键数据。"}
            ]
        },
        "parameters": {"enable_search": true}
    }')

NEWS_SUMMARY=$(echo "$NEWS_RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('output',{}).get('text',''))
" 2>/dev/null)

if [ -n "$NEWS_SUMMARY" ]; then
    echo "$NEWS_SUMMARY" > "$WORKSPACE/logs/news_${TYPE}_${DATE_STR}.txt"
    log "✅ 新闻摘要: $(echo "$NEWS_SUMMARY" | wc -l)行"
else
    NEWS_SUMMARY="暂无新闻摘要"
    log "⚠️ 新闻搜索无结果"
fi

log "[1/5] 千问写文案..."

SYSTEM='你是短视频文案写手。只输出纯台词，不要写任何格式注解。
四段格式：
【00:00-00:10】第一段台词(1-2句)
【00:10-00:25】第二段台词(1-2句)
【00:25-00:40】第三段台词(1-2句)
【00:40-00:50】第四段台词+风云带你看实时

要求：基于提供的当日新闻摘要写文案，必须使用新闻中的具体数据。口语化快节奏，每段1-2句。
武类=战争冲突/军事行动，文类=经济影响/地缘博弈。
只写纯台词，不写格式注解。'

if [ -z "$TOPIC" ]; then
    USER_MSG="今日新闻摘要:\n$NEWS_SUMMARY\n\n基于以上新闻，写一篇$TYPE类短视频文案。要求使用新闻中的具体数据（数字、金额）。50秒四段式。中文。"
else
    USER_MSG="今日新闻摘要:\n$NEWS_SUMMARY\n\n基于$$TOPIC相关新闻，写一篇$TYPE类短视频文案。要求使用新闻中的具体数据。50秒四段式。中文。"
fi

QWEN_RESP=$(curl -s -m 60 "$QWEN_URL" \
    -H "Authorization: Bearer $QWEN_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "qwen-plus",
        "input": {
            "messages": [
                {"role": "system", "content": '"$(python3 -c "import json; print(json.dumps(open('/dev/stdin').read()))" <<< "$SYSTEM")"'},
                {"role": "user", "content": '"$(python3 -c "import json; print(json.dumps(open('/dev/stdin').read()))" <<< "$USER_MSG")"'}
            ]
        },
        "parameters": {"enable_search": true}
    }')

SCRIPT=$(echo "$QWEN_RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('output',{}).get('text',''))
")

if [ -z "$SCRIPT" ]; then log "❌ 文案失败"; tel_msg "❌ 视频管线 ${TYPE}：文案生成失败，请检查千问API"; exit 1; fi
echo "$SCRIPT" > "$WORKSPACE/logs/script_${TYPE}_${DATE_STR}.txt"
log "✅ 文案 ($(echo "$SCRIPT" | wc -c)字)"
# 保存文案到日志
cp "$WORKSPACE/logs/script_${TYPE}_${DATE_STR}.txt" "${OUTPUT_DIR}/文案_${TYPE}_${DATE_STR}.txt" 2>/dev/null

# ===== 步骤2: 配音 =====
log "[2/5] 配音..."

# 分割文案为4段台词
python3 << PYEOF
import re
script = """$SCRIPT"""
parts = re.findall(r'【.*?】\s*(.*?)(?=\n【|\Z)', script, re.DOTALL)
if len(parts) < 4:
    lines = [l.strip() for l in script.split('\n') if l.strip() and not l.startswith('【')]
    parts = lines[:4]
while len(parts) < 4: parts.append('风云带你看实时')

with open('/tmp/vp_parts_$TS.txt', 'w') as f:
    for p in parts:
        clean = p.strip().replace('\n', '。')[:80]
        if not clean: clean = '风云带你看实时'
        f.write(clean + '\n')
PYEOF

mapfile -t LINES < "/tmp/vp_parts_$TS.txt"
for i in 0 1 2 3; do
    python3 scripts/tts_gen.py "/tmp/vp_parts_$TS.txt" "${i}" "/tmp/vp_audio_${TYPE}_${TS}_${i}.mp3" || true
    log "  配音$((i+1))"
done

# ===== 步骤3: 素材 =====
log "[3/5] 素材..."

# 从文案提取关键词搜素材
QS=()
kw=$(python3 scripts/extract_kw.py "$TYPE")
if [ -n "$kw" ]; then
    QS=("$kw")
else
    if [ "$TYPE" = "武" ]; then
        QS=("military conflict war 2026")
    else
        QS=("oil price crisis 2026")
    fi
fi

# ytsearch5: 用文案关键词搜5个视频，串行下载
for __vid in $(python3 -c "
import subprocess, json
q = open('/dev/stdin').read().strip()
r = subprocess.run(['yt-dlp','--flat-playlist','--dump-json',f'ytsearch5:{q}'], capture_output=True, text=True, timeout=30)
ids = [json.loads(l).get('id','') for l in r.stdout.strip().split(chr(10)) if l]
print(' '.join(ids))
" <<< "$kw" 2>/dev/null); do
    log "  → $__vid"
    yt-dlp -f 'bestvideo[height<=720]+bestaudio/best[height<=720]' \
        --download-sections "*00:10-00:30" --force-keyframes-at-cuts \
        --ignore-errors --no-warnings \
        -o "$MATERIAL_DIR/vp_${TYPE}_${TS}_$(echo $__vid | tail -c 8).mp4" \
        "https://youtube.com/watch?v=$__vid" 2>>"$LOG" || true
done

# 检查素材
MAT_FILES=($(ls "$MATERIAL_DIR/vp_${TYPE}_${TS}_"*.mp4* 2>/dev/null))
if [ ${#MAT_FILES[@]} -eq 0 ]; then
    MAT_FILES=($(ls "$MATERIAL_DIR/"*.webm 2>/dev/null))
    log "⚠️ 复用缓存素材"
fi
log "✅ 素材: ${#MAT_FILES[@]}个"

# ===== 步骤4: 合成 =====
log "[4/5] 合成..."

python3 << PYEOF
import subprocess, os, glob, sys

workdir = "$WORKSPACE"
mat_dir = "$MATERIAL_DIR"
ts = "$TS"
atype = "$TYPE"
fontfile = '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc'

# 音频
audio_files = [f'/tmp/vp_audio_{atype}_{ts}_{i}.mp3' for i in range(4)]
durations = []
for af in audio_files:
    r = subprocess.run(['ffprobe','-v','error','-show_entries','format=duration',
        '-of','default=noprint_wrappers=1:nokey=1', af], capture_output=True, text=True)
    d = float(r.stdout.strip() or 1)
    durations.append(d)

# 素材
materials = sorted(glob.glob(f'{mat_dir}/vp_{atype}_{ts}_*.mp4*'))
if not materials:
    materials = glob.glob(f'{mat_dir}/*.webm')
if not materials:
    materials = []

# 文案
with open(f'/tmp/vp_parts_{ts}.txt') as f:
    texts = [l.strip() for l in f.readlines()]
while len(texts) < 4: texts.append('风云带你看实时')

log_file = "$LOG"

segments = []
for i in range(4):
    out = f'/tmp/vp_seg_{ts}_{i}.mp4'
    audio = audio_files[i]
    dur = int(durations[i]) + 1
    safe_text = texts[i].replace("'", "\\'").replace('"', '\\"')
    
    mat = materials[i % max(1, len(materials))] if materials else ''
    
    if mat and os.path.exists(mat):
        cmd = ['ffmpeg', '-y',
            '-ss', '0', '-i', mat,
            '-i', audio,
            '-filter_complex',
            f"[0:v]scale=608:1080:force_original_aspect_ratio=decrease,pad=608:1080:(ow-iw)/2:(oh-ih)/2:black,drawtext=text='{safe_text}':fontfile={fontfile}:fontcolor=white:fontsize=32:x=(w-text_w)/2:y=h-150:box=1:boxcolor=black@0.6:boxborderw=10,setpts=PTS-STARTPTS[v];"
            f"[1:a]adelay=50|50[a]",
            '-map', '[v]', '-map', '[a]',
            '-c:v', 'libx264', '-c:a', 'aac', '-pix_fmt', 'yuv420p',
            '-t', str(dur), out]
    else:
        cmd = ['ffmpeg', '-y',
            '-f', 'lavfi', '-i', f'color=c=black:s=608x1080:d={dur}:r=24',
            '-i', audio,
            '-filter_complex',
            f"[0:v]drawtext=text='{safe_text}':fontfile={fontfile}:fontcolor=white:fontsize=40:x=(w-text_w)/2:y=(h-text_h)/2:box=1:boxcolor=black@0.8:boxborderw=20,setpts=PTS-STARTPTS[v];"
            f"[1:a]adelay=50|50[a]",
            '-map', '[v]', '-map', '[a]',
            '-c:v', 'libx264', '-c:a', 'aac', '-pix_fmt', 'yuv420p',
            '-t', str(dur), out]
    
    r = subprocess.run(cmd, capture_output=True, timeout=60)
    if r.returncode == 0:
        segments.append(out)
        print(f'Seg {i}: OK')
    else:
        err = r.stderr.decode()[-100:]
        print(f'Seg {i}: FAIL - {err}')

if len(segments) < 2:
    print('❌ Too few segments')
    exit(1)

# 拼接
concat_f = f'/tmp/vp_concat_{ts}.txt'
with open(concat_f, 'w') as f:
    for s in segments: f.write(f"file '{s}'\n")

final = f'{workdir}/vp_output_{atype}_{ts}.mp4'
r = subprocess.run(['ffmpeg', '-y', '-f', 'concat', '-safe', '0',
    '-i', concat_f, '-c', 'copy', final], capture_output=True, timeout=60)

if r.returncode == 0:
    sz = os.path.getsize(final)
    print(f'✅ OK: {final} ({sz/1024:.0f}KB)')
    sys.exit(0)
else:
    print(f'❌ Concat: {r.stderr.decode()[-100:]}')
    sys.exit(1)
PYEOF

PY_EXIT=$?
if [ $PY_EXIT -ne 0 ]; then
    log "❌ 合成失败"; tel_msg "❌ 视频合成失败"; exit 1
fi

FINAL_VIDEO="$WORKSPACE/vp_output_${TYPE}_${TS}.mp4"

# ===== 步骤5: 输出 =====
log "[5/5] 输出..."

DESKTOP="$OUTPUT_DIR/归墟视频_${TYPE}_${DATE_STR}.mp4"
cp "$FINAL_VIDEO" "$DESKTOP"
SZ=$(ls -lh "$DESKTOP" | awk '{print $5}')
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FINAL_VIDEO" 2>/dev/null | xargs printf "%.0fs")

log "✅ 桌面: $DESKTOP ($SZ / $DUR)"

# 通知
tel_msg "🎬 归墟出片！

类型: $TYPE
时长: $DUR
大小: $SZ
位置: 桌面

✅ 可直接剪辑发布"

log "=== ✅ 管线完成 ==="
echo "$DESKTOP"
