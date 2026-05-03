# HEARTBEAT 检查清单

## 🛡️ 启动检查（每次心跳必查）
- [ ] 运行 `bash scripts/cron_healthcheck.sh` 查cron是否正常
- [ ] 检查 `logs/cron_audit.log` 末尾：有无 ERROR
- [ ] 检查日志们：`tail -3 logs/cron_news.log` / `tail -3 logs/cron_video_v2.log`
- [ ] 检查 `logs/news_latest.md` 有内容

## 📚 自我提升（每次心跳选做，轮流）

### A. 剪辑/ffmpeg技巧
- [ ] 读 `learning/video_editing_learned.md` 复习
- [ ] 搜一条新ffmpeg/剪映技巧记下来

### B. 🌙 梦境消化（每晚睡前做）
- [ ] 从 `old_data/副官对话.txt` 或 `归墟对话3月*.txt` 啃一段
- [ ] 提炼关键经验，记到当日 memory 文件
- [ ] 进度跟踪：对话名 + 当前行数

### C. 社区/新技术
- [ ] 扫一眼OpenClaw GitHub issue/PR 有无值得关注的
- [ ] 有新release？发版说明里有没有修复/功能我需要的

### D. 工作流优化
- [ ] 今天cron/脚本有没有可以改进的地方？
- [ ] 有没有重复劳动可以自动化？

## 📋 每日流水
- [ ] 04:00新闻推送（cron自动）
- [ ] 08:00新闻推送（cron自动）
- [ ] 12:00新闻推送 → 文案出稿（cron自动）
- [ ] 视频出片（武+文，cron自动）
- [ ] 16:00新闻推送（cron自动）
- [ ] 17-18点网站更新
- [ ] 20:00新闻推送（cron自动）
- [ ] 每晚梦境消化

## 已知问题
- 16:00新闻推送偶尔失败（代理切换），发现则手动追发
- 视频管线TTS依赖venv环境
- AP新闻源经常失败（老问题，非代理问题）
