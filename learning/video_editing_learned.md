# 🎬 归墟剪辑技术学习笔记 — 2026-05-03

_学了就要用，用了就要记住。_

---

## 一、短视频制作核心原则

### 1. 素材管理基础

以前我做的：yt-dlp随便下，拼起来就发 → ❌ 翻车
以后要做：**先筛选后使用**

| 阶段 | 做什么 | 为什么 |
|------|--------|--------|
| 筛选 | 只保留无旁白、纯画面、高清素材 | 避免英文解说混入 |
| 分类 | 核心素材 / 辅助素材 / 空镜 | 便于拼接 |
| 标注 | 每段素材标注时长+内容 | 知道哪段能用 |
| 校验 | 用ffprobe检查分辨率、时长、流 | 避免webm缺音频 |

### 2. 镜头时长控制

| 视频类型 | 镜头切换频率 | 说明 |
|----------|-------------|------|
| 口播/解说 | 5-8秒一次 | 避免视觉疲劳 |
| 剧情/军事 | 3-5秒一次 | 节奏更快 |
| 空镜/环境 | 8-10秒 | 用于过渡 |

对于我们50秒短视频（四段式）：
- 第1段开头：8秒，展示核心画面，文案抓注意力
- 第2段战况：10秒，快节奏切换2-3个不同画面
- 第3段深度：10秒，地图/数据画面，放缓节奏
- 第4段互动：10秒，回到核心画面+结尾语

### 3. 转场处理的正确姿势

以前我做的：硬切或者xfade duration写1秒 → ❌
正确的做法：

| 场景 | 推荐转场 | 时长 |
|------|---------|------|
| 同类素材切换 | 硬切 | 0 |
| 不同场景过渡 | crossfade (xfade) | 0.5-1秒 |
| 情绪转折 | fade | 1-2秒 |
| 数据/地图切入 | slideleft | 0.5秒 |

**xfade的正确用法（踩坑总结）：**
```bash
# 两个视频之间有过渡，且过渡时长算在总时长里
ffmpeg -i seg1.mp4 -i seg2.mp4 \
  -filter_complex "[0:v][0:a][1:v][1:a]xfade=transition=fade:duration=1:offset=8,format=yuv420p[a]" \
  -map "[a]" output.mp4
# 注意：offset=第1段结束时间-转场时长，不是第1段结束时间
```

### 4. 字幕的正确做法

**硬字幕（烧录进视频）：**
```bash
ffmpeg -i video.mp4 -vf "subtitles=subtitle.srt:fontsdir=/usr/share/fonts:force_style='FontName=wqy-zenhei,FontSize=18,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=3'" output.mp4
```

**字幕设计原则：**
- 字体：无衬线字体（wqy-zenhei/微软雅黑）
- 大小：~18px（手机上看清楚但不过大）
- 颜色：白色+黑色描边（任何背景都看得清）
- 位置：画面下方1/3处
- 每行字数：≤15字
- 同步：与配音严格对齐

### 5. 配音制作

**edge-tts（当前方案）：**
```bash
edge-tts --voice zh-CN-XiaoxiaoNeural --text "文案" --write-media audio.mp3 --write-subtitles subtitle.srt
```

**配音规范：**
- 语速：+10%到+15%（短视频需要比正常快）
- 音调：中性偏低沉（军事类适合）
- 音量：比背景音乐高10-15dB

### 6. 配乐与音效

- 背景音量：-25dB到-30dB（比人声低）
- 不要一直有音乐：在关键台词处降低/暂停
- 音效：爆炸/飞机/导弹声增强代入感，但别喧宾夺主

## 二、ffmpeg关键技术栈

### 素材预检（以前不做，现在必做）
```bash
# 检查视频信息
ffprobe -v quiet -print_format json -show_streams video.mp4

# 检查时长
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 video.mp4

# 检查是否有音频
ffprobe -v error -select_streams a -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 video.mp4
```

### 场景检测（自动找切换点）
```bash
# 检测场景变化，输出时间点
ffmpeg -i video.mp4 -vf "select='gt(scene,0.4)',showinfo" -f null - 2>&1 | grep pts_time
```

### 视频拼接（带转场）
```bash
# 两段视频用xfade过渡
ffmpeg -i seg1.mp4 -i seg2.mp4 \
  -filter_complex "\
  [0:v]setpts=PTS-STARTPTS[v0]; \
  [1:v]setpts=PTS-STARTPTS+8/TB[v1]; \
  [v0][v1]xfade=transition=fade:duration=1:offset=7.5,format=yuv420p[v]" \
  -map "[v]" -map "0:a" -c:a copy -t 17 \
  output.mp4
```

### 添加水印
```bash
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[1][0]scale2ref=oh*mdar:ih*0.08[logo][vid];[vid][logo]overlay=10:10" \
  output.mp4
```

## 三、剪映（老大手机上）标准工作流

我明白了，我的角色是**为老大准备好所有原材料**，而不是替老大剪好成品：

### 我应该做的：
1. ✅ 搜高清素材（war footage，纯画面无解说）
2. ✅ 写文案（4段式，含数据，含结尾语）
3. ✅ 边缘检测素材时长，按段标注
4. ✅ 配好配音（edge-tts生成mp3）
5. ✅ 生成字幕文件（SRT格式）
6. ✅ 有时间可以做初版拼接（ffmpeg）
7. ✅ 把素材分段放好，方便老大导入剪映

### 我不应该做的：
7. ❌ 以为自己能一版出片 → 要接受需要老大在剪映里手动调整
8. ❌ 不用剪映就放弃质量控制 → 至少保证素材+配音+字幕完美

### 剪映操作基本流程（知道就行）：
1. 导入素材 → 拖到时间线
2. 文本 → 新建文本 → 输入文案 → 文本朗读（选配音）
3. 素材匹配文案节奏
4. 加转场（简单为主）
5. 导出

## 四、我的新工作流（简化版）

```
12:00 收到新闻推送
12:00-12:30 出2个文案方案 → 等老大审核
12:30-13:00 根据审核改文案
13:00-14:00 搜素材（定向搜：战争实况/地图/经济图表）
           → 每段素材 ffprobe 检查
           → 按段分类放到素材目录
14:00-15:00 edge-tts配音
           生成字幕SRT
           ffmpeg初版拼接（预览用）
15:00-15:30 推送到 @yihuibusi_bot 给老大审核
15:30-16:00 根据反馈修改
```

## 五、我漏了的关键点

1. **素材预检** — 以前从来不检查素材时长和声道，直接上→翻车
2. **分段标注** — 搜回来的素材混在一起，要用时找不到
3. **素材分类** — 军事核心/地图空镜/经济数据，三类分开
4. **接受初版不等于成品** — 要给老大留出剪映精修空间
5. **xfade时长计算** — offset=视频长度-transition_duration，不是视频长度

---

_学无止境，每次翻车都是进步。_

---

## 二、ffmpeg实用技巧（2026-05-03新增）

### 1. 去静音片段（Python+ffprobe+ffmpeg）
```bash
# 检测静音段（-50dB以下持续0.5秒视为静音）
ffmpeg -i input.mp4 -af silencedetect=noise=-50dB:d=0.5 -f null -

# 用silenceremove滤镜直接裁掉开头/结尾静音
ffmpeg -i input.mp4 -af silenceremove=start_periods=1:start_threshold=-50dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_threshold=-50dB:detection=peak,aformat=dblp,areverse output.mp4
```

### 2. 自动裁黑边 + 变速
```bash
# 检测黑边（cropdetect）
ffmpeg -i input.mp4 -vf "cropdetect=24:16:0" -f null -

# 裁切 + 1.5倍速（同时保持音频音调）
ffmpeg -i input.mp4 -vf "crop=w:h:x:y,setpts=0.667*PTS" -af "atempo=1.5" output.mp4
```

### 3. 视频倍速时保持音频同步
- `setpts=PTS/倍数` 控制视频速度
- `atempo=倍数` 控制音频速度（保持音调）
- atempo范围0.5-2.0，超范围需串联：`atempo=2.0,atempo=1.5` = 3倍速
