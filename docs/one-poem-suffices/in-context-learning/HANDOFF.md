# HANDOFF: 《In-Context Learning，一篇就够了》博客

> 给新 session 的 agent：读这份文档,你就能全面接手这篇博客。它告诉你所有素材在哪、当前进度、关键决策、风格硬规则、和接下来该做什么。
> 最后更新: 2026-06-26

---

## 0. 任务一句话

帮 Keli 完成博客《In-Context Learning，一篇就够了》(「One Poem Suffices」系列的深度技术博客)。**主线是 ICL 相关论文,控制论是贯穿全文的切入角度。** 目标读者:每天用 LLM/Agent 的工程师。

---

## 1. 文件在哪

### 博客本体(repo 内)
`docs/one-poem-suffices/in-context-learning/`
- **`index.md`** (~420 行) ← **正式草稿,主要工作对象**。结构:引言 → 1 What(含 1.2 五年时间线)→ 2 Why → 3 When does it work/break(控制论为隐形骨架,术语降级;含「旧怪癖/前沿现状」对照表)→ 4 The End → References → Appendix A(机制四镜头)→ Appendix B(长上下文 many-shot)
- `seed.md` — Codex 写的原始 seed(历史参考,已被 index.md 取代)
- `skeleton.md` — 结构 proposal(历史参考)
- `question-pool/` — 9 个核心问题 × 3 个模型(opus/codex/gemini)的独立回答 + 2 篇 overall-thinking。这是把研究嚼碎后的思考集合,写正文时遇到某个点可回查 `q{N}-answer-*.md`

### 调研库(Keli 的 Obsidian 知识库,简称 ego/KB)
根路径: `/Users/wenkeli/Library/Mobile Documents/iCloud~md~obsidian/Documents/knowledge/30 💡 Resources/Media Notes/`
- **`Blogs/Raw/In-Context Learning/_ICL Survey Index.md`** ← **先读这个**。按博客章节查的总索引 + 数字待核清单 + 机制骨架建议
- `Paper/In-Context Learning/` (22 篇) — 论文精华解读笔记
- `Blogs/Raw/In-Context Learning/` (8 篇) — 博客/技术报告笔记 + 上面那个索引

每篇笔记都带 `> 用途` 标注服务哪一章 + 抄准的数字 + `（待核）` 标记。**正文要引数字,先到对应笔记核对,别凭记忆。**

---

## 2. 博客的核心主张与结构

**一句话主张**:ICL 是预训练数据结构逼出来、由 attention 电路承载、在「检索已有技能 ↔ 在技能内学新参数」双模式连续谱上运行的能力;它的上限被预训练锁死,行为像一个可控但会饱和的控制系统,而推理模型的崛起正在重写「示例」的角色。

**控制论 through-line(隐形骨架,术语降级,现象先行)**:
- 引言 bullet② → 控制论作为全文视角(Keli 来写时自行定调)
- 1.5 → 埋下:训练改模型本身,ICL 改模型这一次收到的输入
- 2.0 开场 → 不再用被控对象/控制信号措辞,直接问「凭什么改变行为」
- **第 3 章 → 主场**:五节组织 = 可控性 / 上下文越长利用越不均匀 / 噪声主动带偏 / 单次无纠偏 / 闭环。每节先讲现象再贴控制论名字,Lyapunov/ISS 等形式化降进 callout
- **新增**:第 3 章开头加了「旧怪癖 / 前沿现状」对照表(5 行),直接校正 GPT-3 时代 vs Opus 4.8 时代
- **新增**:第 3 章开头先给正面判断(ICL 什么时候该用),填补原来的真空
- Appendix A.5 → 控制论是第五把镜头,与机制四镜头互补

**第 2 章(Why)**:可以「老」,讲机制传承(Xie 贝叶斯 / Lin&Lee 双模式 / Chan 数据催生 / Singh 消退)。机制深水区(induction heads / implicit GD / task vectors)放 Appendix A,别让它压垮正文。

**第 3 章(When it breaks)**:这是被重写过的核心章,控制论脊柱 + Opus-4 之后的硬料。每个失败模式紧跟对策,每条挂 paper+数字。关键来源:Bhargava(可控性)、Chroma(context rot)、Liu(lost in middle)、From Harm to Help(推理模型 few-shot 反伤)、Laban(多轮掉 39%)、Less Context Better Agents(剪枝 71→91.6%)、Stable Agentic Control(闭环稳定性)。

---

## 3. 当前进度

| 部分 | 状态 |
|---|---|
| 引言 | ⚠️ **`【Keli 来写，~400 字】` 槽位**,素材 bullets 已就位(self-evolving 动机 → `output=f(weights,context)` → 控制论 → 三问) |
| 1. What | ✅ 完成(1.1-1.5,含 1.2 五年时间线 + pre/post-training/ICL 三层对比) |
| 2. Why | ✅ 完成(2.1 双模式主叙事 / 2.2 连回 CE / 2.3 数据催生 + Singh + Mamba) |
| 3. When it works/breaks | ✅ 完成(控制论为隐形骨架;含正面判断 + 时代校正表 + 五节失败模式,post-Opus-4) |
| 4. The End | ⚠️ **`【Keli 来写】` 槽位**,素材已就位(结晶 insight + 连回系列 + self-evolving 钩子) |
| References | ✅ 完成(🔥 标推荐,含控制论组、长程 agent 组) |
| Appendix A/B | ✅ 完成 |

---

## 4. 接下来该做什么(优先级)

1. **Keli 手写引言(~400 字)和结尾**。这是「声音种子」,必须 Keli 主导。Agent 只提供素材和 review,不要代写他的第一人称定调段。
2. **(可选,已建议)** 用 Laban 的 **Concat 93.2% vs Sharded 61.8%** 强化 3.4(比现在的「平均 39%」更说明"是多轮形式而非信息量")。
3. **freeze 时做 CJK 标点规范化**:正文中英标点混用(几轮手改引入了半角 `, : ( )`,第 3 章/附录是全角 `，：（）`)。**别现在做全局 sed**(会误伤代码 `f(weights, context)`、URL、英文术语)。内容定稿后用 CJK-aware 脚本只动与中文相邻的标点。
4. review pass:对照系列前篇(context-engineering / jit-context / agent-skills)做 voice calibration。

---

## 5. 风格硬规则(必须遵守)

- **永远不用全角破折号「——」**(最高频 AI-tell)。用冒号、逗号、括号或断句。
- **黑名单短语**:值得注意的是 / 总的来说 / 综上所述 / 众所周知 / 革命性的。
- **慎用「不是X，而是Y」**(被用滥),需要对比时用「而非」且少用。
- **「克制的专家」语气**:第一人称,观点鲜明但论证审慎,多用「我倾向认为 / 可能」少用「一定 / 必须」。
- 中文正文 + 英文术语内联。MkDocs callout 用 `!!! tip/note/warning/question`。
- 引数字必须可追溯到 KB 笔记或原文;不确定标 `（待核）`,别编。

---

## 6. Keli 最该自读的 3 篇(都有独立精华解读笔记)

1. **Bhargava & Witkowski 2024, Control Theory of LLM Prompting** (arXiv 2310.04444) → `Paper/In-Context Learning/Bhargava 2024 - Control Theory of LLM Prompting.md`。控制论框架的源头,接 Harness Engineering 续集。
2. **SAIL Blog, How does in-context learning work? (Xie & Min)** → `Blogs/Raw/In-Context Learning/SAIL Blog - How Does In-Context Learning Work (Bayesian Framework).md`。最干净的 ICL 科普,第 2 章脊柱 + 写作范本。
3. **Laban 2025, LLMs Get Lost in Multi-Turn Conversation** (arXiv 2505.06120, ICLR'26 Best Paper) → `Paper/In-Context Learning/Laban 2025 - LLMs Get Lost in Multi-Turn Conversation.md`。开环失效 + self-evolving 的硬证据。

---

## 7. 注意事项

- **GPT-5.5 Pro / Codex**:Keli 视它为「大杀招」,只在 survey/validate 最重要结论时用。它的 codex `service_tier="priority"` 配置和 codex-cli 0.130.0 不兼容(会报错),要用得先修配置或让 Keli 自己跑。
- **并发 subagent 审批**:一条消息发多个 agent,审批弹窗被打断时排在前面的会被判 rejected(不是 bug,不是卡住)。被拒的单独补发即可。
- **Git**:Keli 的发布约定是 draft 分支迭代 → squash merge 回 master 留一个 `feat:` commit,只 push master。别 `git push --all`。
- 这篇属于「一篇就够了」系列(深度,30-45 min 读),不是「Thinking in Context」(随笔)。

---

## 起手式(在新 session 粘这句)

```
读 docs/one-poem-suffices/in-context-learning/HANDOFF.md 全面 orient,然后读 index.md 当前草稿。
我接下来想 <写引言 / review 第 X 章 / 补 Laban 数据到 3.4 / ...>。
调研库索引在 KB 的 _ICL Survey Index.md,引数字先核对笔记。
```
