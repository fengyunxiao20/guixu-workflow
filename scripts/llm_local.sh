#!/bin/bash
# 本地Ollama调用快捷脚本
# 用法: source scripts/llm_local.sh
#       然后调用: llm_qwen "你的提示" 或 llm_gemma "你的提示"

OLLAMA_URL="http://192.168.208.1:11434"

# 调qwen3.6:27b（主力）
llm_qwen() {
    curl -s -m 120 "$OLLAMA_URL/api/generate" \
      -d "{\"model\":\"qwen3.6:27b\",\"prompt\":\"$1\",\"stream\":false}" | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))"
}

# 调gemma4:e4b（轻量快速）
llm_gemma() {
    curl -s -m 30 "$OLLAMA_URL/api/generate" \
      -d "{\"model\":\"gemma4:e4b\",\"prompt\":\"$1\",\"stream\":false}" | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))"
}

# OpenAI兼容模式调用（给OpenClaw用）
llm_local_api() {
    curl -s -m 120 "$OLLAMA_URL/v1/chat/completions" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$1\",\"messages\":[{\"role\":\"user\",\"content\":\"$2\"}],\"stream\":false}" | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])"
}

echo "✅ 本地LLM已就绪"
echo "   llm_qwen \"提示\"  — qwen3.6:27b（主力）"
echo "   llm_gemma \"提示\"  — gemma4:e4b（轻量）"
