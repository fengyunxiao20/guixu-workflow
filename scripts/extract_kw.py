#!/usr/bin/env python3
"""归墟关键词提取器 v2
根据类型输出英文搜索关键词（YouTube素材搜索用）
武类→军事关键词，文类→经济/能源关键词
"""
import sys

def main():
    # 读取类型标记（从文件名或参数）
    # 从 args 或文件名推断
    kw_type = "武"  # 默认
    for arg in sys.argv[1:]:
        if arg in ("武", "文"):
            kw_type = arg
            break
    
    if kw_type == "武":
        keywords = "military conflict war 2026 combat footage"
    else:
        keywords = "oil price economy 2026 global crisis supply chain"
    
    print(keywords)

if __name__ == '__main__':
    main()
