#!/bin/bash
# 归墟 Cron 审计 — 检查所有 shell 脚本的语法
# 每天凌晨2点跑一次
WORKSPACE="/home/yihui/openclaw/workspace"
LOG="$WORKSPACE/logs/cron_audit.log"

echo "=== Cron审计 $(date) ===" > "$LOG"
ERRORS=0

for script in "$WORKSPACE/scripts/"*.sh; do
    name=$(basename "$script")
    result=$(bash -n "$script" 2>&1)
    if [ $? -ne 0 ]; then
        echo "❌ $name: $result" >> "$LOG"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $name" >> "$LOG"
    fi
done

echo "--- 共检查 $ERRORS 个错误 ---" >> "$LOG"
exit $ERRORS
