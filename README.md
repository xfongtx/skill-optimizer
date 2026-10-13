<sub>🌐 <b>English</b> · <a href="README.zh-CN.md">中文</a></sub>

<div align="center">

# skill-optimizer

> *Every rule that stays can say why it is there. Every rule that goes has a recorded destination.*

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-skill--optimizer-blueviolet)](skills/skill-optimizer/SKILL.md)
[![skills.sh](https://skills.sh/b/xfongtx/skill-optimizer)](https://skills.sh/xfongtx/skill-optimizer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Calibrates an agent skill that already works: removes piled-up rules, contradictions and old-model hand-holding, and keeps the environment facts and the rules you locked.**

[Example](#example-calibrating-luban) · [Install](#install) · [How it works](#how-it-works) · [How it differs](#how-it-differs) · [Boundaries](#boundaries)

</div>

---

## The problem

Your skill worked. Then it failed once, and you added a "MUST". Then it failed differently, and you added another. Each rule was reasonable. Six months later the skill is a form the model fills in: it restates your request, prints a self-check table nobody reads, and two sections give opposite defaults for the same thing.

Newer models make this worse, not better. A gate that helped last year's model ("read every file first", "report after each step") now only costs tokens and pulls a strong model toward stopping early.

Asking an agent to "make this skill shorter" deletes the wrong things — including the one rule that exists because of a production incident. skill-optimizer does not start by cutting. It starts by asking where each rule came from.

> The skill itself is written in Chinese. Agents run it fine in any language; this README is the English entry point.

## Example: calibrating luban

[examples/luban/](examples/luban/) is a full, real calibration of [LearnPrompt/luban-skill](https://github.com/LearnPrompt/luban-skill) (MIT, pinned at `cea2da3`), a skill that polishes other skills for public release.

| | Before | After |
|---|---|---|
| `SKILL.md` lines | 511 | 427 |
| Description (paid in every session) | ~389 tokens | ~117 tokens |
| Hard wording (MUST / never / forbidden) | 24 | 16 |

What was kept matters as much as what was cut. The weighted scoring table, the 13-section report, the "graduation certificate" card and the stop-before-merge gates are the skill's advertised deliverables and safety gates, so they were left word for word. The rules that came from a real incident (a background job that deleted unpushed commits) were moved to a failure-fix table, not deleted.

Every removed sentence has a row in the [ledger](examples/luban/ledger.md) saying where it went. Lint output before and after: [lint-before.txt](examples/luban/lint-before.txt), [lint-after.txt](examples/luban/lint-after.txt).

## Install

```bash
npx skills add xfongtx/skill-optimizer
```

Or copy `skills/skill-optimizer/` into your agent's skills directory (for Claude Code: `~/.claude/skills/`).

Then tell your agent:

```text
Use skill-optimizer to check up ~/.claude/skills/<your-skill>
```

Requirements: `bash` and `python3` for the lint script. No API keys, no network calls.

## How it works

1. **Check-up.** `scripts/skill-lint.sh <skill-dir> [skills-library-dir]` prints candidates: hard-wording density, history residue, parallel numbering, broken links, orphan files, conflicting defaults, output-contract lines, the description's token cost ranked against your whole library, and trigger phrases that overlap with other skills. If everything is clean, the answer is "don't cut".
2. **Triage** by load frequency (always loaded, main path, on demand) × material (derivable, contingent fact, human discretion).
3. **Origin before cutting.** Each sentence to cut is classed as pile-up, incident guard, or deliberate lock — via git log, then by asking you. Unknown origins are treated as guards.
4. **Surgery** in order of payoff: output reduced to the deliverable, one definition per fact, pointers that say when to read, three tiers (required / on demand / failure fixes), trust the model's priors, sharp completion criteria.
5. **Ledger.** Every removed sentence gets a destination, reconciled against a diff. You verify in a real conversation with one prompt and a concrete pass criterion.

For skills that write prompts for image, video or audio models, it also distills the generation model's "laws" so new failures revise a law instead of adding a rule.

## How it differs

| | Typical skill audit | skill-optimizer |
|---|---|---|
| Goal | Score against a checklist, or cut tokens | Each rule can justify itself; shorter is a side effect |
| Before deleting | — | Origin list: pile-up, incident guard, or lock |
| After deleting | — | Destination ledger reconciled with a diff |
| Scope of the token check | One skill | The description tax and trigger overlap across your whole library |
| Verification | Evals or subagent A/B runs | You, in a real conversation, with a concrete pass criterion |

Related work worth knowing: [rarestg/skill-review](https://www.skills.sh/rarestg/rarestg-skills/skill-review) (also biased toward leaving things alone), [uinaf/skill-audit](https://tessl.io/registry/uinaf/skill-audit/files), [workleap-skill-optimizer](https://skills.cat/skills/workleap/wl-web-configs/workleap-skill-optimizer) (token cost), and Matt Pocock's [writing-for-agents](https://github.com/mattpocock/skills).

## Boundaries

- The lint script is read-only.
- It edits only the skill you point it at, and asks you before deleting any rule whose origin git cannot explain.
- It never runs evals and never spawns subagents.
- It does not touch rules about irreversible, paid or external actions; those gates stay.
- It does not decide your preferences (how many variants, which material). Those belong to you, not to the skill.

## Files

```
skills/skill-optimizer/
├── SKILL.md                    # the process and the symptom table (always loaded)
├── references/
│   ├── toolkit.md              # how to read the lint, origin list and ledger shapes
│   ├── execution-model.md      # distilling laws for image / video / audio models
│   └── casebook.md             # mistakes calibrators repeat; read before the first cut
└── scripts/skill-lint.sh       # read-only check-up (SKILL_LINT_LANG=en for English output)
examples/luban/                 # a full calibration with ledger and lint output
```

## Credits

The pointer-wording and completion-criteria checks were adapted from Matt Pocock's [writing-for-agents](https://github.com/mattpocock/skills). The luban example uses [LearnPrompt/luban-skill](https://github.com/LearnPrompt/luban-skill) under its MIT license.

## License

[MIT](LICENSE)
