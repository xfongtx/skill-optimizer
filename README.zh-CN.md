<sub>🌐 <a href="README.md">English</a> · <b>中文</b></sub>

<div align="center">

# skill-optimizer

> *留下的每条规则都说得出为什么在，删掉的每条规则都记下去了哪里。*

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-skill--optimizer-blueviolet)](skills/skill-optimizer/SKILL.md)
[![skills.sh](https://img.shields.io/badge/skills.sh-npx%20skills%20add-black)](#安装)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**校准一个已经能用的 agent skill：删掉堆积的规则、自相矛盾和给旧模型的搀扶，保住环境事实和你锁定的规则。**

[看案例](#案例校准-luban) · [安装](#安装) · [怎么工作](#怎么工作) · [和同类的区别](#和同类的区别) · [边界](#边界)

</div>

---

## 它解决什么问题

你的 skill 本来好用。后来翻车一次，你加了一条"必须"；又翻车一次，再加一条。每条都有道理。半年后它成了一张表格：模型先复述你的需求，再打一张没人看的自检表，两个章节对同一件事给出相反的默认值。

模型越新，这个问题越重。去年帮得上忙的门槛（"先读完所有文件""每步汇报"），对今天的强模型只剩成本，还会让它提前收工。

直接让 agent "把这个 skill 改短"，删掉的往往是错的那条，比如某次线上事故后才加的规则。skill-optimizer 不先动刀，先问每条规则是从哪来的。

## 案例：校准 luban

[examples/luban/](examples/luban/) 是对 [LearnPrompt/luban-skill](https://github.com/LearnPrompt/luban-skill)（MIT，固定在 `cea2da3`）的一次完整校准。

| | 改前 | 改后 |
|---|---|---|
| `SKILL.md` 行数 | 511 | 427 |
| description（每个会话都付费） | ~389 token | ~117 token |
| 硬性措辞（必须／绝不／禁止） | 24 | 16 |

留下什么和删掉什么一样重要。九维评分表、13 节报告、出师证书、merge 前的停手点，是它宣传的交付物和安全门，一字没动。来自真实事故的规则（后台任务删掉了未推送的提交）挪进了失败修法表，没有删。

每条删掉的句子在[账本](examples/luban/ledger.md)里都有一行，写明去了哪里。改前改后的 lint 输出：[lint-before.txt](examples/luban/lint-before.txt)、[lint-after.txt](examples/luban/lint-after.txt)。

## 安装

```bash
npx skills add xfongtx/skill-optimizer
```

也可以把 `skills/skill-optimizer/` 复制进你的 agent 的 skills 目录（Claude Code 是 `~/.claude/skills/`）。

装好后对 agent 说：

```text
用 skill-optimizer 体检一下 ~/.claude/skills/<你的 skill>
```

依赖：lint 脚本需要 `bash` 和 `python3`。不需要 API key，不联网。

## 怎么工作

1. **体检。** `scripts/skill-lint.sh <skill 目录> [skill 库目录]` 列出候选：硬性措辞密度、历史残留、并行编号、失效链接、孤儿文件、相反的默认值、输出契约行、description 的 token 开销在整个库里的排名、和其他 skill 重叠的触发词。全部干净，结论就是"不动刀"。
2. **分诊。** 按加载频率（常驻／主路径／按需）和材质（可推导／偶然事实／人的裁量）分类。
3. **先定出身再动刀。** 每条拟删的句子先判定是堆积、事故守卫还是有意锁定：先查 git log，再问你；查不到的按守卫处理。
4. **手术**，按收益排序：输出只留交付物、每个事实只有一个出处、指针写明什么时候读、三层分置（必备／按需／失败修法）、信任模型先验、磨尖完成判据。
5. **记账。** 每条删掉的句子写明去处，用 diff 对账。验证交给你：一条提示词加一个具体的通过标准，在真实对话里跑。

如果 skill 是给图像、视频、音频模型写提示词的，它还会提炼生成模型的"定律"，让新的翻车去修订定律，而不是再加一条规则。

## 和同类的区别

| | 常见的 skill 审计 | skill-optimizer |
|---|---|---|
| 目标 | 按清单打分，或者减 token | 每条规则说得出理由；变短是结果 |
| 删之前 | — | 出身清单：堆积、事故守卫还是锁定 |
| 删之后 | — | 去向账，用 diff 对账 |
| token 检查范围 | 单个 skill | 整个库的 description 开销和触发词重叠 |
| 验证 | 跑评测或子代理 A/B | 你在真实对话里验证，有具体的通过标准 |

值得一看的同类：[rarestg/skill-review](https://www.skills.sh/rarestg/rarestg-skills/skill-review)（同样倾向"能不动就不动"）、[uinaf/skill-audit](https://tessl.io/registry/uinaf/skill-audit/files)、[workleap-skill-optimizer](https://skills.cat/skills/workleap/wl-web-configs/workleap-skill-optimizer)（看 token 开销）、Matt Pocock 的 [writing-for-agents](https://github.com/mattpocock/skills)。

## 边界

- lint 脚本只读。
- 只改你指定的 skill；git 说不清来历的规则，删之前先问你。
- 不跑评测，不起子代理。
- 不碰不可逆、花钱、对外动作的门槛，这些门保留。
- 不替你做偏好判断（生成几条、挑哪个素材），那是你的事，不是 skill 的事。

## 文件结构

```
skills/skill-optimizer/
├── SKILL.md                    # 流程和症状表（常驻）
├── references/
│   ├── toolkit.md              # 怎么读 lint，出身清单和去向账的格式
│   ├── execution-model.md      # 给图像／视频／音频模型提炼定律
│   └── casebook.md             # 改造者总会重犯的错，动第一刀前读
└── scripts/skill-lint.sh       # 只读体检（SKILL_LINT_LANG=en 输出英文）
examples/luban/                 # 一次完整校准，含账本和 lint 输出
```

## 致谢

指针措辞和完成判据两项检查参考了 Matt Pocock 的 [writing-for-agents](https://github.com/mattpocock/skills)。luban 案例按 MIT 许可使用 [LearnPrompt/luban-skill](https://github.com/LearnPrompt/luban-skill)。

## License

[MIT](LICENSE)
