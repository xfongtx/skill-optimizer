#!/usr/bin/env bash
# skill-lint.sh —— 只读体检。给一个 skill 目录打印可机检的症状，不改任何文件。
# Read-only lint. Prints machine-checkable symptoms for one skill directory; never edits files.
# 用法 / usage: skill-lint.sh <skill-dir> [skills-library-dir]
#   skills-library-dir 默认是 <skill-dir> 的父目录（description 常驻税与跨 skill 重叠两节用它）。
#   Defaults to the parent of <skill-dir>; used by the description-tax and cross-skill-overlap sections.
# 输出语言 / output language: SKILL_LINT_LANG=zh|en
# 每一节输出都是"候选"，不是结论：机器只负责把该看的行捞出来，判断留给读的人。
set -uo pipefail
export LC_ALL=en_US.UTF-8 2>/dev/null || true
LINT_LANG="${SKILL_LINT_LANG:-zh}"

L() { if [ "$LINT_LANG" = "en" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

dir="${1:?usage: skill-lint.sh <skill-dir> [skills-library-dir]}"
dir="${dir%/}"
[ -f "$dir/SKILL.md" ] || { echo "$(L '找不到' 'not found:') $dir/SKILL.md"; exit 1; }
lib="${2:-$(cd "$dir/.." && pwd)}"

section() { printf '\n== %s ==\n' "$1"; }
show() { if [ -z "$1" ]; then echo "  $(L 无 none)"; else printf '%s\n' "$1"; fi; }
md_files() { find "$dir" -type f -name '*.md' ! -path '*/.git/*' ! -path '*/node_modules/*' -print0; }

section "$(L '体量（常驻 SKILL.md 先看；其余按行数排，大的先问：常驻还是命中才读）' 'Size (SKILL.md is always loaded; for the rest, biggest first, ask: always read or read on demand?)')"
printf '  %5s  SKILL.md%s\n' "$(wc -l < "$dir/SKILL.md" | tr -d ' ')" "$(L '（常驻）' ' (always loaded)')"
out=$(find "$dir" -type f ! -name 'SKILL.md' ! -name '.DS_Store' ! -path '*/.git/*' ! -path '*/node_modules/*' \
        \( -name '*.md' -o -name '*.txt' -o -name '*.json' -o -name '*.yaml' -o -name '*.yml' -o -name '*.sh' -o -name '*.py' \) -print0 \
      | xargs -0 wc -l 2>/dev/null | grep -v ' total$' | sort -rn | head -15 | sed "s#$dir/#  #")
show "$out"

section "$(L '硬性措辞密度（必须／一律／不可／绝不／禁止／永远／MUST／NEVER／ALWAYS）—— 数量不是病，每一条问出身' 'Hard-wording density (MUST / NEVER / ALWAYS / CRITICAL / 必须 / 绝不) — the count is not the disease; ask each one where it came from')"
out=$(grep -rEc --exclude-dir=node_modules '必须|一律|不可|绝不|禁止|永远|一个字|MUST|NEVER|ALWAYS|CRITICAL|IMPORTANT|[Uu]nder no circumstances' "$dir" --include='*.md' 2>/dev/null \
      | awk -F: '$NF>0{n=$NF; sub(/:[0-9]+$/,"",$0); printf "  %4d  %s\n", n, $0}' | sort -rn | sed "s#$dir/##")
show "$out"

section "$(L '历史残留候选（已移除／不再／旧版已／原来是／改成了／已废弃）—— 文档只描述现状' 'History residue (removed / no longer / previously / deprecated / used to) — docs describe the present only')"
out=$(grep -rniE --exclude-dir=node_modules '已移除|已删除|已废弃|已弃用|不再依赖|不再使用|不再需要|旧版[^，。；]{0,8}已|原来是|以前是|改成了|之前的版本|has been removed|no longer|previously|deprecated|used to be|old version' "$dir" --include='*.md' 2>/dev/null | sed "s#$dir/#  #")
show "$out"

section "$(L '并行编号候选（U1／D3／C4 式前缀编号，同前缀 ≥3 个）—— 掩盖了本可由定律推出的规则' 'Parallel numbering (U1 / D3 / C4 style IDs, ≥3 with the same prefix) — often hides rules a single law could derive')"
out=$(grep -rhoE --exclude-dir=node_modules '(^|[^A-Za-z])[A-Z][0-9]{1,2}([^0-9A-Za-z]|$)' "$dir" --include='*.md' 2>/dev/null \
      | grep -oE '[A-Z][0-9]{1,2}' | sort -u \
      | awk '{p=substr($0,1,1); c[p]++; l[p]=l[p]" "$0} END{for(k in c) if(c[k]>=3) printf "  %s:%s\n", k, l[k]}')
show "$out"

section "$(L '失效的相对链接（指向不存在的文件）' 'Broken relative links (point to files that do not exist)')"
out=$(md_files | while IFS= read -r -d '' f; do
        base=$(dirname "$f")
        grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\((.*)\)$/\1/; s/#.*$//; s/[[:space:]].*$//' \
        | grep -vE '^(https?:|mailto:|$)' | sort -u | while IFS= read -r p; do
            [ -e "$base/$p" ] || [ -e "$dir/$p" ] || echo "  ${f#$dir/} → $p"
          done
      done)
show "$out"

section "$(L '孤儿文件候选（目录内零引用；已跳过 evals／assets／agents／eval-viewer／LICENSE 等由脚本或 harness 消费的约定路径）—— 仍需排除：frontmatter 直接加载、别的 skill 按名编排、外部记忆指针' 'Orphan candidates (zero references inside the skill; evals / assets / agents / eval-viewer / LICENSE skipped) — still rule out: frontmatter loading, other skills calling it by name, external memory pointers')"
out=$(find "$dir" -type f ! -name 'SKILL.md' ! -name '.DS_Store' ! -name 'LICENSE*' ! -name '__init__.py' \
        ! -path '*/.git/*' ! -path '*/__pycache__/*' ! -path '*/node_modules/*' ! -path '*/evals/*' ! -path '*/assets/*' ! -path '*/agents/*' ! -path '*/eval-viewer/*' -print0 \
      | while IFS= read -r -d '' f; do
          b=$(basename "$f"); stem="${b%.*}"
          grep -rqF "$b" "$dir" --include='*.md' --include='*.py' --include='*.sh' --include='*.html' --include='*.json' --include='*.yaml' --include='*.yml' --exclude="$b" 2>/dev/null \
            || grep -rqE "(^|[^A-Za-z0-9_])${stem}([^A-Za-z0-9_]|$)" "$dir" --include='*.md' --include='*.py' --include='*.sh' --include='*.html' --exclude="$b" 2>/dev/null \
            || echo "  ${f#$dir/}"
        done)
show "$out"

section "$(L 'frontmatter description（常驻程度最高的一行）—— 按分支过，见 SKILL.md「指针先于内联」' 'Frontmatter description (the most always-loaded text there is) — review branch by branch, see SKILL.md "Pointers before inlining"')"
desc=$(python3 - "$dir/SKILL.md" <<'PY'
import sys, re
s = open(sys.argv[1], encoding='utf-8', errors='ignore').read()
m = re.search(r'\A---\s*\n(.*?)\n---', s, re.S)
fm = m.group(1) if m else ''
m2 = re.search(r'^description:\s*(.*?)(?=^\w[\w-]*:|\Z)', fm, re.S | re.M)
d = m2.group(1) if m2 else ''
d = re.sub(r'^[|>][-+]?\s*', '', d.strip())
print(re.sub(r'\s+', ' ', d).strip().strip('"').strip("'"))
PY
)
if [ -z "$desc" ]; then echo "  $(L 无 none)"; else
  printf '  %s %s\n  %s\n' "$(printf '%s' "$desc" | wc -m | tr -d ' ')" "$(L 字 chars)" "$desc"
fi

section "$(L '指针行（markdown 链接或反引号里的文件名，连同所在行）—— 逐行问：写没写什么情况下读；只有「另见」的，目标文件基本没人读' 'Pointer lines (markdown links or backticked file names, with their line) — ask each: does it say when to read? A bare "see X" is rarely followed')"
out=$(md_files | while IFS= read -r -d '' f; do
        grep -nE '\]\([^)]+\.(md|py|sh|html|json|yaml|yml|txt)\)|`[A-Za-z0-9_./-]+\.(md|py|sh|html|json|yaml|yml|txt)`' "$f" 2>/dev/null | cut -c1-160 | sed "s#^#  ${f#$dir/}:#"
      done)
show "$out"

section "$(L 'SKILL.md 里的步骤起始行 —— 顺着读到句尾，问：agent 能不能判断这一步做完了' 'Step openings in SKILL.md — read each to the end of its sentence and ask: can the agent tell this step is done?')"
out=$(grep -nE '^[[:space:]]*(#+[[:space:]]*)?(\*\*)?(第?[0-9一二三四五六七八九十]+[.、．）)：:]|第[一二三四五六七八九十]+步|Step[[:space:]]*[0-9]+)' "$dir/SKILL.md" 2>/dev/null | cut -c1-160 | sed 's#^#  #')
show "$out"

section "$(L '所有含「默认」的行（人工比对：有没有两处对同一件事给出相反默认）' 'Every line that sets a default (compare by hand: do two places give opposite defaults for the same thing?)')"
out=$(grep -rniE --exclude-dir=node_modules '默认|by default|defaults? to' "$dir" --include='*.md' 2>/dev/null | cut -c1-220 | sed "s#$dir/#  #")
show "$out"

section "$(L '委托句候选（由你决定／可以是 A 或 B／视情况／酌情）—— 写给读 skill 的推理模型是留白，写进给生成模型的产出是病' 'Delegating phrases (up to you / either A or B / as appropriate) — fine as latitude for the reasoning model reading the skill; a defect inside output meant for a generation model')"
out=$(grep -rniE --exclude-dir=node_modules '由你决定|由模型决定|可以是[^，。；]{1,12}或|视情况|酌情|任选|自行决定|up to you|as appropriate|at your discretion|whichever you prefer' "$dir" --include='*.md' 2>/dev/null | cut -c1-220 | sed "s#$dir/#  #")
show "$out"

section "$(L 'SKILL.md 里的输出契约行（输出／交付／附上／必须包含／自检／决策记录）—— 最常见的真实收益点：这一行要求的是交付物本体吗' 'Output-contract lines in SKILL.md (output / deliver / include / self-check / decision log) — the most common real win: is this line asking for the deliverable itself?')"
out=$(grep -niE '输出|交付|附上|必须包含|自检|决策记录|复述|备选|output|deliver|must include|self-check|checklist|decision log|restate|summary of' "$dir/SKILL.md" 2>/dev/null | head -40 | cut -c1-220 | sed 's#^#  #')
show "$out"

section "$(L 'description 常驻税（全库范围：估算 token、排名、合计）—— 每个会话都付，单个 skill 的体检看不见' 'Description tax (whole library: estimated tokens, rank, total) — every session pays it; a single-skill check cannot see it')"
python3 - "$dir" "$lib" "$LINT_LANG" <<'PY'
import sys, re, glob, os
d, lib, lang = sys.argv[1], sys.argv[2], sys.argv[3]
def desc(path):
    s = open(path, encoding='utf-8', errors='ignore').read()
    m = re.search(r'\A---\s*\n(.*?)\n---', s, re.S)
    if not m: return ''
    fm = m.group(1)
    m2 = re.search(r'^description:\s*(.*?)(?=^\w[\w-]*:|\Z)', fm, re.S | re.M)
    return re.sub(r'\s+', ' ', m2.group(1)).strip() if m2 else ''
def tok(t):
    cjk = len(re.findall(r'[一-鿿]', t)); return int(cjk / 1.3 + (len(t) - cjk) / 4)
rows = []
for f in glob.glob(os.path.join(lib, '*', 'SKILL.md')):
    rows.append((tok(desc(f)), os.path.basename(os.path.dirname(f))))
rows.sort(reverse=True)
me = os.path.basename(os.path.abspath(d)); mine = desc(os.path.join(d, 'SKILL.md'))
rank = next((i + 1 for i, (_, n) in enumerate(rows) if n == me), None)
total = sum(t for t, _ in rows)
shown = os.path.relpath(lib) if not os.path.relpath(lib).startswith('..') else lib.replace(os.path.expanduser('~'), '~', 1)
top = (", " if lang == 'en' else "，").join(f"{n} ~{t}" for t, n in rows[:5])
if lang == 'en':
    print(f"  this one ~{tok(mine)} tokens / {len(mine)} chars; rank {rank} of {len(rows)} skills in {shown}; library total ~{total} tokens")
    print("  heaviest five: " + top)
else:
    print(f"  本条 ~{tok(mine)} token / {len(mine)} 字符，{shown} 下 {len(rows)} 个 skill 中排第 {rank}；全库 description 合计 ~{total} token")
    print("  最重的五条：" + top)
PY

section "$(L '跨 skill 触发重叠（本 description 的短语也出现在库内其他 description 里）—— 每个短语只该归一个 skill' 'Cross-skill trigger overlap (phrases from this description that also appear in other descriptions in the library) — each phrase should belong to one skill')"
python3 - "$dir" "$lib" "$LINT_LANG" <<'PY'
import sys, re, glob, os
d, lib, lang = sys.argv[1], sys.argv[2], sys.argv[3]
def desc(path):
    s = open(path, encoding='utf-8', errors='ignore').read()
    m = re.search(r'\A---\s*\n(.*?)\n---', s, re.S)
    if not m: return ''
    m2 = re.search(r'^description:\s*(.*?)(?=^\w[\w-]*:|\Z)', m.group(1), re.S | re.M)
    return re.sub(r'\s+', ' ', m2.group(1)).strip() if m2 else ''
me = os.path.basename(os.path.abspath(d)); mine = desc(os.path.join(d, 'SKILL.md'))
others = {os.path.basename(os.path.dirname(f)): desc(f) for f in glob.glob(os.path.join(lib, '*', 'SKILL.md'))}
others.pop(me, None)
stop = {'skill', 'skills', 'use', 'user', 'when', 'the', 'and', 'for', 'with', 'this', 'that', 'from', 'into',
        'use when', 'a skill', 'the user', 'it', 'not', 'or', 'to', 'of', 'in', 'on', 'an', 'is', 'are', 'does',
        '使用', '用户', '触发词', '包括', '默认', '或者', '以及', '可以', '需要', '不要', '用于', '本skill', '生成', '提示词'}
phrases = set()
for p in re.split(r'[，。；：、／/,;:.()（）「」“”"\'\[\]|·]+|\s+[-–—]\s+', mine):
    p = p.strip()
    ok_len = 2 <= len(p) <= 12 if re.search(r'[一-鿿]', p) else 2 <= len(p.split()) <= 4
    if ok_len and p.lower() not in stop and not re.fullmatch(r'[\W\d_]+', p):
        phrases.add(p)
hits = []
for p in sorted(phrases, key=len, reverse=True):
    who = [n for n, t in others.items() if p.lower() in t.lower()]
    if who: hits.append(f"  「{p}」 {'also in' if lang == 'en' else '也在'}: {', '.join(sorted(who))}")
print("\n".join(hits) if hits else ("  none" if lang == 'en' else "  无"))
PY
