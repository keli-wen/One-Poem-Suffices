---
hide:
  - toc
---

# Zen of Harness Engineering

曾经是氛围编程之禅。当 AI Coding 的本质变成设计约束让 Agent 干活，记录 Harness Engineering 的实战心得。

---

### :material-lightbulb-outline: [引子与问题划分](./intro/)

> *"Project-Level 的问题需要人主动思考与做细致的规划，拆解为多个 Feature-Level 问题。"*

系列开篇，从 Vibe Coding 的常见困境出发，提出 Project-Level 与 Feature-Level 的问题划分框架。

:octicons-clock-24: 5 min &nbsp; [:octicons-arrow-right-24: 阅读全文](./intro/)

---

### :material-rocket-launch: [最佳实践 I](./best-practice-1/)

> *"AI Coding 的 bottleneck 不在于模型，而是人类的 guidance 是否完善。"*

分享从零开始 AI Coding 的实践：维护 Tech Context 构建技术复利、Talk to Design Docs 的自然语言编程范式、以及 Codex 与 Claude Code 的对比与协同。

:octicons-clock-24: 15 min &nbsp; [:octicons-arrow-right-24: 阅读全文](./best-practice-1/)

---

### :material-flask-outline: [Claude Code 源码蒸馏 - Harness Engineering 实践记录](./claudecode-distillation-practice/)

> *"代码是高维的，但有价值的设计模式其实是低秩的，蒸馏的本质就是找到这些主成分。"*

从 51.2 万行 Claude Code 源码中蒸馏设计模式的完整实践记录：多 Agent 协作架构（Codex 审查 + Claude 执行）、品味注入的 PCA 类比、以及 7 轮 review 收敛的过程复盘。

:octicons-clock-24: 25 min &nbsp; [:octicons-arrow-right-24: 阅读全文](./claudecode-distillation-practice/)

---

### :material-magnify: [为什么 Codex 总在自动压缩？](./why-codex-compacts/)

> *"同一个模型放进不同的 harness，行为/性能可以相差甚远。"*

同一个问题、同一个 GPT-5.5，Codex 反复触发自动压缩，Claude Code 全程平走。从 trajectory 和源码两个角度拆解原因：过泛的搜索与截断、渐进式披露 vs 事后止损、以及子 agent 隔离如何让主 context 峰值从 241k 降到 93k。

:octicons-clock-24: 18 min &nbsp; [:octicons-arrow-right-24: 阅读全文](./why-codex-compacts/)

---

### :material-comment-question-outline: [如何看待 grill-me（拷问我）这个 Skill？](./why-grill-me/)

> *"在 Agent 行动得越来越快时，人应该如何继续对方向负责。"*

从一个轻量的追问 Skill 出发，讨论 Taste Injection、执行过程中的不确定性，以及 Shared Context Folder、Issue / PR 和设计追问组成的三层控制体系。

:octicons-clock-24: 9 min &nbsp; [:octicons-arrow-right-24: 阅读全文](./why-grill-me/)
