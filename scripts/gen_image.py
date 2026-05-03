#!/usr/bin/env python3
"""AI图像生成工具 - 用 Google Gemini API"""
import requests, json, sys, base64

PROMPT = sys.argv[1] if len(sys.argv) > 1 else "一只红色龙虾站在沙滩上"
OUTPUT = sys.argv[2] if len(sys.argv) > 2 else "/tmp/gen_image.png"

# Gemini Image Generation API
API_KEY = "AIzaSyA8fH6Uzn2rO4_IOkAFq8sFTf_K0mB_0k0"
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent?key={API_KEY}"

payload = {
    "contents": [{
        "parts": [{"text": f"Generate a photorealistic image: {PROMPT}"}]
    }],
    "generationConfig": {
        "responseModalities": ["IMAGE", "TEXT"]
    }
}

resp = requests.post(url, json=payload, timeout=120)
data = resp.json()

# 找图片数据
for part in data.get('candidates',[{}])[0].get('content',{}).get('parts',[]):
    if 'inlineData' in part:
        img_data = base64.b64decode(part['inlineData']['data'])
        with open(OUTPUT, 'wb') as f:
            f.write(img_data)
        print(f"✅ 图片已保存到 {OUTPUT}")
        sys.exit(0)

print(f"❌ 图片生成失败: {json.dumps(data, indent=2, ensure_ascii=False)[:500]}")
