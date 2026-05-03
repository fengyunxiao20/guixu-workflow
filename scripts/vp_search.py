#!/usr/bin/env python3
"""归墟素材搜索 - 用关键词搜3个YouTube视频"""
import sys, subprocess, json, os

def extract_video_ids(query, count=3):
    """用 ytsearch 一次搜多个视频，返回 (id, title) 列表"""
    cmd = [
        'yt-dlp', '--flat-playlist', '--dump-json',
        f'ytsearch{count}:{query}'
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    videos = []
    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        try:
            d = json.loads(line)
            videos.append((d.get('id', ''), d.get('title', '')))
        except:
            pass
    return videos

def main():
    query = sys.argv[1] if len(sys.argv) > 1 else 'war crisis 2026'
    mat_dir = sys.argv[2] if len(sys.argv) > 2 else '/mnt/d/归墟文件夹/素材'
    suffix = sys.argv[3] if len(sys.argv) > 3 else '武_99999'
    log_file = sys.argv[4] if len(sys.argv) > 4 else '/dev/null'
    
    # 如果关键词太短，扩写
    if len(query) < 6:
        query = f'{query} military 2026'
    
    # 搜3个视频
    all_videos = []
    # 先用关键词搜
    videos = extract_video_ids(query, 3)
    all_videos.extend(videos)
    
    # 如果不够，用中英文变体
    if len(all_videos) < 3:
        # 加英文战争词变体
        expansions = ['war', 'conflict', 'military', 'attack', 'missile']
        for exp in expansions:
            videos = extract_video_ids(f'{exp} {query}', 2)
            all_videos.extend(videos)
            if len(all_videos) >= 3:
                break
    
    # 去重取前3
    seen = set()
    unique_videos = []
    for vid, title in all_videos:
        if vid and vid not in seen:
            seen.add(vid)
            unique_videos.append((vid, title))
    unique_videos = unique_videos[:3]
    
    if not unique_videos:
        # fallback: 硬编码常用战争视频
        unique_videos = [
            ('dQw4w9WgXcQ', 'Fallback'),  # 不应该走到这里
        ]
    
    # 下载（串行）
    for idx, (vid, title) in enumerate(unique_videos):
        log_line = f"[{__import__('datetime').datetime.now().strftime('%H:%M:%S')}]   → {vid}"
        print(log_line)
        with open(log_file, 'a') as lf:
            lf.write(log_line + '\n')
        
        out_path = f'{mat_dir}/vp_{suffix}_{vid[-7:]}.mp4'
        dl_cmd = [
            'yt-dlp',
            '-f', 'bestvideo[height<=720]+bestaudio/best[height<=720]',
            '--download-sections', '*00:10-00:30',
            '--force-keyframes-at-cuts',
            '-o', out_path,
            f'https://youtube.com/watch?v={vid}'
        ]
        subprocess.run(dl_cmd, capture_output=True, timeout=120)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
