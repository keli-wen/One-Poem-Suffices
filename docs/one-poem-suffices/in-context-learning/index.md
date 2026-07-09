# In-Context Learning，一篇就够了。

`READ⏰: ~35min`

!!! ambition "One Poem Suffices"

    ☁️ *output = f(weights, context)*

## 引言

【Keli 来写，~400 字】

以下是可用素材和节奏建议。（注：旧版引言承诺「控制论作为全文 through-line」，新版已把控制论降级为第 3 章的局部词汇，引言不必再提；全文唯一主线是「降低不确定性」。）

- **个人动机**: 最近在做 self-evolving / learning harness / skills-as-model-weight 相关的思考，回过头来发现一个基础问题一直没有认真想过。output = f(weights, context)，如果不能 fine-tune，我们能不能 tune context？但修改 context 真的算「学习」吗？
- **两个观察**:
    - ① ICL 是 Context Engineering 的地基。之前几篇博客讨论的都是如何组装上下文，这篇要补的是：上下文进了窗口以后，凭什么有效？（Prompt / RAG / Skills 的分层关系 1.4 会讲一次，引言不必展开。）
    - ② context 的价值不取决于放了多少信息，而取决于把当前任务的不确定性降低了多少。这是全文唯一的主线：第 2 章从模型侧建立它，第 3 章用它逐个审视失效。
- **诚实声明**: ICL 的底层机制到今天仍然没有统一理论，但零件是确证的：哪些类型的训练数据催生了 ICL、模型内部存在什么样的电路、上下文如何被压缩成可搬运的表征。正文只推一个对工程最有用的主叙事，四把学术镜头放在 Appendix A；工程结论对「最终哪把对」是鲁棒的。
- **三个问题**:
    - **What?** 什么是 In-Context Learning？它和我们天天在用的 Context Engineering 是什么关系？
    - **Why?** 为什么上下文能改变模型行为？目前有哪些可靠的解释？
    - **When does it break?** 什么时候 ICL 会失效，我们能做什么？

---

## 1. What is In-Context Learning?

### 1.1 参数没变，行为为什么变了？

从你最熟悉的场景开始：

- 给模型三条翻译示例，它自动沿用同样的翻译风格
- 给一个 JSON schema，结构化输出的概率大幅提高
- 给 Agent 一个 Skill 文件，它按步骤做事而不是重新探索
- 给一段检索到的资料，模型会修改原来基于参数知识的回答
- 给一段错误或冲突的上下文，模型也可能被带偏

这些场景有一个共同点：**模型权重一个参数都没动，但行为变了。**

这就是 In-Context Learning (ICL)。这个现象在 2020 年因为 GPT-3 第一次进入主流视野，而它的含义在过去五年里早已超出了最初的 few-shot 范畴。

### 1.2 它从哪来：被撞见，然后被改写

ICL 不是被设计出来的，是被撞见的。2020 年 GPT-3 的论文标题就叫 *Language Models are Few-Shot Learners*（Brown 2020）：一个只被训练来预测下一个 token 的模型，你在 prompt 里塞几组示例，它就能完成没专门训练过的任务，全程不更新一个梯度。「In-Context Learning」这个词从这里进入主流。它最初的意思很窄，就是 few-shot：给几组 `输入 → 输出`，让模型照着做。

接下来的几年，研究者主要在小模型和 few-shot 分类上追问它为什么 work（第 2 章和附录 A 的机制工作大多出自这个时期），顺带刨出一批「怪癖」：示例顺序敏感、标签好像可以乱给、输出需要概率校准。再往后，两件事同时改写了这个领域：窗口涨到百万 token，示例可以从几个堆到上千个；会自己长篇推理的模型出现，few-shot 第一次出现反效果。讨论的重心也随之从「单次 prompt 怎么写」移到「多轮、长程、带工具反馈的 agent 里 context 怎么管」。

这条时间线是理解后文的一个坐标：**早期那些关于「示例怎么摆」的怪癖，大多随模型变强而消退；真正没解决的失效，搬进了 agent 闭环。** 第 3 章开头有一张表，把最有名的几个怪癖逐个对齐时代。

### 1.3 狭义 ICL 和广义 ICL

提到 ICL，很多人脑子里浮现的是 few-shot：给几组 `输入 → 输出`，模型归纳映射，预测下一个。这是学术论文里最常见的实验设定，也是 GPT-3 论文最初讨论的形态。但今天我们实际在用的 ICL，范围要大得多。

指令让模型知道目标，示例让它校准格式，RAG 补充事实，Memory 提供偏好，Skills 提供流程，工具定义告诉它能做什么。这些都是上下文在改变模型行为，都是 ICL 的不同载体（Dong et al. 2024 的综述用 "learning from context" 来统括这个更宽的定义）。为方便讨论，前者叫**狭义 ICL**，后者叫**广义 ICL**。

本文主要使用广义定义。但在讨论论文和机制的时候会回到狭义定义，因为 few-shot 是最容易做控制变量实验的形态。

### 1.4 谁送上下文，谁让上下文生效

把几个常混淆的概念理成层级关系：

- **Prompt / RAG / Memory / Skills / Tool definitions** = 上下文的运输方式。它们把不同来源、不同形态的信息送进窗口
- **In-Context Learning** = 模型拿到上下文后改变行为的过程。解释的是「进了窗口以后，凭什么有效」
- **Fine-tuning / Pre-training / RLHF** = 改变模型权重。改的是模型「以后怎么答」，而不是「这一次怎么答」

连回系列：[Context Engineering](../context-engineering/) 讨论「如何组装最优上下文」，[JIT Context](../just-in-time-context/) 讨论「上下文如何按需加载」，[Agent Skills](../agent-skills/) 讨论「程序性知识如何打包复用」。这些都默认了一个前提：上下文进入窗口后对模型有用。ICL 这篇补的就是这个前提。

!!! note "ICL 和 Prompt Engineering / Context Engineering 是什么关系？"

    直觉上很想说「prompt engineering 基于 ICL」。用广义 ICL 这么讲是成立的：你写 prompt、做 RAG、配 Skills，本质上都在利用模型从上下文中调整行为的能力。但用狭义 ICL（few-shot）来说就不准确了，RAG 和 Memory 跟 few-shot 没什么关系。更精确的表述是：Context Engineering 是在工程侧优化模型的输入，ICL 是模型侧解释这些输入为什么能改变输出。一个管供给，一个管消化。

---

## 2. Why does ICL work?

到这里有一个自然的追问：模型没更新参数，上下文凭什么就能改变它的行为？这一章试着给一个对工程实践有用的回答。只关心怎么用的读者可以直接跳第 3 章（更细的机制讨论放在了 Appendix A）。

我先把这一章的主线说在前面。阅读了一批论文之后，结合自己的工程实践，我更倾向于这样理解 ICL：**它的核心作用是降低不确定性。** 一个预训练好的模型内部装着海量的能力，面对一个新输入，它不确定该用哪个能力、怎么用、用到什么程度。上下文的作用就是降低这些不确定性。Jeon 2024 (ICML) 从信息论角度给了这个直觉一个形式化：ICL 的误差可以分解为 meta-learning error 和 intra-task error 两项，每增加一条有效上下文都在降低任务后验的熵（增益有边际递减，附录 B 的 many-shot 曲线是它在行为层的一个侧影）。后面三节分别回答：这个降低是怎么发生的（2.1），模型凭什么能做到这件事（2.2），以及这个视角如何连回 Context Engineering（2.3）。

### 2.1 上下文如何降低不确定性

模型在预训练时见过海量任务。当你给它上下文，它做的事情类似于从自己学过的所有能力里，找到当前最可能的那一类，然后按这类任务的规律去预测输出。几个示例就像线索，帮模型把一个巨大的可能性空间收窄到一个小范围。用 Xie 2021 的话说，这个过程等价于隐式贝叶斯推断：上下文让模型对「当前是什么任务」的后验分布变得更尖锐。

这个洞察在 GPT-3 时代提出，但它的核心（上下文 = 缩窄后验）经受住了后续的验证。Lin & Lee 2024 (ICML) 在现代规模上把图景做了升级，给出了一个更完整的框架：上下文同时做两件事。

1. **检索 (task retrieval)**：在预训练学会的技能集合里挑出最匹配的一个。示例主要用来缩小搜索范围，标签的具体对错没那么关键。这是在降低「该用哪个技能」的不确定性。
2. **学习 (task learning)**：在选中的技能内部，根据示例微调参数（在激活空间里，不是梯度更新）。这时候标签被当作真正的训练信号，模型会去读并利用它们。这是在降低「这个技能该怎么用」的不确定性。

谁主导取决于模型规模和示例数量。小模型或 few-shot 偏检索，大模型或 many-shot 两件事都能做。这个双模式框架同时解释了两个看似矛盾的经典实验（3.1 节的 callout 会再展开）：Min 2022 发现随机标签几乎不影响表现（检索模式，不确定性主要在「哪个技能」），Wei 2023 发现大模型能学进翻转标签（学习模式，不确定性已经深入「怎么用」）。

一个关键推论：**好的 context 让模型更确定当前该做什么；坏的 context 让它更不确定，甚至确定地指向错误方向。** 这也是第 3 章讨论失败模式的理论基础。

!!! note "这章引的论文看起来比较「老」？"

    1.2 的时间线已经解释了这一点：ICL 机制研究的奠基工作集中在 2021–2024 年，2025–2026 的进展主要在更大模型上验证和细化这些框架。Xie 的贝叶斯框架虽然提出于 GPT-3 时代，但「上下文缩窄后验」这个核心洞察是架构无关的，Lin & Lee 2024 在现代规模上验证了它。正文里经典论文偏多是这个领域的特点。

### 2.2 是什么让模型具备了这个能力？

上一节说的是 ICL「在做什么」，这一节回答「模型凭什么能做到」。答案不是一个单一因素，而是三样东西的组合。

**架构提供了机制。** 模型需要一种方式来「回看」上下文中的每个 token。Attention 正是这个机制：它让模型在生成每一个 token 时，都能看到前面所有内容，并决定把注意力分配给谁。这是 ICL 的物理基础。没有这种回看能力的架构（比如纯前馈网络）做不了 ICL。Mamba（state space model）和 xLSTM 也展现了 ICL 能力，只是在需要精确回看上文的任务上明显弱于 attention，所以实践里常用混合架构（Park 2024）。

**数据提供了模式。** 光有 attention 架构还不够。Chan 2022 (NeurIPS Oral) 用一个干净的因果实验证明了这一点：同一个 Transformer，只换训练数据分布，就能把 ICL 能力开关。要让 ICL 涌现，数据需要同时具备三个属性，每个都有明确的「为什么」：

- **同类样本在窗口内成簇出现 (burstiness)**。如果训练数据是均匀 i.i.d. 的，窗口内几乎碰不到同类样本，模型没有理由去学「读上下文里的邻居再做判断」这个策略。Burstiness 让窗口内经常出现同类线索，模型被迫发展出利用上下文的回路（即 induction head 这类电路）。简单说：burstiness 制造了「上下文里有线索可用」的训练信号。
- **大量只出现几次的稀有类 (长尾分布)**。高频类出现足够多次，模型可以直接把映射关系「背」进权重；但长尾上的稀有类每个只出现寥寥几次，权重根本记不住。模型被逼学一套通用策略：「不认识这个类？去读上下文里的 example-label 对，现场推断。」这就是 ICL。如果所有类都高频且均匀，模型全部背住，ICL 就不会出现。
- **同一个标签在不同上下文中含义不同 (歧义性)**。这直接摧毁了「label → class 的全局固定映射」。模型无法把 label 的含义写死进权重，因为同一个 label 下次可能指向完全不同的东西。唯一的出路：每次都看当前上下文里的 example-label 配对，现场确定含义。

自然语言的 token 分布恰好落在这三个条件的交汇处。这是目前 ICL 研究里最硬的因果证据：不是 attention 架构自动给你 ICL，是数据结构逼出来的（B. Chan et al. 2024/ICLR 2025 进一步把这三个条件理论化为「数据对模型的可学习性」：IWL 能收敛的数据走权重，IWL 收敛不了的数据才逼出 ICL）。

**训练目标提供了激励。** 一个自然的疑问：训练目标和架构是不是同一个论点？毕竟 Transformer 就是用 next-token prediction 训练的，两者似乎绑在一起。但实验证据表明它们是可分离的。一方面，BERT 用 masked language modeling（不是 next-token prediction）训练，Samuel et al. 2024 (NeurIPS) 证明 DeBERTa 也能做生成式 ICL，性能匹敌同时代的 GPT-3。这说明 ICL 不是 next-token prediction 的专属产物。另一方面，Mamba 也用 next-token prediction 训练，但检索类 ICL 明显弱于 Transformer（NVIDIA 的大规模实证 Waleffe 2024：纯 SSM 在 5-shot MMLU 上比同规模 Transformer 低约 15 个百分点）。所以架构和训练目标各自有独立的贡献：架构决定了模型能不能「回看」上下文（attention 的强项），训练目标决定了模型有没有激励去利用上下文（next-token prediction 天然奖励这件事）。两者可以被实验拆开，Park 2024 的 MambaFormer（Mamba 层 + Attention 层混合）在两类模型各自薄弱的任务上都取得最优，进一步确认了它们是可叠加的独立贡献。

这三样缺一不可。所以「预训练教会了模型 ICL」更精确的说法是：具备回看能力的架构，在合适的数据上，用鼓励利用上下文的训练目标训练，自然涌现出了利用上下文降低不确定性的能力。

!!! note "Post-training 在这里扮演什么角色？"

    一个容易混淆的点：instruction tuning、RLHF 这些 post-training 并不创造新的 ICL 能力。Bigoulaeva 2025 在 90 个模型上的实验显示，post-training 主要降低的是「理解指令格式」的门槛，能力上限由 pretraining 决定；He & Cao 2025 的分析进一步指出，它调节的更多是模型的 confidence，而非重构语义。这意味着：你在 prompt 里能「教」模型做什么，取决于预训练阶段已经学进去了什么。

!!! question "ICL 和「死记硬背」会竞争吗？"

    会。Singh 2023 (NeurIPS) 在合成数据上发现，模型训练早期先学会了「看例题举一反三」(ICL)，但训练继续下去之后，渐渐转向「把答案背下来」(in-weights learning)，ICL 能力反而衰退了，而训练 loss 全程在降。Wurgaft 2025 用一个经济性权衡模型几乎完美预测了这条曲线：当「背下来」比「现学」更省力时，模型就切换策略。不过自然语言的长尾分布意味着大量稀有任务永远不可能被背下来（出现次数太少），模型只能靠上下文现学，长尾充当了 ICL 的「保险丝」。

**模型越强，需要的*示例*越少，但不意味着不需要上下文。** 更强的模型只需要更少的线索就能定位到正确的技能（检索模式更高效了）。但指令、事实（RAG）、工具定义、输出格式约束，这些在任何规模的模型上都在发挥作用。少的是「要给几个示例模型才明白你想做什么」，不是「上下文整体变得不重要了」。这也是 3.4 节会展开的话题。

!!! note "这些机制解释在大模型上验证过吗？"

    ICL 机制研究集中在 13B 以下，但并非完全没有大模型的工作。Bansal 2023 (ACL) 在 OPT-66B 上做了可解释性分析，发现约 70% 的 attention head 和 20% 的 FFN 可移除而不显著损害 ICL，少数 head 在 induction 原语上得分极高。Lieberum 2023 在 Chinchilla 70B 上做了 circuit analysis，验证了 mech interp 技术在 70B 量级基本可用。Anthropic 2024-2025 用 SAE 和 attribution graph 在 Claude 3 Sonnet / 3.5 Haiku 上做了大规模可解释性研究（Scaling Monosemanticity, Circuit Tracing），证明了前沿模型内部确实存在可定位的抽象概念和推理链路，但这些工作没有专门瞄准 ICL few-shot 机制。行为层面的证据更充分：Wei 2023 在 GPT-3 / PaLM 全系列上确认了大模型能覆写 in-context 先验（小模型做不到），Agarwal 2024 在 GPT-4-Turbo / Claude 3 Opus / Gemini 1.5 Pro 上测试了 many-shot ICL 的 scaling 曲线。总的来看：大模型上有行为验证和初步的可解释性探索，但 ICL 完整回路的机制拆解仍然缺位。我更倾向把 2.1-2.2 的机制当作建立直觉的心智模型，而非可以精确描述前沿模型内部的物理定律。想深入机制细节的读者可以翻到 **Appendix A**。

### 2.3 从模型侧到工程侧

把这一章的结论放回系列的坐标系里。ICL 是模型侧的机制：模型读 context，降低对任务的不确定性。[Context Engineering](../context-engineering/) 做的是工程侧的同一件事：选择放什么信息进 context，让模型的不确定性降得最多。上下文的价值不取决于你放了多少 token，而取决于这些 token 是否让模型在当前任务上更确定了。除了给模型更好的信息，还可以直接限制它的行动空间（有界的工具集合、确定性逻辑在边界上兜底），这是系统侧的手段，留给下一篇 Agent Harness 展开。

第 3 章讨论的所有失败模式，都可以用这个视角读：不确定性没有被降低，甚至被推高了。

---

## 3. When does ICL work, and when does it break?

行文至此，我们知道了 ICL 是什么、为什么有效。这一章回到一个更实用的问题：什么时候该用它，什么时候它会失效？

ICL 最顺手的场景是：任务能被预训练见过的某个技能覆盖，你只需要用少量线索（指令、示例、检索到的事实）把模型定位过去，而且单次或短程就能完成。它开始吃力的地方是：需要精确逐字回看大量内容、需要学一个预训练里没有的全新机制、或者任务长到要跨很多轮不断和工具来回（我自己在用 Claude Code 时经常感受到后一种：长对话积累太多早期探索的痕迹后，agent 后续的决策质量会明显下降）。后面几节展开的就是后半句。

但在拆失效之前，先做一次时代校正。1.2 说过，早期那些关于「示例怎么摆」的怪癖大多已经消退。下面这张表把几个最有名的「ICL 怪癖」对齐时代，免得拿 GPT-3 时代的结论来套今天的模型：

| 经典「怪癖」 | 来源（时代） | 当年的结论 | 前沿现状 |
|---|---|---|---|
| 示例顺序极度敏感 | Lu 2021，GPT-3 2.7B | 换个顺序，准确率 54% → 93% | 明显消退。系统性复测不多，但当年两位数的波动在前沿模型上已难复现 |
| 标签可以乱给 | Min 2022，小模型 | 随机标签只掉 1.7~2.6% | 大模型转「学习模式」，能学进翻转标签（Wei 2023） |
| 需要概率校准 | Zhao 2021，GPT-3 | recency / majority 偏置要靠 contextual calibration 修 | 显著缓解，这类校准手段在前沿模型的实践里已基本退场 |
| lost in the middle | Liu 2023，GPT-3.5 | 中段 75.8% → 53.8%，比闭卷还低 | 结构性，**没有消失**；2026 年的理论工作证明它训练第 0 步就在 |
| few-shot 总是有用 | Chat 时代默认 | 给几条示例 ≈ 免费提升 | 推理模型上**反伤**，单条 demo 掉 6~16%（Wang 2025） |

看这张表的走向：前三行是弱模型时代的不稳定，基本随模型变强而溶解（如果你今天还在纠结示例顺序，可能是在解决一个已经消失的问题）。后两行不一样，一个是结构性的（lost in the middle），一个是新冒出来的（推理模型反伤）。**真正还活着的失效，没有一个停在「单次 prompt 怎么写」这一层**，它们都搬去了长程、多轮、带工具的 agent 场景。

下面按读者离失效最近的顺序走：先看单次 prompt 里 context 的三个局限（推不动、用不匀、被带偏），再看两个新时代的失效（信号打架、误差累积），最后落到 agent 里的 context 管理。判据始终是第 2 章那条：这段 context 在降低不确定性，还是在推高它。

### 3.1 先验的墙：有些输出你就是推不过去

你给了正确的事实，模型就是不采纳，还是用参数里的旧知识回答。反过来，你贴了段过时的资料，它就直接跟着错了。（用过 RAG 的人应该都踩过这两种坑。）这两件事是同一个问题的两面：context 和模型的参数先验在拉扯，谁赢并不总是你说了算。

不过这堵「先验的墙」比想象中好推。Bhargava 2024 在 Falcon / Llama 上实测，**97% 的正确 next token 能用长度 ≤10 的 prompt 触达**，先验概率低远不等于不可达。但墙确实存在：当目标输出和模型先验差得太远，而 context 长度又有限时，目标就落在可达范围之外（Nosrati 2026 给了这个不可达条件的形式化）。推力有上限。

!!! note "「推」不是随手的比喻"

    这一章会偶尔借用控制论的词汇（可控性、开环、闭环）。它们有严格形式化打底：Bhargava & Witkowski 在 ICML 2024 把 LLM 建成离散随机动力系统，prompt 是控制输入，上面 97% 的数字就来自这篇；Nosrati 等人 2026（When Control Meets LLMs）推进成完整的 plant / state / feedback 框架。正文只用直觉版，对形式化感兴趣的读者可以从这两篇进，这条线在下一篇 Agent Harness 里还会回来。

!!! note "示例标签该不该较真？一个正在退场的老问题"

    在 GPT-3 到 GPT-4 那几年，「示例标签对不对重要吗」是个热门问题。Min 2022 发现把正确标签换成随机标签只掉 1.7%~2.6%（标签空间和格式保留的前提下）；Wei 2023 又发现大模型能从翻转标签里学到翻转映射。这个张力就是 2.1 讲的双模式：检索模式下标签是定位线索（扰动不影响），学习模式下标签是训练信号（正确性关键），模型越大越偏学习模式。同一时期还有一类发现是示例顺序的敏感性：Lu 2021 在 GPT-3 2.7B 上仅仅换示例顺序，准确率就能从 54% 跳到 93%，Zhao 2021 把它归因到 recency / majority / common-token 三种偏置，并用 contextual calibration 校正。这些本质上都在问「几个示例能不能把模型的后验推到目标任务」。在弱模型上很致命的不稳定，到 Opus 4 级模型上已大幅缓解，这个游戏基本结束了，所以我把它压进 callout。细节见 Appendix A。

**实践启发**：

- 和参数先验可能冲突的关键事实，放在显眼位置（开头或结尾，3.2 会解释为什么），并明确指示优先级：「以下资料优先于你已有的知识」。要求模型引用来源作答，也能提高采纳的稳定性
- 对冲突事实标注来源和时间，让模型有判断依据。过时资料的危害是双向的：它既可能被忽略，也可能赢过正确的参数知识
- 失效时先分方向再动手：是先验压过了 context（不采纳），还是坏 context 压过了先验（被带偏）？前者调显著性和指令，后者要回头修检索质量（3.3）

### 3.2 上下文越长，利用越不均匀

一个朴素的预期是「上下文越多，模型越准」。现实不是这样。模型的注意力是有限的预算：self-attention 的计算量随 token 数平方增长，token 越多，每一对之间分到的注意力越薄（Anthropic 2025 把它叫 attention budget）。这个预算会被耗尽。

**Chroma 2025 的 Context Rot 报告**在 18 个前沿模型上（含 Claude Opus 4、o3、Gemini 2.5 Pro、Qwen3-235B）验证了一件事：**模型并不均匀地使用上下文，输入越长，表现越不可靠**，即使任务简单到只是复述一个词。这里要诚实：Chroma 没有给出「在第几 K token 崩」的精确阈值，它给的是趋势。坊间流传的「标称窗口 50% 以上就该主动管理」是工程师的经验法则，不是 Chroma 的结论。

注意力分配的非均匀还有一个经典形态：lost in the middle (Liu 2023)。信息放在开头和结尾用得最好，埋在中间最差。把 gold 文档挪到 20 篇文档的中段，GPT-3.5 的多文档问答从 75.8% 掉到 53.8%，**比完全不给文档的闭卷基线 (56.1%) 还低**。答案就在上下文里，只因为位置不对，反而成了负担。这个 U 形很顽固：2026 年的理论工作 (arXiv:2603.10123) 证明它在随机权重、训练第 0 步就已存在，和位置编码无关，更像 Transformer 架构本身带来的结构性特征，而非可以靠训练修掉的 bug。有工作尝试在推理时校准这个位置偏置（Hsieh 2024），但工程上更稳的做法仍然是控制放进去什么、放在哪。

窗口从 200K 涨到 1M、2M，这个问题没有随之消失。长上下文检索类基准上，前沿模型在接近标称窗口上限时仍会显著掉点。更大的窗口给了你更多容量，没给你更均匀的利用。

**实践启发**：

- 对 RAG 结果做筛选，只留对当前决策真正有用的。语义相似不代表对推理有用
- 关键信息放头尾，别埋中间
- 长资料先压成结论加引用、按需展开，这正是 [JIT Context](../just-in-time-context/) 篇 progressive disclosure 的动机

### 3.3 噪声会主动带偏，不只是占位

上一节讲的是「太长了，用不过来」。这一节讲一个更棘手的问题：上下文里混进无关内容，比单纯变长更危险。Chroma 的一个反直觉发现：**哪怕只加 1 个干扰项 (distractor)，表现就掉到只有 needle 的基线以下**；而且逻辑连贯的干扰文本比随机打乱的更伤（18 个模型一致）。连贯的叙事更像真信号，更容易把模型的注意力从关键信息上拐走。

这意味着无关上下文会主动注入误差，而非被动占位。一个生产级佐证来自 Sourcegraph 2026：在 370 个企业级编码任务上，同一个 agent 只把 context 管线从粗放的 grep 换成精确过滤加重排序，文件召回就从 0.127 升到 0.277；**5K token 的精准检索结果，胜过 100K token 的全量 codebase 摘要**。在真实系统里，信噪比比信息量重要得多。

**实践启发**：

- 信噪比优先于信息量：宁可 5K 的精准检索，不要 100K 的全量摘要。检索管线里加过滤和重排序，通常比扩大召回更划算
- 特别警惕「连贯但无关」的材料，它比乱码更危险，因为它长得像真信号

### 3.4 推理模型：外来的示例会和内生的推理打架

R1、o-series 这类模型经过 RL 训练，会自己生成很长的内部推理链。它们内部已经有一套自我引导的机制，你再从外面塞 few-shot 示例，两套引导信号就可能冲突。From Harm to Help (Wang et al. 2025) 给了硬数字：在 AIME'25 / MATH-500 上，所有被测推理模型加示例后都掉点，**单条 demo 掉 6~16%，3-shot 最高掉 35%**。掉点的机制有两个：语义误导（目标题和示例太像，模型照抄示例的中间步骤）和策略迁移失败（提取不出抽象策略，被示例的具体形态带偏）。DeepSeek-R1 的官方建议因此直接是：用 zero-shot，描述清楚问题、指定输出格式。

注意这个失效的精确对象：失灵的是「贴几条完整解题过程让模型照抄」这一种载体。指令、检索到的事实、输出格式约束，这些上下文在推理模型上照样有效。few-shot 这个词在这代模型上需要拆开看，示例里的「答案格式」还有用，「解题过程」开始有害。

!!! tip "厂商口径：按家族分流，不要一刀切"

    OpenAI o-series 和 DeepSeek-R1 明确建议 zero-shot，别写「think step by step」；Google Gemini 2.5 的官方指南仍推荐 few-shot；Anthropic 居中，推荐 2~5 条 `<example>` 用于格式对齐。给推理模型配 prompt 之前，先查一眼它家的官方指南。

**实践启发**：

- 对推理模型默认 zero-shot：描述清楚问题、指定输出格式。不够再加示例
- 真要给示例，一条精选的 one-shot 通常好过三五条；2503.19602 报告它还能把过度反思砍掉约 90%

### 3.5 多轮与长程：误差会累积，除非你主动管理 context

前面四节的问题，在单次 prompt 里就能观察到。真实的 agent 是多轮的，多轮会引入一个共同的放大器：误差累积。借控制论的话说，信号一次性给出、没有反馈修正，叫**开环 (open-loop)**；根据输出持续调整输入，叫**闭环 (closed-loop)**。单次 prompt 天然是开环，早期拐错了弯，误差一路带到底。agent 循环给了你做闭环的机会，但闭环不会自动发生，它落到工程上就是 context 管理。

先看误差累积有多严重。Laban et al. 2025（微软加 Salesforce，ICLR 2026 Best Paper）做了一个干净的实验：把同样的信息一次性给（单轮），对比分散到多轮逐步给。结果是 **15 个模型平均掉 39%**，连 GPT-4.1、Gemini 2.5 Pro 也不能幸免。掉点的主因是可靠性崩溃：模型一旦在早期某一轮拐错了方向，后续就回不来了。真实 agent 天然是多轮的，所以这个失效在 agent 场景里几乎无处不在。

对策的第一个方向是「少即是多」。Less Context, Better Agents (2606.10209, 2026) 用 GPT-5 做主 agent、Claude Sonnet 4.5 交叉验证，在一个 50 任务的长程报销基准上：保留全部历史只有 71.0% 完成率，而**剪枝加摘要后升到 91.6%，同时 token 少 62.7%、耗时少 60.2%**。主导失效是**引用过期状态**：旧的 tool 结果描述的是已经被后续操作覆盖掉的中间状态，但模型还把它当成当前状态来决策（全历史下出现 34 次，加摘要后降到 4 次）。旧 context 并非中性冗余，它和 3.3 说的噪声一样会主动误导。Anthropic 2025 给了产品级的同向证据：context editing（自动剪掉过期的 tool 调用）单独带来 +29%，叠加 memory tool 到 +39%；在 100 轮 web search 的评测里，token 消耗砍掉 84%，并让原本会因 context 耗尽而失败的任务跑通了。

对策的第二个方向是可观测性：看不见系统状态，就谈不上反馈。落到工程上就是 eval 和 trace。把 context 当成可测试的对象，改了 prompt / skill / memory 之后用 held-out 任务跑分，而不是靠体感判断；记录失败样本，区分是信息缺失、噪声、冲突还是格式问题，对症下药。

再往外还有一层：系统结构。Stable Agentic Control (2605.03034, 2026) 把 tool-mediated agent 严格建成闭环控制系统后得到的结论是，让 agent 长期稳定运行，靠的更多是 harness 的结构（有界的动作空间、确定性工具兜底），而非 prompt 的措辞。这一层怎么设计，是下一篇 Agent Harness 的主题，这里只留一个指针。

回顾这一章的脉络：先验的墙（推力有上限）→ 注意力预算（长了用不均匀）→ 信噪比（噪声主动带偏）→ 信号打架（外来示例干扰内生推理）→ 误差累积与闭环管理（多轮 agent 的主战场）。一条线串下来，ICL 的失效已经从「prompt 怎么写」搬到了「agent 的 context 怎么管」。

最后留一个边界：闭环能压住误差累积，却压不破能力上限。ICL 能在模型预训练见过的能力范围内组合、泛化，但跨出这个范围去学一个全新的机制，至今没有证据。真正要让 agent 学会预训练里没有的东西，还得靠权重更新或 memory write-back。这也是 self-evolving 绕不开的下一步，留给下一篇。

### 3.6 速查表

| 失效 | 典型信号 | 第一反应 |
|---|---|---|
| 先验的墙（3.1） | 给了正确资料模型不采纳；或给了过时资料它照单全收 | 关键事实放头尾 + 明确优先级指令；标注来源和时间 |
| 长上下文利用不均（3.2） | 窗口越满，中段信息越像没给过 | 筛选、压缩、按需展开；关键信息别埋中间 |
| 噪声带偏（3.3） | 加了「相关资料」反而答错 | 砍召回量，加过滤和重排序；警惕连贯但无关的材料 |
| few-shot 反伤推理模型（3.4） | 加示例后推理任务掉点 | 默认 zero-shot；必要时一条精选 one-shot |
| 多轮误差累积（3.5） | 长会话后期决策质量下降、引用过期状态 | 剪枝过期 tool 结果 + 摘要；用 eval 验证 context 改动 |

---

## 4. The End

【Keli 来写。下面是可用元素。】

**结晶 insight**：

> 每段进入上下文窗口的内容，都应该被看作一次 runtime intervention。它要么帮模型识别任务、降低不确定性，要么只是在消耗注意力预算。Context Engineering 本质上是为 In-Context Learning 准备高质量的学习材料。

**连回系列**：从 Context Engineering（如何动态组装上下文）到 JIT Context（上下文如何按需加载）到 Agent Skills（程序性知识如何打包），一直有一条主线：Context is everything。这篇补上了「为什么 context 有效」这块地基。

**Self-evolving 钩子**：ICL 有一个根本局限：它不持久。这一次学到的，下个会话就没了。ICL 能在预训练见过的函数类内部组合和泛化，但跨出这个范围的真学习仍然需要梯度更新。要让它持久、让 Agent 自我进化，需要一条把当前上下文写回的回路（Memory → Skills → 下一次会话的 context），也需要权重更新的路径。这是下一篇的主题。

**个人收尾**（Keli 的风格，可以是一段思考、一个类比、一句引用）。

---

## References

🔥 代表个人更推荐阅读的。

**机制与理论:**

- [🔥 SAIL Blog: How does in-context learning work?](https://ai.stanford.edu/blog/understanding-incontext/) — Xie & Min，最好的 ICL 科普
- [Brown 2020: Language Models are Few-Shot Learners (GPT-3)](https://arxiv.org/abs/2005.14165) — ICL 一词在 LLM 语境的起源
- [Chan 2022: Data Distributional Properties Drive Emergent ICL](https://arxiv.org/abs/2205.05055) — 训练数据结构如何决定 ICL 是否出现
- [Lin & Lee 2024: Dual Operating Modes of ICL](https://arxiv.org/abs/2402.18819) — 检索 vs 学习双模式，统一 Min 和 Wei 的矛盾
- [Xie 2021: ICL as Implicit Bayesian Inference](https://arxiv.org/abs/2111.02080) — 隐式贝叶斯推断框架
- [Singh 2023: ICL Transience and Emergence](https://arxiv.org/abs/2311.08360) — ICL 在训练中可能是过渡态
- [Wurgaft 2025: In-Context Learning Strategies Emerge Rationally](https://arxiv.org/abs/2506.17859) — 损失-复杂度权衡预测 ICL↔IWL 的策略切换
- [Dong et al. 2024: A Survey on In-context Learning](https://arxiv.org/abs/2301.00234) — ICL 综述，广义 ICL 定义的来源之一
- [Jeon 2024: An Information-Theoretic Analysis of ICL](https://proceedings.mlr.press/v235/jeon24a.html) — ICML 2024，ICL 误差的信息论分解
- [B. Chan et al. 2024: Toward Understanding In-context vs. In-weight Learning](https://arxiv.org/abs/2410.23042) — ICLR 2025，将 Chan 2022 的数据条件理论化为可学习性框架
- [Samuel et al. 2024: BERTs are Generative In-Context Learners](https://arxiv.org/abs/2406.04823) — NeurIPS 2024，MLM 模型也能 ICL，训练目标与架构可分离
- [Waleffe et al. 2024: An Empirical Study of Mamba-based Language Models](https://arxiv.org/abs/2406.07887) — NVIDIA，纯 SSM 在检索类 ICL 上的短板

**示例设计与失败模式:**

- [🔥 Min 2022: Rethinking the Role of Demonstrations](https://arxiv.org/abs/2202.12837) — 随机标签的实验
- [Lu 2021: Fantastically Ordered Prompts](https://arxiv.org/abs/2104.08786) — 顺序敏感性
- [Zhao 2021: Calibrate Before Use](https://arxiv.org/abs/2102.09690) — 三种偏置 + contextual calibration
- [Wei 2023: Larger LMs do ICL differently](https://arxiv.org/abs/2303.03846) — 规模如何改变 ICL 行为
- [🔥 Liu 2023: Lost in the Middle](https://arxiv.org/abs/2307.03172) — 信息位置的 U 形效应
- [🔥 Chroma 2025: Context Rot](https://research.trychroma.com/context-rot) — 18 模型上输入越长越差
- [Hsieh et al. 2024: Found in the Middle](https://arxiv.org/abs/2406.16008) — 推理时校准位置偏置

**长上下文时代:**

- [Agarwal 2024: Many-Shot ICL](https://arxiv.org/abs/2404.11018) — few-shot 到 many-shot 的 scaling 曲线
- [Bertsch 2024: ICL with Long-Context Models](https://arxiv.org/abs/2405.00200) — many-shot 的增益来自检索

**推理模型:**

- [DeepSeek-R1 Technical Report](https://arxiv.org/abs/2501.12948) — 推理模型建议 zero-shot
- [2503.19602: Innate Reasoning is Not Enough](https://arxiv.org/abs/2503.19602) — 精选 one-shot 可以帮助推理模型减少过度思考
- [🔥 Wang et al. 2025: From Harm to Help](https://arxiv.org/abs/2509.23196) — few-shot 伤害推理模型的硬数字 + I2S 方法

**机制解释 (Appendix A 相关):**

- [Olsson et al. 2022: In-Context Learning and Induction Heads](https://transformer-circuits.pub/2022/in-context-learning-and-induction-heads/index.html) — Anthropic，induction heads 的发现
- [Bansal et al. 2023: Rethinking the Role of Scale for ICL](https://arxiv.org/abs/2212.09095) — ACL 2023，OPT-66B 上的 ICL 可解释性
- [Lieberum et al. 2023: Does Circuit Analysis Interpretability Scale?](https://arxiv.org/abs/2307.09458) — Chinchilla 70B 上的 circuit analysis
- [Crosbie & Shutova 2024: Induction Heads in Large Models](https://arxiv.org/abs/2407.07011) — 大模型上的因果消融
- [Which Attention Heads Matter 2025](https://arxiv.org/abs/2502.14010) — function-vector heads 是 few-shot 的主力
- [Hendel 2023: In-Context Learning Creates Task Vectors](https://arxiv.org/abs/2310.15916) — task vector 可提取可注入
- [Todd 2023: Function Vectors in LLMs](https://arxiv.org/abs/2310.15213) — function vector 由少量 attention heads 搬运
- [von Oswald 2022: Transformers Learn ICL by Gradient Descent](https://arxiv.org/abs/2212.07677) — 隐式梯度下降（玩具设定）
- [Yang 2025: Task Vectors 的形成与塑形（TVP-loss）](https://arxiv.org/abs/2501.09240) — 干净的 task vector 需要训练目标主动雕出来
- [Dong 2025: Task Vector 的线性组合猜想与秩限制](https://arxiv.org/abs/2506.09048) — rank-one 系数导致双射/高秩任务失灵
- [Xiong 2024: LLMs can In-Context Learn Multiple Tasks in Superposition](https://arxiv.org/abs/2410.05603) — task superposition
- [Unifying Attention Heads and Task Vectors 2025](https://arxiv.org/abs/2505.18752) — NeurIPS 2025，两阶段几何（早层 separability、晚层 alignment）把 induction heads 和 task vectors 接到一起
- [Park 2024: Can Mamba Learn How to Learn?](https://arxiv.org/abs/2402.04248) — 跨架构 ICL，SSM 弱在 retrieval，MambaFormer 混合补足

**控制论视角 (第 3 章局部借用):**

- [🔥 Bhargava & Witkowski 2024: What's the Magic Word? A Control Theory of LLM Prompting](https://arxiv.org/abs/2310.04444) — ICML 2024，prompt 作为控制信号的形式化，k-ε 可控性，97% 目标 token 在 k≤10 可达
- [Nosrati et al. 2026: When Control Meets Large Language Models](https://arxiv.org/abs/2602.03433) — plant / state / feedback 完整框架，shift-and-grow 动力学，不可达条件
- [Stable Agentic Control 2026](https://arxiv.org/abs/2605.03034) — tool-mediated LLM agent 的闭环稳定性（ISS / 可观测性，Lean 4 验证），稳定性来自 harness 结构而非 prompt

**长程 agent 与多轮失效 (2025-2026):**

- [🔥 Laban et al. 2025: LLMs Get Lost in Multi-Turn Conversation](https://arxiv.org/abs/2505.06120) — 微软 + Salesforce，ICLR 2026 Best Paper，多轮分散信息平均掉 39%，可靠性崩溃
- [🔥 Less Context, Better Agents 2026](https://arxiv.org/abs/2606.10209) — GPT-5 / Sonnet 4.5，剪枝+摘要把长程 agent 从 71.0% 提到 91.6%，stale-state 是主导失效
- [Anthropic 2025: Context editing & Memory tool](https://www.anthropic.com/news/context-management) — context editing +29%，叠加 memory +39%，100 轮 web search 省 84% token
- Sourcegraph 2026: Context Engineering Practical Guide — 370 个企业级任务上的 context 管线对照实验【链接待补，见调研笔记 `Sourcegraph 2026 - Context Engineering Practical Guide.md`】

**Post-training 与安全:**

- [Bigoulaeva et al. 2025: Instruction Tuning and ICL](https://arxiv.org/abs/2501.08716) — 90 个模型，IT 不创造新 ICL 能力
- [He & Cao 2025: SVD Analysis of Post-Training](https://arxiv.org/abs/2509.17866) — post-training 约等于 temperature 缩放

**系列前篇:**

- [Context Engineering，一篇就够了](../context-engineering/) — 上下文工程的 What / Why / How
- [Just-in-Time Context，一篇就够了](../just-in-time-context/) — Agent 主动获取上下文的范式转移
- [Agent Skills，一篇就够了](../agent-skills/) — 程序性知识如何打包为可复用 Context

---

## Appendix A. ICL 机制的四把镜头

> 正文 2.1~2.3 给出了一个工程友好的主叙事。这里展开四种学术视角，适合想深入的读者。它们是同一条 attention 通路上不同抽象刻度的互补解释，目前没有统一理论（2024~2025 两篇综述都明确确认了这一点）。

理解它们的关系：与其说是四个竞争假说，不如说是同一现象在不同放大倍率下看到的不同东西。把模型看成 `f(weights, context) -> output`，context 影响 output 的物理路径只有一条：context 的每个 token 都被编码进 residual stream，后续每个待生成 token 的 attention 都能读到这些表征，于是被它们改写 logits。四种解释只是在这条唯一的物理通路上，从不同抽象刻度去描述发生了什么。

### A.1 贝叶斯推断 / 任务定位

Xie 2021 把预训练数据建模成多个「潜在概念」(latent concept) 的混合体。ICL 的过程就是模型根据上下文推断当前属于哪个概念，然后按这个概念的规律预测输出。数学上，这是在做 `p(output|prompt) = ∫ p(output|concept,prompt) · p(concept|prompt) d_concept`，示例越多，concept 后验越尖。

Lin & Lee 2024 把这个框架做了关键升级：在高斯混合先验 + 线性函数 + squared loss 的可解设定下，ICL 对示例做两件可分离的事。一是 component re-weighting（在已有 task group 里挑一个，即检索），二是 component shifting（在选中分量内部朝示例平移中心，即学习）。示例少时检索主导，示例多时学习接管。这个闭式解在 GPT-4 上验证了 early ascent（少量示例可能检索到错技能，示例更多后学习接管性能才回升）和翻转标签有界有效性等定性预测。

局限：严格的闭式解建立在线性 + 高斯混合的玩具设定上。真实 LLM 只验证到定性形状，没有端到端复现数值后验。「检索和学习是 LLM 内部两条可分离机制」目前仍是类比，不是电路级证明。

### A.2 Induction heads：一种注意力电路

Olsson 2022（Anthropic）发现模型内部存在一种叫 induction head 的注意力电路。它的机制是一个跨层的两步接力：第一层一个 previous-token head 把位置 i 的信息搬到 i+1，第二层的 induction head 做 prefix matching + copying，合起来执行 `[A][B]...[A] → [B]`，即在上文里找到「上次出现的当前 token」，把它后面跟过的 token 抬高 logit。因为需要跨层组合，1 层模型永远长不出 induction head，这给「ICL 为什么需要深度」提供了一个干净的解释。

这种电路在训练早期突然形成（phase change），同时 ICL 能力跳升。大模型上的因果证据由 Crosbie 2024 补上：在 Llama-3-8B 上只消融 prefix-matching 分数最高的 1% heads，复制类任务从 91.3% 掉到 59.7%（接近随机），NLP few-shot 的 ICL 增益掉 63.8% 退回 zero-shot 附近；随机消融 1% 只掉不到 6%。

但 2025 年的后续工作 (Which Attention Heads Matter, ICML'25) 跨 12 个模型发现了重要转折：真正扛 few-shot 任务表现的是 function-vector (FV) heads，模型越大越明显。很多 FV heads 是从 induction heads 在训练中单向演化来的（induction 分数降、FV 分数升，反向从不发生），两类 head 集合在 7/12 模型上零重叠。

现代图景：induction heads 是必要底座和早期种子，FV heads 是更晚成熟、承载任务语义的主力。Crosbie 的「敲了就塌」和 Which-Heads 的「FV 才是主力」并不矛盾：Crosbie 的复制任务正是 induction heads 的主场，两类 heads 在不同任务维度各司其职。

### A.3 隐式梯度下降（玩具设定）

von Oswald 2022 等人发现，在线性回归玩具设定下，训练好的 Transformer 的前向传播看起来像在上下文样本上做了一步梯度下降。一层 linear self-attention 等价于对内部隐式线性模型做一步 GD，多层约等于多步。Akyurek 等人把它扩展到 ridge regression 和闭式最小二乘。

这个结果在数学上很漂亮，但边界条件最硬：几乎全部结论都在线性注意力、去掉 softmax、专门按 ICL 目标从头训练的合成设定里成立。两篇 2024~2025 综述都给保守结论：这是强假设下的数学等价，大模型表现更像直接逼近闭式解，而非真的一步步跑 GD。反方 (Deutch 2023, Shen 2023) 在 LLaMA-7B 上发现 ICL 与 GD 对 demo 顺序的敏感性、改写输出分布的方式都不同。2025 年 Google 团队 (Dherin, Goldwaser) 把 context-parameter 等价推广到 Gemma-style 现代架构，但仍是 per-token 的 rank-1 patch，compositional regime 缺分析；Xie 2025 证明非 zero-mean 权重下多头 linear attention 无法复现 one-step GD。

所以这条更像有启发性的类比，不宜写成「LLM 内部就是在跑 SGD」。

### A.4 Task vectors / Function vectors

Hendel 2023 和 Todd 2023 几乎同时、各自独立地发现：ICL 可以把整组示例压缩成模型中间层的一个向量。把这个向量从一次 ICL 前向传播里抽出来，patch 进一次没有看过任何示例的零示例前向传播，模型就能执行那个任务。Todd 进一步定位到这个向量由约十个量级的 attention heads 搬运，且能迁移到和原 prompt 完全不像的自然文本。

后续工作揭示了边界：Dong 2025 的 Linear Combination Conjecture 说一个 task vector 约等于把 N 个示例按某组权重线性叠成的一个虚拟示例。因为系数矩阵是 rank-one，它无法表示高秩映射。典型反例是双射任务（大小写互转、英法互译）：Llama-7B 上单向量注入掉到 uppercase 约 55%、英法约 35%，而标准 ICL 是 54~92%。Yang 2025 还指出干净的 task vector 不是模型自带的赠品，默认弱且弥散，需要训练目标 (TVP-loss) 主动塑形。

另一面是 task superposition (Xiong 2024)：模型可以在一次前向传播里同时持有多个 task vector，按上下文比例分配。

### A.5 为什么不必押注唯一理论

这四种解释不互相排斥，更像是不同放大倍率下看到的不同东西：

| 抽象层级 | 解释 | 回答的问题 |
|---|---|---|
| 最高层 | 贝叶斯 / 双模式 | ICL 在做什么（定位或学习一个任务） |
| 中间层 | Task vectors | ICL 的产物长什么样（一个可搬运的方向） |
| 最低层 | Induction heads / FV heads | 前向传播里什么电路在搬运信息 |
| 算法层 | 隐式梯度下降 | 前向传播在执行什么数值运算（玩具设定下） |

2025 年开始有把这些镜头拼起来的尝试。Unifying Attention Heads and Task Vectors (2505.18752, NeurIPS 2025) 发现 ICL 在分类任务上是一个两阶段过程：早层由 previous-token heads 制造可分性 (separability)，晚层由 induction heads 和 task vectors 制造对齐 (alignment)，把 A.2 和 A.4 接到了一起。不过统一理论仍未完成。

还有一把这里没单列的镜头：控制论（正文 3.1 和 3.5 借用了它的词汇）。它和上面四把不一样，它不打开黑箱，只描述「context 这个控制信号如何驱动模型、何时驱动失败」。机制四镜头回答「模型为什么响应」，控制论回答「响应的行为规律和边界在哪」，两者互补。

对工程实践而言，知道「上下文通过多种机制改变模型的行为分布，且这个改变是有损的、有限的」就够了。正文第 3 章的所有结论，对这四种理论都成立。

---

## Appendix B. 长上下文时代的 ICL

> 正文 3.2 和 3.3 讲了长上下文的风险面。这里补充积极面：长上下文窗口打开后，ICL 的 scaling 曲线是什么样？

### B.1 Many-shot ICL：从几个示例到上千个

Agarwal 2024 用 Gemini 1.5 Pro（100 万 token 窗口）做了系统测试：从几个示例一路加到上千个，在大多数任务上看到了持续增益。

两个有意思的发现：

**可以不需要人写答案**：用模型自己生成的推理过程（按正确性筛选）替换人写的，效果一样好甚至更好 (Reinforced ICL，BBH 上 83% vs 人工 3-shot CoT 的 72.1%)。甚至只给题不给答案，在一些推理任务上也能工作 (Unsupervised ICL，77.1%)。

**增益并非处处单调**：有些任务在几十个示例时就见顶，再加反而掉。XSum 约 50-shot 见顶后退化，MATH 约 125-shot 见顶后回落。所以不是「越多越好」，而是存在一个任务相关的最优 shot 数。NLL/perplexity 也不是 ICL 收益的可靠代理指标 (Agarwal 2024)。

### B.2 增益的来源：检索，不是逐例学习

Bertsch 2024 深入挖了 many-shot 增益的机制：大部分增益来自「有更多示例可以检索到相关的」，而不是「模型从每个示例里都学到了一点」。

证据：用 block attention（只看邻近 50~75 个示例）就能恢复全注意力 95% 的效果；按标签排序（打破检索多样性）掉 25.7 点；随着 shot 数增加，精选示例 vs 随机示例的优势从 +51.5 缩到 +4.9。

这也呼应 3.2：即便进入 many-shot，注意力预算仍是天花板。堆到覆盖任务所需之后，多出来的示例更多是在稀释注意力，而不是继续教模型。many-shot 不是绕过长上下文限制的捷径，它自己就活在那个限制里。

这意味着：在长上下文时代，示例选择的重要性被稀释了（量大可以弥补质的差距），但对上下文组织的要求反而更高了（3.2 说的注意力分配不均匀和长度退化不会因为示例多就消失）。
