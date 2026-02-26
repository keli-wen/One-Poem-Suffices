# Scripts

## screenshot_blog.py

博客文章导出工具，支持两种模式：

- **截图模式**（默认）：导出为小红书长图（3000x4500 PNG）
- **Markdown 模式**（`--md`）：导出为 Typora 兼容的 Markdown（admonition 转 blockquote，相对链接转绝对 URL）

自动隐藏导航栏/侧边栏/页脚，只保留正文内容。

### 前置条件

```bash
# 安装 Playwright 浏览器（截图模式需要，首次使用）
uv run playwright install chromium
```

### 快速开始

```bash
# 1. 启动本地服务（截图模式需要）
uv run zensical serve

# 2. 导出

# 小红书截图
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent

# Typora Markdown（不需要启动服务，直接读源文件）
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --md
```

`<article-path>` 是文章在 `docs/` 下的路径。输出到 `archived/` 目录（已被 `.gitignore` 忽略）：

- 截图 → `archived/xiaohongshu/<slug>/page_01.png, page_02.png, ...`
- Markdown → `archived/md/<slug>.md`

### 参数

| 参数 | 短写 | 默认值 | 说明 |
|------|------|--------|------|
| `article` | | (必填) | 文章路径，如 `thinking-in-context/when-multi-agent` |
| `--md` | | | 导出为 Typora Markdown（默认为截图模式） |
| `--url` | | | 完整 URL，用于截图模式（覆盖 article） |
| `--port` | `-p` | `8000` | 本地服务端口 |
| `--output-dir` | `-o` | 自动 | 自定义输出路径 |

**截图模式专用参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--width` / `-W` | `3000` | 输出图片宽度（px） |
| `--height` / `-H` | `4500` | 输出图片高度（px） |
| `--dpr` | `4` | 设备像素比（越大文字越大） |
| `--zoom` | `1.2` | CSS 缩放（微调文字大小） |
| `--overlap` | `80` | 相邻页重叠像素（避免断行） |

### 截图调参指南

| 效果 | 参数组合 | 预计页数 |
|------|---------|---------|
| 文字较小（桌面感） | `--dpr 2 --zoom 1.0` | ~5 页 |
| 文字适中 | `--dpr 3 --zoom 1.0` | ~7 页 |
| **文字舒适（推荐）** | **`--dpr 4 --zoom 1.2`（默认）** | **~11 页** |
| 文字很大 | `--dpr 4 --zoom 1.3` | ~14 页 |

### 示例

```bash
# === 截图模式 ===
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --width 4000 --height 6000
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent -o ./my-output

# === Markdown 模式 ===
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --md
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --md -o docs/README.md

# === 通用 ===
uv run scripts/screenshot_blog.py --url https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/
uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --port 8765
```

### Markdown 模式转换规则

| 原始语法 | 转换后 |
|---------|--------|
| `!!! type "title"` + 缩进内容 | `> **title**` blockquote |
| `../../one-poem-suffices/xxx/` | `https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/xxx/` |
| `./assets/img.png` | `https://keli-wen.github.io/.../assets/img.png` |
| 外部链接 `https://...` | 保持不变 |
| `==高亮==` | 保持不变（Typora 原生支持） |
