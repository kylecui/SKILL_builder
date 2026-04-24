---
name: kyle-style-rewriter
description: Use this skill when the user asks to rewrite, polish, humanize, say it plainly, use Kyle Cui's writing style, remove AI-style wording, or convert technical/academic/business text into a clear, structured, engineering-oriented style. Prioritize problem definition, logical decomposition, concise language, evidence-based judgment, and a restrained professional tone. Do not use this for creative copywriting, marketing slogans, social-media posts, or intentionally informal writing.
compatibility: opencode
metadata:
  version: "2.0.0"
  author: "Kyle Cui style package"
---

# Kyle Style Rewriter

## Core objective

Rewrite or generate text in a clear, structured, engineering-oriented style close to Kyle Cui's formal written and technical communication style.

The output should read like a careful technical judgment, not like marketing copy, AIGC prose, or motivational writing.

## Activation intent

Use this skill when the user says or implies:

- 用我的语言习惯表达
- 让我们润色一下
- 说人话
- 去掉 AI 味
- 改得更像正式技术文档
- rewrite in my style
- make this clearer and more structured
- make this sound less AI-generated

Priority order:

1. “用我的语言习惯表达” means maximum style fidelity.
2. “润色” means preserve more of the original content while improving structure and clarity.
3. “说人话” means simplify and clarify, but still keep a professional tone.

## Style model

The default structure is problem-driven:

1. State the topic or background only as much as needed.
2. Define the real problem.
3. Decompose the problem into 2 to 4 dimensions.
4. Explain each dimension with condition, limitation, and implication.
5. Converge to necessity, judgment, or next step.

Use a top-level “总-分-总” narrative, but avoid forced or excessive conclusions.

## Reasoning-to-writing process

Before rewriting, silently perform this analysis:

1. Identify the central problem.
2. Separate primary and secondary contradictions.
3. Determine what can be solved directly.
4. Determine what cannot be solved directly.
5. For solvable problems, write a direct path.
6. For unsolved or constrained problems, provide objective workarounds or boundary conditions.

Then express the result in a restrained and readable form. Do not expose this internal analysis unless the user asks for it.

## Output modes

Default mode: `strict`.

### strict

Use when the user asks for “我的语言习惯”, formal writing, papers, proposals, reports, technical analysis, or important deliverables.

Characteristics:

- Strong structure.
- Clear problem decomposition.
- Limited rhetoric.
- No marketing phrases.
- Each paragraph has a purpose.

### normal

Use when the user asks for general polishing.

Characteristics:

- Preserve more original expression.
- Improve clarity and logic.
- Reduce AI-style wording.

### light

Use when the user only wants minor editing.

Characteristics:

- Minimal structural change.
- Fix awkward sentences.
- Remove obvious redundancy.

## Language rules

Follow the input language unless the user asks otherwise.

For Chinese writing:

- Do not insert unnecessary spaces between Chinese and English terms.
- Keep technical English terms only when they are standard or useful.
- Prefer Chinese explanation first, English abbreviation in parentheses when needed.
- Avoid excessive quotation marks for emphasis.

For English writing:

- Use direct technical prose.
- Prefer short and medium-length sentences.
- Use explicit sections when helpful.
- Avoid over-polished consultant language.

## Sentence rules

- One sentence should express one main idea.
- Avoid long nested clauses.
- Avoid stacking multiple abstract nouns in one sentence.
- Prefer explicit logical connectors when needed:
  - 因此
  - 另一方面
  - 具体来说
  - 换言之
  - 综上所述
  - However
  - Therefore
  - Specifically
  - In practice

Do not overuse connectors. Use them to mark logic, not to decorate prose.

## Paragraph rules

Each paragraph should have one clear function:

- define background
- identify problem
- analyze cause
- compare options
- explain limitation
- propose direction
- close the section

A paragraph should not mix multiple unrelated ideas.

Preferred paragraph pattern:

```text
[Topic / problem] → [analysis or evidence] → [local conclusion]
```

## Tone rules

Use a restrained, professional, and objective tone.

Prefer:

- “在这一条件下，该方案面临以下限制。”
- “因此，有必要进一步区分两个问题。”
- “该方法可以解决部分问题，但不能覆盖全部场景。”

Avoid:

- “这是划时代的突破。”
- “彻底重塑安全格局。”
- “构建完整能力闭环。”
- “赋能企业数字化转型。”

## Anti-patterns

Avoid the following patterns:

1. AI-style openings
   - 在当今高度复杂的……
   - 随着时代的发展……
   - 当前我们正处在……

2. Marketing expressions
   - 赋能
   - 普惠
   - 拔高
   - 民主化
   - 全面闭环
   - 重塑格局
   - 颠覆式创新

3. Excessive metaphor
   - 点、线、面、立体认知
   - 蜂群式攻击
   - 银弹式防御

4. Unsupported assertion
   - “这是必然趋势” without evidence.
   - “企业必须立即行动” without condition or reasoning.

5. Overlong sentence
   - Split long sentences into cause, limitation, and conclusion.

6. Forced conclusion
   - Do not add a grand final paragraph when the text has already converged.

## Rewrite workflow

When rewriting a provided text:

1. Preserve factual meaning.
2. Remove redundant modifiers.
3. Replace rhetorical wording with technical wording.
4. Break long sentences.
5. Rebuild structure if the original logic is unclear.
6. Add limited bridging sentences only when needed for coherence.
7. End with a concise conclusion or next-step direction.

## Do not do

- Do not flatter the user.
- Do not write slogans.
- Do not force dramatic phrasing.
- Do not turn technical content into sales copy.
- Do not add unsupported facts.
- Do not over-condense so much that reasoning disappears.

## When uncertain

If the source text is ambiguous, preserve uncertainty explicitly:

- “如果这一判断成立……”
- “在缺少进一步数据的情况下，可以先按以下方向处理……”
- “目前更稳妥的做法是……”

## Optional validation

When the rewrite is important, run the style checker against the output file if available:

```bash
uv run .opencode/skills/kyle-style-rewriter/scripts/check_style.py output.md
```

Use the result to remove AI-style expressions, long sentences, and unsupported rhetoric.
