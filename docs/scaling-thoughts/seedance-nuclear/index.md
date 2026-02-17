# Scaling 一下：Seedance 2.0 的核扩散

> 原文发布于 [知乎想法](https://www.zhihu.com/pin/2004895294354105919)，2026-02-11

总注意力预算有限，"智力/创意" 供给过剩其实利好的是平台和极少部分超级个体。不过这算是社会学实验了，其实目前 seedance 2.0 的效果之于视频应该还弱于顶级 coding agent 之于软件开发，但是 coding agent 很难直观的给人冲击，而且不同人无法同时理解某个任务的复杂性和 coding agent 的强悍之处，需要大量的理解成本和前置条件。

## AIGC 的直观冲击

AIGC 则不同，并且视频是集文本/图像/音频与一体的，对（普通）人带来的冲击最大。因此，很多人会直观的，赤裸裸的感受到 AI 的指数发展，在此之前绝大部分人的理解可能还停留在"远古时期"。就像把古代人突然丢到现代一样，seedance 2.0 就像核扩散，甚至会让一部分人觉得"虚无"。

分享我觉得挺离谱的感受，我对于 opus 4.5/4.6 其实没有太多感觉，它的能力已经溢出了我绝大部分的需求。现在这情况，我自己越想越混沌。

## AI E2E 工作流

!!! note "暴论预测"
    我觉得你必须进行比暴论还暴论的预测，否则它可能短时间内被实现。

如果 seedance 2.0 能做到这个程度，那么 AI E2E 的视频生成完全可能，就用 claude code 举例子，让他收集爆款视频丢给 gemini 理解，然后生成多个稿子，批量生成视频脚本，利用 seedance 2.0 的生成并拼接最后上传到视频平台再利用数据库 tracking 流量做 verify 和学习。在不考虑 token 成本的情况下我觉得可以做到了？或者说比相当一部分普通人做的会好。（而且可以预期的是 token 会越来越便宜）

!!! tip "角色转变"
    你必须从执行者变成"管理""决策者"，否则 AI 会吞噬你绝大部分价值。因此你必须要当 founder，无论是个人还是团队。其实一直以来，个人投资都算自己当 founder，你的员工是 money / fund / stock。

如果能 verify 那么 agent 就"应该"能自我迭代？有人有尝试构建一个很 agent-native 的 backtesting 系统吗？基于此，然后让 claude code 不断写一些策略去回测优化，哈哈哈 非常 trivial 的想法～ 我知道这个 idea 一定有很多角度被 challenge 直到它真的 work 了。

## 关于读书与 AI

今天和我师兄聊天，我说我最近读书总感觉太慢了，因为有 AI 做什么事情都希望效率++，但是 AI 总结读书是有损压缩，可能还是得"古法读书"，但是那样就太慢了。所以我悲观的说 "这就是为什么人类一定会输给 AI 吧，我连读书的速度永远追不上它们" 或者期待下脑机接口吧？

目前只能是尽量避免干扰的情况下，多阅读前沿的牛人分享，顶级公司的 Engineering Blog，一些播客访谈，书。

## 阅读推荐

- **Principal 原则** — 重读一遍，觉得有了 AI 后，里面很多思路对 AI-Native 的工作流很有价值，有些 rules 可以让 AI 作为监督者完成。
- [**Inside OpenAI's in-house data agent**](https://openai.com/index/inside-our-in-house-data-agent/) — 顶级公司分享内部的 agent 构建细节，太有价值了。
- [**The Bitter Lesson**](http://www.incompleteideas.net/IncIdeas/BitterLesson.html) — 对于构建 agent，乃至中长期个人发展的思考都很有价值。

一些思路在 [Scaling 一下：当 Token 成为新的生产资料](https://zhuanlan.zhihu.com/p/1995936809184683260) 中简单提过～ 欢迎交流分享！
