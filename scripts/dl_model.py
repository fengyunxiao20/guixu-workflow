#!/usr/bin/env python3
"""
多线程模型下载器
用法: python3 dl_model.py <url> [输出路径]
"""
import sys, os, requests, time
from concurrent.futures import ThreadPoolExecutor, as_completed

def download_range(url, start, end, part_num, out_path):
    headers = {'Range': f'bytes={start}-{end}'}
    for retry in range(3):
        try:
            r = requests.get(url, headers=headers, timeout=30)
            if r.status_code in (206, 200):
                with open(out_path, 'r+b') as f:
                    f.seek(start)
                    f.write(r.content)
                return part_num, end - start + 1
        except:
            if retry < 2:
                time.sleep(2)
    return part_num, 0

def main():
    url = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.basename(url)
    
    # 获取文件大小
    print(f"📥 连接 {url}")
    r = requests.head(url, timeout=10, allow_redirects=True)
    total = int(r.headers.get('content-length', 0))
    print(f"📏 文件大小: {total/1024/1024:.1f} MB")
    
    if os.path.exists(out) and os.path.getsize(out) == total:
        print(f"✅ 已存在: {out}")
        return
    
    # 分片
    num_threads = 8
    chunk = total // num_threads
    parts = [(i * chunk, (i + 1) * chunk - 1 if i < num_threads - 1 else total - 1) for i in range(num_threads)]
    
    # 创建空文件
    with open(out, 'wb') as f:
        f.truncate(total)
    
    print(f"🚀 启动 {num_threads} 线程下载...")
    start = time.time()
    done = 0
    
    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = {executor.submit(download_range, url, s, e, i, out): i for i, (s, e) in enumerate(parts)}
        for f in as_completed(futures):
            n, size = f.result()
            done += size
            pct = done * 100 / total
            speed = done / 1024 / 1024 / (time.time() - start)
            print(f"\r⏳ {pct:.0f}% | {done/1024/1024:.0f}/{total/1024/1024:.0f} MB | {speed:.1f} MB/s", end='')
    
    elapsed = time.time() - start
    print(f"\n✅ 完成! 用时 {elapsed:.0f}s, 平均 {total/1024/1024/elapsed:.1f} MB/s")
    print(f"📁 {os.path.abspath(out)}")

if __name__ == '__main__':
    main()
