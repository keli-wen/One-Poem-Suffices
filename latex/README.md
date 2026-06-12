# One Poem Suffices · PDF 导出样式

博客转 PDF 的 XeLaTeX 样式（`onepoem.cls`），Anthropic report 质感，主要用于小红书分发。

## 目录组织

```
latex/
├── onepoem.cls            # 样式类（所有文章共用）
├── demo-agent-skills.tex  # 全要素样式示例（改样式时用它快速预览）
├── agent-skills/          # 每篇文章一个文件夹
│   ├── main.tex           # 封面元信息 + \input 各章
│   ├── build.sh           # 一键编译（处理 TEXINPUTS）
│   ├── sections/          # 00-intro ... 07-appendix 分章节源文件
│   └── agent-skills.pdf   # 产物
└── README.md
```

## 编译

文章（推荐走 build 脚本，cls 在上级目录需要 `TEXINPUTS=..:`）：

```bash
cd latex/agent-skills && ./build.sh
```

样式示例：

```bash
cd latex
xelatex demo-agent-skills.tex   # 跑两遍稳定引用
xelatex demo-agent-skills.tex
```

开本选择：

```latex
\documentclass{onepoem}       % 默认 xhs：140mm × 186.67mm（3:4，小红书图片比例）
\documentclass[a4]{onepoem}   % A4 标准 report
```

导出小红书图片（每页一张 PNG，300dpi）：

```bash
pdftoppm -png -r 300 demo-agent-skills.pdf xhs-page
```

## 设计系统 v3

参照 Anthropic 官方 report PDF：纯白、克制、留白。
排版对位 Styrene（黑体小标题）+ Tiempos（衬线大标题与正文），
中文遵循「衬线配衬线、黑体配黑体」的混排原则。

### 色板

| Token | 色值 | 用途 |
|---|---|---|
| 背景 | `#FFFFFF` | 纯白 |
| `opink` | `#191919` | 正文墨色、标题、章节编号、列表圆点（克制：黑就是黑） |
| `opclay` | `#DE7356` | Anthropic 陶土：封面短杠、引文悬挂引号、分隔线 |
| `opclaydeep` | `#C0593B` | 陶土加深：链接 |
| `opmuted` | `#6B6B6B` | 次级文字、caption、页脚 |
| `opcream` | `#F5F1E8` | 代码与行内代码底色（oat） |

callout 用**背景色**区分类型（Claude palette 低饱和衍生，无边框无侧条）：
note oat `#F0EBE1` · tip bud `#E9EFE2` · question heather `#EDE9F3` ·
info sky `#E7EFF3` · important clay `#FAE9E1` · warning terra `#F6E0D9`，
图标着对应深色，标题文字保持墨色。

### 字体（四族分工）

| 角色 | 英文 | 中文 | 来源 |
|---|---|---|---|
| 大标题（封面 / section） | Source Serif Semibold | 思源宋体 SemiBold | TeX Live / Adobe 下载 |
| 封面副标题 | EB Garamond Italic | 思源宋体（正体回落） | TeX Live |
| 小标题（subsection / 表头） | Helvetica Neue Bold | PingFang SC Semibold | macOS 系统 |
| 正文 / callout 标题 | Source Serif Pro（加粗 = Semibold） | 思源宋体 | 同大标题 |
| 代码 | JetBrains Mono | — | 用户字体目录 |

思源宋体与 Source Serif 是 Adobe 同源设计，中英文衬线笔形灰度一致。
若换机器缺字体：从 [adobe-fonts/source-han-serif](https://github.com/adobe-fonts/source-han-serif/releases)
下载 `09_SourceHanSerifSC.zip`，将 Regular / SemiBold / Bold 拷入 `~/Library/Fonts/`。

### 字号（xhs 开本，正文约 33 汉字/行）

行距全部显式指定（全局 `\linespread{1}`）：正文 9pt/14.8pt；section 衬线 15.5pt；
subsection 10.6pt；callout 内文 8.6pt；代码 7.6pt；caption 7.6pt；封面主标题 21.5pt。

### 章头（Anthropic chapter 式）

居中胶囊描边标签（`SECTION N`，letterspaced 大写，TikZ `rounded rectangle`
保证真正的半圆端）+ 居中衬线大标题，两者装在同一个 `\parbox` 里防止分页拆开。

### 封面

顶部满幅 Header 插画 + 系列刊头（letterspaced）+ 单行衬线大标题 +
EB Garamond Italic 副标题 + 底部陶土短杠与三栏元信息
（AUTHOR / DATE / READ 小标签压在数值上方）。

### 引文

无底无框，缩进 + 衬线斜体 + 左侧悬挂陶土引号。

## 组件速查

```latex
% 封面（导言区设置，正文起始处 \makecover）
\opheaderimg{path/to/header.png}
\optitle{...} \opsubtitle{...} \opdate{2026.06} \opread{50 MIN}

% callout（可选参数为自定义标题）
\begin{notebox}[标题]...\end{notebox}           % 陶土
\begin{tipbox}...\end{tipbox}                   % 绿
\begin{questionbox}[标题]...\end{questionbox}   % 紫
\begin{infobox}[标题]...\end{infobox}           % 青
\begin{importantbox}[标题]...\end{importantbox} % 陶土
\begin{warnbox}...\end{warnbox}                 % 红
\begin{blockquote}...\end{blockquote}           % 引文

% 行内代码 / 代码块（* 版带文件名框眉）
\code{SKILL.md}
\begin{codeblock*}[my-skill/SKILL.md]{}...\end{codeblock*}

% 链接（外链自动加右上角小箭头）
\weblink{https://...}{链接文字}

% 图（caption 自动编号「图 N · 说明」）
\opfig[0.9]{path/to/img.png}{caption 文字}

% 表（booktabs 三线表，表头用 \tabhead，正文自动用黑体族）
\begin{optable}
\begin{tabularx}{\linewidth}{@{}ll>{\raggedright\arraybackslash}X@{}}
\toprule
\tabhead{列一} & \tabhead{列二} & \tabhead{列三} \\
\midrule ... \bottomrule
\end{tabularx}
\end{optable}

% 分隔线（替代 markdown 的 ---）
\opdivider
```

## Markdown → LaTeX 对照

| 博客 markdown | LaTeX |
|---|---|
| `!!! tip` / `!!! note "标题"` | `tipbox` / `notebox[标题]` |
| `> 引文` | `blockquote` |
| `` `code` `` | `\code{}` |
| 代码块 | `codeblock` / `codeblock*` |
| `![](img)` + 斜体 caption | `\opfig{}{}` |
| 表格 | `optable` + `tabularx` |

## 已知坑（改样式前必读）

1. **垂直模式陷阱**（最容易踩）：X/p 型表格单元格起始、`\item` 之后，仍处于垂直模式。
   此时裸 `\color`、`\llap`、fontspec 字族切换都会产生独立行 / 基线下坠。
   解法统一为先 `\leavevmode`（`\tabhead` 和 `blockquote` 内部已处理）。
2. **盒内行距**：行距策略是全局 `\linespread{1}` + 各处显式 `\fontsize{x}{y}`。
   若改回全局 linespread > 1，tcolorbox / listings 内的字号会被二次放大。
3. **行内代码盒高**：tcbox 高度随内容升降部变化（`name` vs `description` 高矮不一），
   `\code` 内置 `\vphantom{bg}` 统一盒高，改样式时别删。
4. **章头分页**：titlesec display 形制下胶囊标签和标题之间可能被分页拆开，
   现在两者装在同一个 `\parbox`（`\op@sectionhead`）里，保持这个结构。
5. JetBrains Mono 只装了 Regular，加粗走 `FakeBold`；中文无斜体，`\itshape` 下保持正体（引文的惯例）。
6. fontawesome5 图标统一用 `\faIcon{kebab-name}` 形式，camelCase 命令跨版本不稳。
