#!/usr/bin/env python3
"""
归墟配音生成器
调用: python3 tts_gen.py <parts_file> <index> <output>
"""
import sys, asyncio

async def gen(text, out_file):
    from edge_tts import Communicate
    for attempt in range(3):
        try:
            await Communicate(text, 'zh-CN-YunxiNeural').save(out_file)
            return True
        except Exception:
            if attempt < 2:
                await asyncio.sleep(3)
    return False

def main():
    _, parts_file, idx, out_file = sys.argv
    with open(parts_file, encoding='utf-8') as f:
        lines = [l.strip() for l in f.readlines() if l.strip()]
    text = lines[int(idx)] if int(idx) < len(lines) else '风云带你看实时'
    ok = asyncio.run(gen(text, out_file))
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
