<img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/thinking-in-context-multi-agent-header.png" alt="thinking-in-context-multi-agent-header" style="max-width: 100%;" />


# Thinking in Context: 何时需要多智能体

`READ⏰: 20min`

多智能体架构正在从实验走向生产。Kimi 的 [Agent Swarms](https://www.kimi.com/blog/agent-swarm)、Anthropic 的 [Agent Teams](https://code.claude.com/docs/en/agent-teams)，各家都在尝试更复杂的智能体组合。

去年 7 月我写过[《Multi-Agent System，一篇就够了》](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/multi-agent-system)，聚焦 Deep Research 场景下的多智能体架构，覆盖了 What、Why、How。但漏掉了一个更前置的问题：**When 何时应该使用多智能体？**

忽略该问题，可能把大量的精力投入低 ROI 的优化。Anthropic 在最新的博客 [《Building multi-agent systems: When and how to use them》](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them) 中也坦言：

> [!Important]
>
> **Anthropic 的实践经验**
>
> *"At Anthropic, we've seen teams invest months building elaborate multi-agent architectures only to discover that improved prompting on a single agent achieved equivalent results."*<br>
> 在 Anthropic，我们看到有些团队投入数月时间构建复杂的多智能体架构，结果却发现改进单智能体的提示词就能达到同等的效果。


所以这一篇，我想认真想想 "When"。让我们 Thinking in Context，思考**何时使用多智能体架构？**

- 在 [Context Engineering](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/context-engineering) 中，我们定义了上下文工程的四个支柱：**Write、Select、Compress、Isolate**。
- 在 [JIT Context](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/just-in-time-context) 一篇中，我们主要深入了 Select 和 Compress/Write，而 Isolate 只是简单提及。本篇正是对 Isolate 的展开：当单个上下文空间的优化手段用尽时，何时需要扩展为多个？
- 在上一篇 Thinking in Context 中，我们从 [Codex 的工程实践](https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/context-engineering-from-codex) 出发，着眼于单个上下文空间内的工程实践（Prompt Cache 友好的上下文设计、Append-only 的状态管理）。

**多智能体系统，本质上是多个上下文空间的系统。**这一篇我尝试从内到外：从单个上下文的内部优化，转向多个上下文之间的交互。**何时需要从一个上下文空间扩展为多个？用什么原则来判断？**

AI 发展得太快，很多博客中的一些结论可能已经过时～ 欢迎大家交流。

## 1. The Tradeoff: 多智能体的价值与代价

在前篇中，我们讨论了多智能体系统的诸多优势：并行探索带来的涌现性、突破单 Agent 上下文窗口上限的推理算力扩展（Inference Compute Scaling）、以及"搜索即压缩"的信息提炼能力。这些优势是真实的，但不完整，我当时更侧重于阐述多智能体的优势，而没有充分思考**它的代价**。重读之前的文章，我似乎在暗示：”多智能体一定比单智能体更优秀”，**但该结论并不总是正确**。这一节我将补上它们的 tradeoff。

### 1.1 价值：为什么需要扩展？

什么时候单一上下文窗口不够用？

我自己在用 Claude Code 时经常遇到一个问题：当一个长对话中积累了太多早期探索的痕迹（debug，失败的尝试、被否决的方案）Agent 后续的决策/推理质量会明显下降，有时甚至会重复之前已经失败的路径（tip：这时候手动重构一个新的上下文或许能快速解决问题）。这其实就是[上下文退化](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/context-engineering/#31)在单 Agent 内部的表现。拆分出 Sub-agent 让它在独立上下文中完成子任务再返回结果，是一种**主动的上下文噪声隔离**。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/context-failure-modes.png" alt="上下文退化的三种表现" style="max-width: 80%;" />
</div>

类似的上下文窗口不够用信号还有：研究类任务中单 Agent 串行搜索覆盖面不足，需要并行探索来扩大信息空间。并行化的价值往往先体现在**覆盖面**，而在编排得当时，速度也可能是显著收益（Anthropic 在多智能体 research 系统中报告过大幅缩短复杂查询耗时）。另一种常见信号是工具集/MCP 膨胀，当工具超过 15～20 个时（尤其是有些工具定义模糊）Agent 选择准确率显著下降，此时需要将工具拆分到专业化的 Sub-agent（e.g. 有些 Sub-agent 专门负责搜索，有些 Sub-agent 负责最终报告的可视化等等）。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/tool-scaling-nonlinear.png" alt="工具数量与 Agent 准确率的非线性关系" style="max-width: 90%;" />
</div>


归纳一下，这些信号有一个共同点：**单一上下文窗口已经无法承载当前任务的需求**。这也是上下文工程中 **Isolate** 机制的三种触发条件：隔离噪声（避免失败路径污染后续推理）、隔离关注点（让专业化的工具集各司其职）、或突破物理限制（并行扩展单 Agent 的 Token 上限）。

### 1.2 代价：为什么扩展需要谨慎？

然而，扩展并非没有代价。

最直观的是 **Token 成本的跃升**。Anthropic 的实践数据表明：Agent 比普通聊天多用约 4x Token，多智能体系统则多用约 15x（最近大家有用过 OpenClaw 也会发现，token 用的和流水一样）。我在前篇中提过这组数据，但当时更多是作为 Inference Compute Scaling 的正面证据（"投入更多 Token 能获得更好的性能"），而没有强调它同时也是一笔实实在在的成本，并且没有思考投入这些成本所带来的 ROI **是否一定高**。

另一个更根本的问题是**信息在传递中不可避免地损耗**。Orchestrator 将任务传递给 Sub-agent 时，原始意图中的微妙之处可能被简化；Sub-agent 返回结果时，探索过程中的上下文线索又被压缩掉。多数跨 Agent 的传递都伴随着信息损耗。用前篇的概念来说：多智能体 Scale 的是系统的 Token 总预算，但每次传递都有不可忽视的"通信税"，**并且在某些错误的多智能体划分下，增加的预算大部分都被用来交“通信税”了**。花了更多钱（有时甚至多一个量级），但没有得到显著的性能提升。

更隐蔽的代价是**隐式决策链的断裂**（来自 Cognition 的 [Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents#a-theory-of-building-long-running-agents)）。每一个代码变更背后都隐含着未被显式写出的决策逻辑，"选择修改这个文件而非另一个"意味着 Agent 对架构有某种理解。

最理想的情况下，我们 fork 上下文以保证 Sub-agent 拥有相同的上下文，这似乎不再有上下文的问题了。但是，当多个 Agent 并行工作时，它们无法共享这些隐式逻辑，这一定会导致上下文不一致。并且 Sub-agent 返回的结果一般是**高度总结后的信息**，这类隐式决策会随之被隐藏无法传递到 Orchestrator 中。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/implicit-decision-chain.png" alt="隐式决策链断裂示意" style="max-width: 70%;" />
</div>

例如，Sub-agent A 选择了某种数据结构，Sub-agent B 不知情地引入了不兼容的依赖。冲突的根源更多从“代码写错了”（模型能力），转移为**决策上下文的碎片化**（多智能体架构导致关键上下文不共享）。Cognition 将这个现象概括为 **"Actions carry implicit decisions"**，每个行动都暗含决策，拆分 Agent 就是在拆分决策链，容易引入难以预料的问题。

> [!Tip]
>
> **与 Codex 文章的呼应**
>
> 这个问题与我们在 [Codex 上下文工程](https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/context-engineering-from-codex) 中讨论的 Append-only 模式相关。Codex 选择 Append-only 而非原地修改，一个重要原因是**保留因果链**——模型不仅需要知道"现在的状态是什么"，还需要知道"为什么是这个状态"。拆分 Agent 本质上是在打断这条因果链：每个 Sub-agent 只看到自己的行为序列，无法追溯其他 Agent 的决策路径。


## 2. Context Coupling: 以耦合度为拆分标准

理解了上下文空间扩展的价值和代价之后，核心问题变成了：**用什么维度来判断"何时该扩展为多智能体架构"？**

### 2.1 按问题类型一刀切的局限

一种常见的方式是按问题类型一刀切：研究类任务 → 用多智能体；编码类任务 → 用单智能体。我在前篇中也隐含了这种逻辑，整篇博客的主要案例是 Deep Research，可能给读者的印象是"多智能体 = 适合做搜索"。

但这种分类过于粗糙。一个真实的 Coding Agent 场景中：

- **代码搜索**：在大型代码库中定位相关文件，搜索路径之间互不依赖，上下文耦合度低，适合拆。Claude Code 的公开文档中也能看到这类并行探索思路（如 Agent Teams / subagents）([Claude Code Docs](https://code.claude.com/docs/en/agent-teams))。
- **核心编码**：需要理解完整的代码上下文，函数调用关系、类型定义、设计约束，一个函数的修改可能牵连多个文件，**上下文耦合度高**，不适合拆。
- **前后端并行开发**：理论上可以规定好 API 后并行，但中途任何 Plan 变更都可能导致接口不一致。

同一个"编码类"项目中，既有适合拆分的子任务，也有不适合拆分的子任务。按问题类型一刀切，无法捕捉这种粒度差异。更典型的**错误例子**是按工作类型划分：一个 Agent 编写功能，另一个编写测试，第三个审查代码。这看起来像合理的分工，但每次交接都在丢失上下文：

1. 编写测试的 Agent 不知道实现时为何选择了某种方案。

2. 审查代码的 Agent 更不知道探索过程中排除了哪些替代方案。

并不能据此武断地说 “**编码类任务不适合多智能体**”。主要是这种按功能阶段的拆分恰好切在了**上下文耦合度最高的地方**。

### 2.2 把边界画在上下文的边界上

既然按问题类型划分不够精细，那更好的判断标准是什么？

我认为答案是**上下文耦合度：两个子任务需要共享多少上下文才能各自正确完成**。Anthropic 在最新博客中称之为 **Context-Centric Decomposition**（以上下文为中心的任务分解），并视其为多智能体系统中的关键设计决策之一。我觉得这个提法很准确，也足够提点我。

核心思想是：**决策的边界应该沿着上下文的边界来画，而非沿着功能的边界。**

正如 2.1 中讨论的，按功能阶段拆分（规划→编码 | 测试 | 审查）恰好在耦合度最高处画线。在**耦合度最高的地方**画边界，结果就是典型的"电话游戏"：原始的设计意图和考量在每一次传递中被简化、被误解，到最后一环可能已面目全非（下图是通信税效应的示意）。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/token-vs-communication-tax.png" alt="Token 预算与通信税的关系" style="max-width: 90%;" />
</div>


这个原则类似于分布式训练中数据并行与模型并行的选择。数据并行按 batch 拆分（各 GPU 处理不同数据，模型相同），通信开销低，因为 batch 之间天然独立；模型并行按网络层拆分（不同 GPU 负责不同层），通信开销高，因为层与层之间存在强依赖——每一层的输出是下一层的输入。**在有选择的情况下，沿低耦合边界拆分的通信成本更低**——正如单卡能容纳模型时，数据并行几乎总是首选。Agent 拆分同理：不是说高耦合处"不能"拆，而是拆的代价更高，只在确实必要时才值得。

一个能很好说明这个原则的例子是 **Verification Subagent**（验证子智能体）。这可能是表现最稳定的多智能体模式。为什么？因为验证 Agent **不需要知道主 Agent 是如何构建输出的**，它只需黑盒测试最终产出物。需要传递的上下文只有：验收标准和待验证的产出物。上下文传递量降到最低，信息损耗也降到最低。

反过来说，**如果一个子任务需要继承大量前序 Agent 的决策历史才能正常工作，那它可能不适合被拆分。**

## 3. In Practice: 两个实际场景

抽象的原则需要具体的场景来检验。

### 3.1 Deep Research：天然的低耦合

Deep Research 是多智能体架构的"理想型"场景。用上下文耦合度的视角来看，原因很直接：**研究路径之间天然独立**。

搜索"半导体行业的供给侧分析"和搜索"需求侧的市场趋势"是两条各自独立的路径，路径 A 不需要知道路径 B 发现了什么。每条路径会产生大量的原始搜索结果（5000～8000 tokens 的网页、报告、新闻），但对其他路径来说这些都是纯噪声。最终汇聚到 Orchestrator 的可能只有每条路径 300～500 tokens 的关键发现。这就是[前篇](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/multi-agent-system)中说的"**搜索即压缩**"。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/deep-research-orchestrator-worker.png" alt="Deep Research 的 Orchestrator-Worker 结构示意" style="max-width: 85%;" />
</div>


在 Anthropic 的 Claude Research 实现中，这表现为经典的 Orchestrator-Worker 模式。Orchestrator 的核心工作本质上是两个上下文工程操作：下行的 **Context Isolation**（为每条研究路径创建独立的上下文空间）和上行的 **Context Compression**（从子 Agent 产出中提炼关键信息）。

### 3.2 Coding Agent：选择性拆分

Coding Agent 更复杂，因为同一个项目内部存在**耦合度差异显著的子任务**。

核心编码（理解需求、设计架构、编写实现）需要完整的代码上下文。一个函数的修改可能影响多个文件的类型定义和测试用例。在 `module_a.py` 中选择某种数据结构，会隐式约束 `module_b.py` 的实现方式。如果拆分，就会面临 Cognition 描述的问题：**隐式决策链断裂，各自合理的输出组合后产生冲突。**

但 Coding 涉及的任务非常多元：代码搜索（搜索路径间互不依赖，一般是在初始的 Plan 模式下）、文档消化（读取整份 API 文档但只需提取少量相关信息，基于某些最新的库实现功能）、测试验证（黑盒测试最终产出物），这些子任务的上下文耦合度较低，适合拆分。

经常用 Claude Code 也能体会到他们的这种设计。结合公开文档和实际体验，Sub-agent 更多承担探索、调研、验证等子任务，再由主 Agent 汇总整合（可以理解为"单智能体 + 可调度的 Agentic 工具"）。

<div style="text-align: center;">
  <img src="https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/when-multi-agent/assets/claude-code-subagent-example.png" alt="Claude Code Sub-agent 调度示例" style="max-width: 70%;" />
</div>

这里大概归纳了一个表格：

| 子任务 | 上下文耦合度 | 适合拆分？ | 代表实践 |
|--------|------------|-----------|---------|
| 代码搜索 / Codebase Exploration | 低 | 适合 | CC Explore agents |
| 文档消化 / API 理解 | 低 | 适合 | Sub-agent 读取后返回摘要 |
| 测试验证 / Linting | 低 | 适合 | Verification Subagent |
| 核心编码 / 架构设计 | 高 | 不适合 | 保持在主 Agent 内 |
| 前后端并行开发 | 中→高 | 谨慎 | 接口变更导致频繁同步 |

> [!Warning]
> 
> **关于并行开发的陷阱**
>
> 一个容易想到的方案是：规定好 API Interface，让两个 Agent 分别开发前端和后端。理论上可行——如果接口在开发过程中始终不变。但实践中初始 Plan 几乎不可能完美，中途变更会导致频繁的上下文同步——而 1.2 节分析的信息衰减效应会在每一次同步中累积。**同步的难度与耦合度成正比**。


### 3.3 是 Sub-agent 还是 Agentic Tool？

对比 Deep Research 和 Coding Agent，我发现：**目前公开了架构细节的多智能体系统，有价值的实现大多采用 Orchestrator-Worker 模式**，比如 Claude Code 的 Explore/subagents 和 Claude Research 的子智能体机制。Sub-agent 更像是被主 Agent 调用的 Agentic Tool（调用 → 独立上下文执行 → 返回结果），而非独立 Agent 间的 peer-to-peer 协作（A2A，不过那样也不叫 Sub-agent 了）。

这或许意味着"多智能体"在实践中比概念上更为朴素。当然也意味着未来可能有更大的展望空间（最近 Grok 4.2 好像出了 4 agents 模式 “**Four-Brain**”）。如果你的 Agent 已经在调用 Sub-agent 做搜索或验证，那你可能已经在使用多智能体了，只是没这么称呼而已。

## 4. The Decision Framework: 何时拆分

上面的分析可以归结为一个简洁的判断流程。

**先穷尽单 Agent 的优化空间。** Prompt 是否足够清晰？是否做了上下文压缩？工具描述是否准确？是否使用了 [Tool-search-tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool) 进行工具集的优化。Anthropic 和 Cognition 在这一点上有共识：==*"Start with the simplest approach that works."*== 很多看似需要多智能体的问题，实际上是单 Agent 的上下文管理没有做好。

**如果仍有瓶颈，识别信号。** 上下文窗口接近极限（表现为幻觉率上升、忽略早期指令）、工具集过大（频繁选错工具，并且工具集内有明显的专业领域区分）、需要覆盖大信息空间（搜索覆盖面不足），这些都是可能需要拆分的信号。

**拆分时，按上下文耦合度画线。** 低耦合子任务（搜索、验证、独立研究路径）→ Isolate 为 Sub-agent；高耦合子任务（核心编码、状态共享、顺序依赖）→ 保持在主 Agent 内，用 Compress 管理增长。如果不确定？默认不拆：**拆错的代价（信息损耗 + 决策不一致）通常大于不拆的代价（上下文略显冗余）**。

AI 的发展太快了，所以我认为**未来上下文耦合度一定不是唯一的决策维度**。延迟要求可能迫使并行化，权限边界可能要求 Sub-agent 在不同安全域执行。但对于大多数 Agent 开发者面临的决策，上下文耦合度仍然是最具解释力的标准，它直接决定了拆分后**信息损耗的程度**。

## 5. The End

回到开篇的问题：何时需要多智能体？目前我们的回答是：在于**子任务间的上下文耦合度**。

耦合度低（搜索、信息消化、黑盒验证）→ 拆分有价值；耦合度高（核心编码、状态共享、顺序依赖）→ 保持单一上下文，用 Context Compress 管理上下文增长。同一个项目中，不同子任务的耦合度处于不同位置，正确的做法不是一刀切，而是逐子任务判断。

从 Codex 的 Append-only（保留单 Agent 内的因果链完整性）到 Context Engineering / JIT Context 中的四个支柱：**Write、Select、Compress、Isolate** 再到本篇的 Context-Centric Decomposition（在多 Agent 间沿上下文边界画线）。上下文工程的核心原则可以归纳为三个层次：**微观层面保护上下文完整性**（Append-only 保留因果链），**中观层面优化信噪比**（Write/Select/Compress 确保每次推理拿到的是高密度的必要上下文），**宏观层面沿低耦合边界进行隔离**（Context-Centric Decomposition）。

本文主要从上下文工程的视角探讨多智能体的决策原则。Anthropic 的原文还包含了许多代码级别的实践细节（如 delegation prompt 的写法、Sub-agent 的错误处理、结果校验策略等），**再好的上下文压缩算法永远比不过直接读高信噪比的原始上下文**。推荐感兴趣的读者直接阅读 [原文](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)。

最后用 Anthropic 的话收束。这句话从 2025 年的 [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) 到最新博客始终出现，我很喜欢它：

> [!Tip]
> 
> **"Start with the simplest approach that works, and add complexity only when evidence supports it."**


---

## References

- [Anthropic: Building multi-agent systems: When and how to use them](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)（2026.01）
- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system)（2025）
- [Anthropic: Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)（2025）
- [Claude Code Docs: Agent Teams](https://code.claude.com/docs/en/agent-teams)（2026）
- [Cognition: Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents)（2025.06）
- [My Blog: Multi-Agent System，一篇就够了](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/multi-agent-system)
- [My Blog: Context Engineering，一篇就够了](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/context-engineering)
- [My Blog: Just-in-Time Context，一篇就够了](https://keli-wen.github.io/One-Poem-Suffices/one-poem-suffices/just-in-time-context)
- [My Blog: Thinking in Context：Codex 中的上下文工程](https://keli-wen.github.io/One-Poem-Suffices/thinking-in-context/context-engineering-from-codex)

