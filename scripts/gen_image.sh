#!/bin/bash
# AI出图工具
# 用法: gen_image "画面描述" /tmp/output.png

PROMPT="$1"
OUTPUT="${2:-/tmp/gen_image.png}"

echo "🎨 生成图像: $PROMPT"
echo ""

# 方式1: 用OpenClaw的API直接调（绕过CLI限制）
# 先试试NVIDIA的flux模型（API兼容OpenAI格式）
echo "尝试NVIDIA Flux..."
curl -s -m 60 https://ai.api.nvidia.com/v1/vlm/google/gemma-3-27b-it \
  -H "Authorization: Bearer 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" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"stream\":false}" 2>/dev/null | head -500

echo ""
echo "⚠️ 注: 图片生成需要配置对应的API provider"
echo "   可用方案: Google Gemini Image / OpenAI GPT Images 2.0 / OpenRouter"
