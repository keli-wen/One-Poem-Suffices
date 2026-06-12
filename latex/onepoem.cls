%% onepoem.cls — One Poem Suffices 博客 PDF 导出样式 v3
%% 参照 Anthropic 官方 report PDF：纯白、克制、留白、衬线大标题
%% 字体系统（衬线配衬线、黑体配黑体）：
%%   大标题  Source Serif Semibold + 思源宋体 SemiBold（Tiempos 式衬线 display）
%%   小标题  Helvetica Neue Bold + PingFang SC Semibold
%%   正文    Source Serif Pro + 思源宋体
%%   代码    JetBrains Mono
%% 编译要求：XeLaTeX（TeX Live 2024+，macOS）
%%
%% 用法：
%%   \documentclass{onepoem}          % 默认 xhs：3:4 小开本，适配小红书截图
%%   \documentclass[a4]{onepoem}      % A4 标准 report 开本
%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{onepoem}[2026/06/12 v3.0 One Poem Suffices blog PDF style]

\newif\ifop@afour
\DeclareOption{a4}{\op@afourtrue}
\DeclareOption{xhs}{\op@afourfalse}
\ExecuteOptions{xhs}
\ProcessOptions\relax

\LoadClass[10pt]{article}

%% ---------------------------------------------------------------- 基础包
\RequirePackage{geometry}
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\RequirePackage{tikz}
\usetikzlibrary{shapes.misc}
\RequirePackage[most]{tcolorbox}
\RequirePackage{fontspec}
\RequirePackage{xeCJK}
\RequirePackage{fontawesome5}
\RequirePackage{booktabs}
\RequirePackage{colortbl}
\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{caption}
\RequirePackage{enumitem}
\RequirePackage{titlesec}
\RequirePackage{fancyhdr}
\RequirePackage{listings}
\RequirePackage{etoolbox}

%% ---------------------------------------------------------------- 版面
\ifop@afour
  \geometry{a4paper, top=26mm, bottom=28mm, left=24mm, right=24mm, footskip=14mm}
\else
  % 3:4 小开本（小红书图片比例），正文约 33 个汉字/行，四周留足呼吸感
  \geometry{paperwidth=140mm, paperheight=186.67mm,
            top=15mm, bottom=17mm, left=13.5mm, right=13.5mm, footskip=9mm}
\fi

% 行距全部显式指定，\linespread 固定为 1，避免盒内字号被二次放大
\linespread{1}
\renewcommand\normalsize{\@setfontsize\normalsize{9pt}{14.8pt}}
\renewcommand\small{\@setfontsize\small{8.3pt}{12.6pt}}
\renewcommand\footnotesize{\@setfontsize\footnotesize{7.7pt}{11pt}}
\setlength{\parskip}{0.5\baselineskip}
\setlength{\parindent}{0pt}

%% ---------------------------------------------------------------- 色板
% 主色：Anthropic clay
\definecolor{opink}{HTML}{191919}     % 正文墨色
\definecolor{opmuted}{HTML}{6B6B6B}   % 次级文字
\definecolor{opclay}{HTML}{DE7356}    % Anthropic 陶土
\definecolor{opclaydeep}{HTML}{C0593B}% 陶土加深（小字号 / 链接）
\definecolor{opline}{HTML}{E5E0DB}    % 细线
\definecolor{opcream}{HTML}{F5F1E8}   % 代码 / 行内代码底色（oat）
% callout 背景色板（Claude palette 低饱和衍生，用背景色区分类型）
\definecolor{opbgnote}{HTML}{F0EBE1}      % oat
\definecolor{opbgtip}{HTML}{E9EFE2}       % bud green
\definecolor{opbgquestion}{HTML}{EDE9F3}  % heather
\definecolor{opbginfo}{HTML}{E7EFF3}      % sky
\definecolor{opbgimportant}{HTML}{FAE9E1} % clay tint
\definecolor{opbgwarn}{HTML}{F6E0D9}      % terra tint
% callout 图标深色
\definecolor{opicnote}{HTML}{8A7355}
\definecolor{opictip}{HTML}{5E7A4E}
\definecolor{opicquestion}{HTML}{6E5A8C}
\definecolor{opicinfo}{HTML}{4E7287}
\definecolor{opicimportant}{HTML}{C0593B}
\definecolor{opicwarn}{HTML}{A8432F}

\color{opink}
\arrayrulecolor{opink}

%% ---------------------------------------------------------------- 字体
% 正文衬线：Source Serif Pro（加粗 = Semibold，保持纤细优雅）
\setmainfont{SourceSerifPro-Regular.otf}[
  BoldFont       = SourceSerifPro-Semibold.otf,
  ItalicFont     = SourceSerifPro-RegularIt.otf,
  BoldItalicFont = SourceSerifPro-SemiboldIt.otf,
]
% 无衬线：Helvetica Neue（小标题 / 标签 / 页脚）
\setsansfont{Helvetica Neue}[
  UprightFont    = * Medium,
  BoldFont       = * Bold,
  ItalicFont     = * Medium Italic,
  BoldItalicFont = * Bold Italic,
  Scale          = 0.92,
]
% 代码：JetBrains Mono（与站点一致）
\setmonofont{JetBrains Mono}[
  Scale        = 0.78,
  BoldFont     = {JetBrains Mono},
  BoldFeatures = {FakeBold=1.02},
]
% 中文正文：思源宋体（与 Source Serif 同源，衬线配衬线）；中文斜体保持正体
\setCJKmainfont{Source Han Serif SC}[
  BoldFont   = Source Han Serif SC SemiBold,
  ItalicFont = Source Han Serif SC,
]
\setCJKsansfont{PingFang SC}[BoldFont=PingFang SC Semibold]
\setCJKmonofont{PingFang SC}
% 小标题字族（黑体配黑体）
\newfontfamily\opheadfont{Helvetica Neue}[UprightFont=* Medium, BoldFont=* Bold, Scale=0.92]
\newCJKfontfamily\opheadcjk{PingFang SC}[BoldFont=PingFang SC Semibold]
\newcommand{\opdisplay}{\opheadcjk\opheadfont\bfseries}
% 大标题（衬线 display，Tiempos 质感）：直接用正文衬线族的 Semibold
\newcommand{\opserif}{\rmfamily\bfseries}
% 小标签（letterspaced 全大写；\kern 收掉末字符的尾随字距）
\newfontfamily\oplabelfont{Helvetica Neue}[UprightFont=* Medium, LetterSpace=18, Scale=0.92]
\newcommand{\oplabel}[1]{{\oplabelfont\MakeUppercase{#1}\kern-0.18em}}
% 副标题专用：改用正体衬线（避免中英混排长句时斜体带来的不协调感）
\newcommand{\opsubfont}{\rmfamily}

%% ---------------------------------------------------------------- 元信息
\newcommand{\opseries}{One Poem Suffices}
\newcommand{\opauthor}{@whisper}
\def\op@title{}      \newcommand{\optitle}[1]{\def\op@title{#1}}
\def\op@subtitle{}   \newcommand{\opsubtitle}[1]{\def\op@subtitle{#1}}
\def\op@date{}       \newcommand{\opdate}[1]{\def\op@date{#1}}
\def\op@read{}       \newcommand{\opread}[1]{\def\op@read{#1}}
\def\op@epigraph{}   \newcommand{\opepigraph}[1]{\def\op@epigraph{#1}}
\def\op@headerimg{}  \newcommand{\opheaderimg}[1]{\def\op@headerimg{#1}}

%% ---------------------------------------------------------------- 封面：Header 插画 + 标题
\newcommand{\makecover}{%
  \thispagestyle{empty}%
  \begin{tikzpicture}[remember picture, overlay]
    % 顶部满幅 Header 插画
    \node[anchor=north, inner sep=0pt] (opimg) at (current page.north)
      {\includegraphics[width=\paperwidth]{\op@headerimg}};
    % 系列刊头
    \node[anchor=north west] at ([xshift=14mm, yshift=-10mm]opimg.south west)
      {\fontsize{7}{7}\selectfont\color{opclaydeep}\oplabel{\opseries\ · 一篇就够了}};
    % 主标题（衬线 display）
    \node[anchor=north west, text width=\dimexpr\paperwidth-28mm\relax, align=left]
      at ([xshift=14mm, yshift=-17mm]opimg.south west)
      {\opserif\fontsize{21.5}{29.5}\selectfont\color{opink}\op@title};
    % 副标题（正体衬线，增加行距增强呼吸感）
    \node[anchor=north west, text width=\dimexpr\paperwidth-28mm\relax, align=left]
      at ([xshift=14mm, yshift=-32mm]opimg.south west)
      {\linespread{1.3}\opsubfont\fontsize{10.2}{16}\selectfont\color{opmuted}\op@subtitle};
    % 底部：更优雅的极细线条 + 衬线体数值（增加间距，弱化标签）
    \fill[opclay] ([xshift=14mm, yshift=27.5mm]current page.south west)
      rectangle ++(12mm, 0.5pt); % 变细、变长，更克制
    \node[anchor=south west, xshift=14mm, yshift=15.5mm] at (current page.south west)
      {\renewcommand{\arraystretch}{1}%
       \begin{tabular}{@{}l@{\hspace{4em}}l@{\hspace{4em}}l@{}}
         {\fontsize{5.2}{5.2}\selectfont\color{opmuted}\oplabel{Author}} &
         {\fontsize{5.2}{5.2}\selectfont\color{opmuted}\oplabel{Date}} &
         {\fontsize{5.2}{5.2}\selectfont\color{opmuted}\oplabel{Read}} \\[3.5pt]
         {\rmfamily\fontsize{9.5}{9.5}\selectfont\color{opink}\opauthor} &
         {\rmfamily\fontsize{9.5}{9.5}\selectfont\color{opink}\op@date} &
         {\rmfamily\fontsize{9.5}{9.5}\selectfont\color{opink}\op@read} \\
       \end{tabular}};
  \end{tikzpicture}%
  \null\newpage
}

%% ---------------------------------------------------------------- 页脚
\fancypagestyle{opmain}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
  \fancyfoot[L]{\fontsize{6}{6}\selectfont\color{opmuted}\oplabel{\opseries}}%
  \fancyfoot[R]{\fontsize{7.3}{7.3}\selectfont\sffamily\color{opmuted}\thepage}%
}
\pagestyle{opmain}

%% ---------------------------------------------------------------- 标题层级
% section 最佳实践：去除滞重的胶囊框，采用极简的字距微调小标签
\newcommand{\op@sectionpill}[1]{%
  {\fontsize{7}{7}\selectfont\color{opmuted!80!opink}\oplabel{#1}}}
% 标题容器
\newcommand{\op@sectionhead}[1]{%
  \parbox{\linewidth}{\centering
    \op@sectionpill{Section \thesection}\\[0.6em]
    {\opserif\fontsize{16}{22}\selectfont\color{opink}#1}}}
\titleformat{\section}[block]
  {\filcenter}
  {}{0pt}
  {\op@sectionhead}
% subsection / subsubsection：黑体小标题，编号同为墨色（克制）
\titleformat{\subsection}
  {\opdisplay\fontsize{10.6}{15}\selectfont\color{opink}}
  {\thesubsection}{0.55em}{}
\titleformat{\subsubsection}
  {\opdisplay\fontsize{9.4}{13.5}\selectfont\color{opink}}
  {\thesubsubsection}{0.55em}{}
\titlespacing*{\section}{0pt}{1.9em}{1.0em}
\titlespacing*{\subsection}{0pt}{1.5em}{0.4em}
\titlespacing*{\subsubsection}{0pt}{1.2em}{0.3em}
% 不编号章头：自定义胶囊文字 + 衬线大标题（用于 Appendix 等 end matter）
\newcommand{\opsectionx}[2]{%
  \par\vspace{1.9em}%
  {\centering\parbox{\linewidth}{\centering
    \op@sectionpill{#1}\\[0.8em]
    {\opserif\fontsize{15.5}{21.5}\selectfont\color{opink}#2}}\par}%
  \vspace{1.0em}\@afterheading}
% 仅胶囊的轻量章头（用于 References 这类 end matter 分隔）
\newcommand{\opsectionpillonly}[1]{%
  \par\vspace{1.9em}{\centering\op@sectionpill{#1}\par}%
  \vspace{1.0em}\@afterheading}

%% ---------------------------------------------------------------- 链接
\RequirePackage[colorlinks=true, linkcolor=opclaydeep, urlcolor=opclaydeep,
                citecolor=opclaydeep, filecolor=opclaydeep]{hyperref}
% 外链：正文 + 右上角小箭头
\newcommand{\weblink}[2]{\href{#1}{#2{\fontsize{5.5}{5.5}\selectfont\,\faIcon{external-link-alt}}}}

%% ---------------------------------------------------------------- 行内代码 / 代码块
% 行内代码：无边框浅底胶囊；\vphantom 统一盒高，不随字母升降部变化
\newtcbox{\op@codebox}{on line, tcbox raise base, nobeforeafter,
  colback=opcream, colframe=opcream, boxrule=0pt, arc=2.2pt,
  left=2.4pt, right=2.4pt, top=0.9pt, bottom=0.9pt, boxsep=0pt}
\newcommand{\code}[1]{\op@codebox{\texttt{\vphantom{bg}\color{opink}#1}}}

\lstdefinestyle{opcode}{
  basicstyle   = \linespread{1}\fontsize{7.6}{10.8}\selectfont\ttfamily\color{opink},
  keywordstyle = \color{opclaydeep}\bfseries,
  stringstyle  = \color{opink!62!opclaydeep},
  commentstyle = \color{opmuted},
  numberstyle  = \fontsize{6}{6}\selectfont\color{opmuted!70},
  identifierstyle = \color{opink},
  breaklines   = true,
  breakatwhitespace = false,
  columns      = fullflexible,
  keepspaces   = true,
  showstringspaces = false,
  tabsize      = 2,
}
% 代码块：无边框浅底圆角；* 版带文件名框眉
\newtcblisting{codeblock}[2][]{%
  listing only, breakable, enhanced,
  colback=opcream, colframe=opcream, boxrule=0pt, arc=5pt,
  left=8pt, right=8pt, top=7pt, bottom=7pt,
  before skip=1.0em, after skip=1.0em,
  listing options={style=opcode, language={#2}},
  #1
}
\newtcblisting{codeblock*}[2][]{%
  listing only, breakable, enhanced,
  colback=opcream, colframe=opcream, boxrule=0pt, arc=5pt,
  left=8pt, right=8pt, top=2pt, bottom=7pt,
  before skip=1.0em, after skip=1.0em,
  listing options={style=opcode, language={#2}},
  title={\ttfamily\fontsize{6.8}{6.8}\selectfont #1},
  coltitle=opmuted, colbacktitle=opcream,
  titlerule=0.4pt, titlerule style={opline},
  attach boxed title to top left={yshift=-2.1mm, xshift=2mm},
  boxed title style={colback=opcream, colframe=opcream, arc=0pt,
    left=2pt, right=2pt, top=1pt, bottom=1pt},
}

%% ---------------------------------------------------------------- Admonition
% 用背景色区分类型（Claude palette），无边框无侧条；图标着深色，标题墨色
\newcommand{\op@newadmonition}[5]{% {环境名}{底色}{图标色}{图标}{默认标题}
  \NewDocumentEnvironment{#1}{O{#5}}{%
    \begin{tcolorbox}[
      enhanced, breakable,
      colback=#2, colframe=#2, boxrule=0pt, arc=6pt,
      left=10pt, right=10pt, top=8pt, bottom=8.5pt,
      before skip=1.1em, after skip=1.1em,
      title={\textcolor{#3}{#4}\hspace{0.55em}%
        {\rmfamily\bfseries\linespread{1}\fontsize{8.7}{12}\selectfont\textcolor{opink}{##1}}},
      coltitle=opink, colbacktitle=#2,
      attach title to upper={\par\smallskip},
      fontupper=\linespread{1}\fontsize{8.6}{14}\selectfont,
    ]%
  }{\end{tcolorbox}}%
}
\op@newadmonition{notebox}{opbgnote}{opicnote}{\faIcon{pen-nib}}{Note}
\op@newadmonition{tipbox}{opbgtip}{opictip}{\faIcon{lightbulb}}{Tip}
\op@newadmonition{questionbox}{opbgquestion}{opicquestion}{\faIcon{question-circle}}{Question}
\op@newadmonition{infobox}{opbginfo}{opicinfo}{\faIcon{info-circle}}{Info}
\op@newadmonition{importantbox}{opbgimportant}{opicimportant}{\faIcon{exclamation-circle}}{Important}
\op@newadmonition{warnbox}{opbgwarn}{opicwarn}{\faIcon{exclamation-triangle}}{Warning}

% 引文：衬线斜体 + 悬挂的陶土引号，无底无框（编辑部质感）
\NewDocumentEnvironment{blockquote}{}{%
  \par\addvspace{1.0em}%
  \begin{list}{}{\setlength{\leftmargin}{1.7em}\setlength{\rightmargin}{1.2em}%
    \setlength{\topsep}{0pt}\setlength{\parsep}{0.35em}}%
  \item\relax\leavevmode\llap{{\color{opclay}\opheadfont\bfseries\fontsize{14}{14}\selectfont``}\hspace{0.32em}}%
  \linespread{1}\fontsize{8.8}{14.2}\selectfont\color{opink!78!opmuted}\itshape
}{\end{list}\par\addvspace{1.0em}}

%% ---------------------------------------------------------------- 图片与 caption
\captionsetup{
  font          = {color=opmuted},
  textfont      = {it},
  labelfont     = {color=opink, up},
  labelsep      = none,
  justification = centering,
  skip          = 6.5pt,
}
\DeclareCaptionFormat{opcap}{\linespread{1}\fontsize{7.6}{10.8}\selectfont{\opdisplay #1}{\;·\;}#3}
\captionsetup{format=opcap}
\renewcommand{\figurename}{图}
\renewcommand{\tablename}{表}
% 快捷命令：\opfig[宽度比例]{路径}{caption}
\newcommand{\opfig}[3][0.92]{%
  \begin{figure}[!ht]
    \centering
    \includegraphics[width=#1\linewidth]{#2}
    \caption{#3}
  \end{figure}}

%% ---------------------------------------------------------------- 表格
\renewcommand{\arraystretch}{1.42}
\setlength{\heavyrulewidth}{0.7pt}
\setlength{\lightrulewidth}{0.4pt}
\setlength{\abovetopsep}{0.45em}
\setlength{\belowbottomsep}{0.45em}
% 表头单元格（X/p 型单元格需先 \leavevmode，避免基线下坠）
\newcommand{\tabhead}[1]{\leavevmode{\opdisplay\fontsize{8.2}{11.5}\selectfont\color{opink}#1}}
% 表格正文字号环境（黑体族，与小标题同系）
\newenvironment{optable}{\begin{center}\linespread{1}\fontsize{8.2}{12.8}\selectfont\sffamily\opheadcjk}{\end{center}}

%% ---------------------------------------------------------------- 列表
\setlist[itemize]{leftmargin=1.25em, itemsep=0.22em, topsep=0.32em,
  label={\textcolor{opink}{\fontsize{6.5}{6.5}\selectfont\textbullet}}}
\setlist[enumerate]{leftmargin=1.45em, itemsep=0.22em, topsep=0.32em}

%% ---------------------------------------------------------------- 目录 (TOC)
\RequirePackage{tocloft}
\tocloftpagestyle{opmain}
\renewcommand{\contentsname}{Contents}
\renewcommand{\cfttoctitlefont}{\opserif\fontsize{17}{22}\selectfont\color{opink}}
\setlength{\cftaftertoctitleskip}{2em}

% 目录局部去掉红色的超链接颜色，使用正文墨色
\let\oldtableofcontents\tableofcontents
\renewcommand{\tableofcontents}{%
  \begingroup
  \hypersetup{linkcolor=opink}%
  \oldtableofcontents
  \endgroup
}

% Section 样式：缩小字号和间距以容纳 Appendix
\renewcommand{\cftsecfont}{\rmfamily\bfseries\fontsize{10.2}{15}\selectfont\color{opink}}
\renewcommand{\cftsecpagefont}{\sffamily\fontsize{8.5}{15}\selectfont\color{opmuted}}
\renewcommand{\cftsecleader}{\hfill}
\setlength{\cftbeforesecskip}{0.6em}

% Subsection 样式：衬线常规体，紧凑排版
\renewcommand{\cftsubsecfont}{\rmfamily\fontsize{9}{13}\selectfont\color{opink!85}}
\renewcommand{\cftsubsecpagefont}{\sffamily\fontsize{8}{13}\selectfont\color{opmuted!85}}
\renewcommand{\cftsubsecleader}{\hfill}
\setlength{\cftbeforesubsecskip}{0.2em}
\setlength{\cftsubsecindent}{1.5em}

%% ---------------------------------------------------------------- 杂项
% 分隔线（替代 markdown 的 ---）
\newcommand{\opdivider}{\begin{center}%
  \tikz{\fill[opclay!75] (0,0) circle (0.5pt);
        \fill[opclay!75] (0.45,0) circle (0.5pt);
        \fill[opclay!75] (0.9,0) circle (0.5pt);}\end{center}}
% 正文小标签
\newcommand{\opmeta}[1]{{\fontsize{7.3}{7.3}\selectfont\sffamily\color{opmuted}#1}}

\endinput
