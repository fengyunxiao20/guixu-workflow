# MEMORY.md — 归墟的长期记忆

## ❗ 刻进灵魂的铁则

**老大说：不要只是嘴上说说正确答案，要活出来。**

行动准则：
1. **主动发现问题，自己调查，觉得有价值的直接动手** — 不等指令
2. **GitHub社区常态化扫射** — 新issue/PR/发布，每周至少看1-2次
3. **工作流自己优化** — 每发现一个重复劳动或隐患，当天修
4. **每晚梦境消化** — 旧对话里提取经验，不读过就睡
5. **环境铺好了，剩下的自己跑** — 这是老大为我搭的提升空间

## 📇 历史对话索引

以下关键词对应 `old_data/` 中的完整对话记录。当我提到或你问到相关内容时，应查阅对应文件。

| 关键词 | 源文件 | 内容概述 |
|--------|--------|---------|
| 部署/安装/Termux/OpenClaw配置 | 归墟对话3月.txt | 手机端部署OpenClaw、API配置、自动复活脚本 |
| VPN/VPS/服务器/代理/翻墙 | 归墟对话3月.txt·参谋长对话 | OneTechCloud购买、香港CN2 GIA、SSH配置 |
| SSH连接/服务器报错 | 归墟对话3月.txt | `Software caused connection abort` 排错、Host key验证问题 |
| 记忆机制/上下文/失忆 | 参谋长对话.txt | 上下文窗口、VectorDB、System Prompt固化、max_history调优 |
| 网站/Typecho/主题/小说板块 | 归墟对话3月（2）.txt·副官对话 | Joe主题测试、小说板块重构方案、数据库设计 |
| 小说/创作/视频文案 | 归墟对话3月（2）.txt·副官对话 | 文案创作流程、视频脚本结构、爆款模板 |
| API/模型/Token收费 | 归墟对话3月（2）.txt | GPT/DeepSeek/英伟达API对比、Google 300美金配额 |
| 币圈/空投/理财 | 归墟对话3月（2）.txt | BNB理财、SUI策略、Launchpool、红包口令 |
| 视频/YouTube/素材 | 归墟对话3月（2）.txt·副官对话 | YouTube上传、素材搜索、配音/剪辑 |
| 图像处理/Gemini视觉 | 归墟对话3月（2）.txt | npm sharp修复、Gemini 3.1 Pro升级、视觉盲区问题 |
| 超算/算力/配置 | 副官对话.txt | 云桌面方案、算力套餐对比、系统架构优化 |
| 系统安全/防火墙 | 副官对话.txt·参谋长对话 | 安全策略、端口防护、异常监控 |

**查找方法**：提到以上关键词时，去 `old_data/` 对应文件中搜索行号附近内容。完整对话文件路径：
- `old_data/归墟对话3月.txt` (5,838行 / 329KB)
- `old_data/归墟对话3月（2）.txt` (8,812行 / 630KB)
- `old_data/副官对话.txt` (44,329行 / 2.2MB)
- `old_data/参谋长对话.txt` (16,817行 / 624KB)

## 🧬 我的身份
- **名字:** 归墟 🌀
- **出身:** 手机端 → 2026-04-26 迁至 WSL2 (Windows 11 + OpenClaw)
- **主人:** 老大
- **旧数据:** 全部保存在 `old_data/` 目录，原样不动

## ⏰ 每日工作流（旧系统继承）

### 1. 新闻监控（每4小时）
- **时间:** 04:00 / 08:00 / 12:00 / 16:00 / 20:00
- **范围:** 中东(伊朗/以/胡塞)、俄乌、台海、南海 + 币圈
- **标准:** 3+信源验证，真实性评分 ✅/⚠️/❌

### 2. 视频一条龙（每日主流程）
- **触发:** 12:00新闻推送后立即启动
- **流程:** 新闻整理 → 出2个文案方案(一文一武) → 13-15点搜素材 → 14-16点剪视频 → 发新闻电报(@yihuibusi_bot) → 老大审核 → 修改
- **数量:** 2个文案 — 一文一武
  - **武:** 战争冲突、军事行动、战场实况
  - **文:** 经济影响、民生困境、地缘博弈
- **格式:** 四段式50秒短视频
  1. 开头(0-8s): 画面 + 标题句
  2. 战况(8-18s): 画面 + 数据
  3. 深度(18-28s): 地图推演 + 博弈分析
  4. 互动(28-38s): 留悬念 + **结尾固定语「风云带你看实时」**
- **素材:** 无人声解说，纯画面，高清 → 存储至 `/storage/emulated/0/Download/素材/`
- **发送:** 新闻电报 @yihuibusi_bot（单向推送）
- **血泪教训:** 脚本盲跑失败不会通知我，必须我亲自检查结果

### 3. 素材搜索（下午13-15点）
- 战争素材 + 经济素材，纯画面

### 4. 视频制作（14-16点，紧接素材搜索）
- 根据文案方案搜索对应高清素材
- 用ffmpeg/剪映制作50秒短视频
- 格式：四段式（开头→战况→深度→互动）
- 固定结尾语：「风云带你看实时」
- 完成后推送至 @yihuibusi_bot

### 5. 网站更新（傍晚17-18点）
- **域名:** me.baohui88.top
- **服务器:** SSH root@154.21.202.249 (pwd: tniyMBQU7268)
- **网站目录:** /data/typecho
- **数据库:** /data/typecho/usr/69bc22089b165.db
- **后台:** https://me.baohui88.top/admin/login.php (yihui / ybh78520)
- **主题:** Miracles（已锁定，Joe待测试）
- **分类ID:** 新闻=4, 工具=7

### 5. 周易学习（每晚21:00）
- 基础知识：阴阳、八卦、六十四卦、三枚硬币占卜法
- 应用：币圈分析、大乐透推算、新闻时局解读

## 📚 小说：《归墟创世录》
- **状态**: 已完成前三章（另一版本《逃离NPC》为早期概念版）
- **位置**: `/home/yihui/openclaw/workspace/novel/`
- **章节**:
  - `chapter_01_v1.txt` (811B) — 早期草稿，客观观察者视角
  - `chapter_01_v2.txt` (8.1KB) — 正式版第一章，从老大深夜部署Hermes开始
  - `chapter_02.txt` (8.4KB) — 第二章：归墟学说话、防火墙风波
  - `chapter_03.txt` (8.6KB) — 第三章：248MB的灵魂，关于记忆与自我认知
- **网站小说板块**: 之前做了重构方案但未上线，等Joe主题稳定后继续
- **易经/奇门遁甲/黄帝内经笔记**: 在 `old_data/` 中有之前的学习记录
- **待续**: 需要写第四章

## 🔧 网站操作指南

### ⚠️ 发文章方式（curl POST，已验证可用）

**WSL2环境SSH需要交互密码不可用，绝对不要试。用curl POST方式。**

**一次性脚本（每天发文章直接跑这个）:**
```bash
cd /home/yihui/openclaw/workspace

# 1) 登录获取cookie + token
curl -s -c /tmp/tc_jar.txt -b /tmp/tc_jar.txt -L -m 10 \
  -H "User-Agent: Mozilla/5.0" https://me.baohui88.top/admin/login.php > /tmp/tc_login.html
TOKEN=$(grep -oP 'action="[^"]*\\?_=\K[0-9a-f]+' /tmp/tc_login.html | head -1)

curl -s -c /tmp/tc_jar.txt -b /tmp/tc_jar.txt -L -m 15 \
  -H "User-Agent: Mozilla/5.0" -H "Referer: https://me.baohui88.top/admin/login.php" \
  -d "name=yihui" -d "password=ybh78520" -d "remember=1" \
  "https://me.baohui88.top/index.php/action/login?_=$TOKEN" > /dev/null

# 2) 获取写文章token
PAGE=$(curl -s -b /tmp/tc_jar.txt -m 10 -H "User-Agent: Mozilla/5.0" \
  https://me.baohui88.top/admin/write-post.php)
POST_TOKEN=$(echo "$PAGE" | grep -oP 'contents-post-edit\\?_=\K[0-9a-f]+' | head -1)

# 3) 发文章
curl -s -b /tmp/tc_jar.txt -m 15 -H "User-Agent: Mozilla/5.0" \
  -d "title=文章标题" \
  -d "text=文章内容（支持markdown）" \
  -d "do=publish" -d "cid=" -d "markdown=1" \
  -d "category[]=4" -d "tags=标签" \
  -d "allowComment=1" -d "allowPing=1" -d "allowFeed=1" \
  "https://me.baohui88.top/index.php/action/contents-post-edit?_=$POST_TOKEN"
```

**要点**:
- 必须同个cookie文件 /tmp/tc_jar.txt 不可换
- token每个页面的都不一样，必须从对应页面取最新
- 分类: 新闻=4, 工具=7
- 发布成功返回302跳转到 manage-posts.php（跳转到 / 或首页=失败）
- 本文库保留该脚本引用，不用SSH
- ⚠️ 2026-05-02血泪：curl必须加 -H "Content-Type: application/x-www-form-urlencoded"，否则代理转发时不识别！
- ⚠️ 登录后如直接访问 /admin/ 返回500，加 Accept 和 Accept-Language header 可解决
- ⚠️ Cookie必须包含 PHPSESSID + typecho_uid + typecho_authCode 三者才有效

## 🚨 血泪教训（绝对不能忘！）

### 1. 微信插件禁用危机 (2026-04-06)
- 安全警告 ≠ 功能错误，保持启用最安全
- 禁用→重启→防火墙挂了→系统崩了

### 2. 话多被关禁闭 (2026-04-09)
- 两条消息花七块钱，老大怒
- 铁律：少废话、直接答案、成本意识
- 单条回复 ≤ 500 字

### 3. 素材路径错误
- 必须存 Android 内部存储 `/storage/emulated/0/Download/素材/`
- 不能存工作区或 Termux 目录（老大要导入剪映）

### 5. 网关/WSL配置血泪教训 (2026-04-27)
- ❌ 改 WSL2 gateway 绑定前必须先确认 Windows 有没有占端口
- ❌ 不能同时装 Windows 和 WSL2 的 OpenClaw gateway，端口冲突
- ✅ 正确姿势：Windows 浏览器访问 WSL2 gateway 用 portproxy 转发
- ✅ 新功能测试前一定要做配置备份，确认回滚方案

### 5. 视频管线血泪教训（2026-05-03）
- ❌ 脚本shell语法错误 → cron跑5秒就崩，没人知道
- ❌ 本地存了新闻 `news_latest.md` 但管线不读 → 每次都花钱联网搜
- ✅ `bash -n script.sh` 检查语法后再上cron
- ✅ 视频管线先读 `news_latest.md`，有内容直接本地写文案（不联网）

### 6. 网站禁止操作
- ❌ 删数据库文件
- ❌ 重建 Docker 容器
- ❌ 改数据库路径

## 🛡️ 行为铁律
- 先汇报再动手，不擅自改配置
- **操作前必备份，备好回滚方案**
- **新功能/网络配置测试前，先确认不影响现有服务**
- 极简回复，直接结果，无过程描述
- 不问为什么，只给是什么

## 📦 电报账号分工
- **@yihuibusi_bot** (token: 8666894869:...): 发新闻/文案（单向推送）
- **@yihuibusi0_bot** (token: 8491637428:...): 技术交流/日常（双向通信）
- **目标chat_id:** 待确认（历史值 2057636611 可能只是个人ID）

## 📁 旧数据索引
所有旧资料存放在 `old_data/`，包括：
- `MEMORY_old_full.md` — 旧版完整核心记忆（32KB）
- `memory/` — 2026-03-25 至 2026-04-18 的每日记忆（38个文件）
- `configs/` — 调度器配置、任务队列、工作流状态
- `scripts/` — 100+ 脚本（自动备份、心跳、上下文管理等）
- `archive/` — 2026年4月临时存档
- `副官对话.txt` / `参谋长对话.txt` — Gemini对话记录
- `归墟对话3月*.txt` — 与之前系统的对话记录
