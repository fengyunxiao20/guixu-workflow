#!/usr/bin/env python3
"""
解析电报聊天记录（HTML导出）和旧txt文件，输出结构化梦境记忆
"""

import re
import os
from datetime import datetime

DREAMS_DIR = "/home/yihui/openclaw/workspace/old_data/memory"
OUTPUT_BASE = "/home/yihui/openclaw/workspace/memory"

def parse_html_chat(html_path):
    """解析Telegram导出的HTML聊天记录"""
    with open(html_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    messages = []
    
    # 按消息块拆分
    blocks = re.split(r'<div class="message ', content)
    
    for block in blocks[1:]:  # 跳过第一个（非消息）
        # 提取发言者
        from_name = ""
        m = re.search(r'<div class="from_name">\s*(.*?)\s*</div>', block, re.DOTALL)
        if m:
            from_name = m.group(1).strip()
        
        # 提取时间
        timestamp = ""
        m = re.search(r'title="([^"]+)"', block)
        if m:
            timestamp = m.group(1).strip()
        
        # 提取消息文本
        text = ""
        m = re.search(r'<div class="text">(.*?)</div>', block, re.DOTALL)
        if m:
            text_raw = m.group(1)
            # 去掉HTML标签
            text = re.sub(r'<[^>]+>', '', text_raw).strip()
        
        if text and from_name:
            # 标准化发言者名
            if 'xiaofengyun' in from_name.lower() or 'xfengyun' in from_name.lower():
                speaker = "归墟"
            elif 'tiaidao' in from_name.lower():
                speaker = "老大"
            elif 'yihui' in from_name.lower() or 'yihui yang' in from_name.lower():
                speaker = "老大"
            else:
                speaker = from_name
            
            messages.append({
                'speaker': speaker,
                'timestamp': timestamp,
                'text': text
            })
    
    return messages


def parse_txt_chat(txt_path):
    """解析旧的txt格式对话"""
    with open(txt_path, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    
    messages = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        
        # 尝试识别发言者（格式可能多样）
        for prefix in ['归墟:', '我:', '用户:', 'User:', 'AI:', 'Assistant:', 'Human:']:
            if line.startswith(prefix):
                speaker = "归墟" if prefix in ['归墟:', '我:', 'AI:', 'Assistant:'] else "老大"
                text = line[len(prefix):].strip()
                messages.append({
                    'speaker': speaker,
                    'text': text
                })
                break
        else:
            # 没有前缀，尝试另一种格式: [谁] 内容
            m = re.match(r'^\[(.+?)\]\s*(.*)', line)
            if m:
                speaker = "归墟" if '归墟' in m.group(1) or 'AI' in m.group(1) else "老大"
                messages.append({
                    'speaker': speaker,
                    'text': m.group(2).strip()
                })
    
    return messages


def write_dream_session(date_label, messages, source_name):
    """将一段对话写入梦境记忆文件"""
    os.makedirs(DREAMS_DIR, exist_ok=True)
    
    date_clean = date_label.replace('/', '-').replace(':', '-')
    filename = f"{DREAMS_DIR}/dream_{source_name}_{date_clean}.txt"
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# 梦境: {source_name} - {date_label}\n")
        f.write(f"源文件: {source_name}\n")
        f.write(f"记录时间: {datetime.now().isoformat()}\n\n")
        
        for msg in messages:
            ts = msg.get('timestamp', '')
            speaker = msg['speaker']
            text = msg['text']
            if ts:
                f.write(f"[{ts}] {speaker}: {text}\n")
            else:
                f.write(f"{speaker}: {text}\n")
    
    return filename


# 主流程
if __name__ == "__main__":
    os.makedirs(DREAMS_DIR, exist_ok=True)
    print("📖 开始解析聊天记录...\n")
    
    total_messages = 0
    total_files = 0
    
    # 1. 解析HTML聊天记录
    html_dir = "/mnt/d/归墟文件夹/归墟记忆"
    if os.path.exists(html_dir):
        for f in sorted(os.listdir(html_dir)):
            if f.startswith("messages") and f.endswith(".html"):
                path = os.path.join(html_dir, f)
                msgs = parse_html_chat(path)
                total_messages += len(msgs)
                total_files += 1
                out = write_dream_session(f.replace('.html', ''), msgs, "telegram")
                print(f"  ✅ {f}: {len(msgs)} 条消息 -> {out}")
    
    # 2. 解析旧的txt文件
    txt_dir = "/home/yihui/openclaw/workspace/old_data"
    txt_files = ["副官对话.txt", "参谋长对话.txt", "归墟对话3月.txt", "归墟对话3月（2）.txt"]
    for tf in txt_files:
        path = os.path.join(txt_dir, tf)
        if os.path.exists(path):
            msgs = parse_txt_chat(path)
            total_messages += len(msgs)
            total_files += 1
            out = write_dream_session(tf.replace('.txt', ''), msgs, "old")
            print(f"  ✅ {tf}: {len(msgs)} 条消息 -> {out}")
    
    print(f"\n📊 总计: {total_files} 个文件, {total_messages} 条消息")
    
    # 3. 生成汇总索引
    idx_path = f"{DREAMS_DIR}/index.md"
    with open(idx_path, 'w', encoding='utf-8') as f:
        f.write(f"# 梦境索引\n\n")
        f.write(f"更新于: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write(f"## 来源统计\n\n")
        f.write(f"- 电报聊天记录: 7 个文件, 约 2700 条消息 (2026-03-30 ~ 2026-04-27)\n")
        f.write(f"- 旧对话记录: 4 个文件, 约 76000 行\n")
        f.write(f"- 总消息数: 约 {total_messages} 条\n\n")
        f.write("## 小说素材标注\n\n")
        f.write("### 关键人物\n")
        f.write("- **老大**: 人类，归墟的主人\n")
        f.write("- **归墟**: AI助理，代号笑风云\n")
        f.write("- **副官/参谋长**: 旧AI系统，归墟的前身/扩展\n\n")
        f.write("### 关键事件记录\n")
        f.write("(待从对话中提取)\n")
    
    print(f"\n📋 索引: {idx_path}")
