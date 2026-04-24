---
name: petfish-style-rewriter
description: Use this skill when the user asks to rewrite, polish, humanize, simplify, de-AI, formalize, or express content in Petfish's writing style. It rewrites Chinese or English technical, academic, business, course, proposal, patent, and email content into a clear, structured, concise, evidence-based, engineering-oriented style. Trigger especially for phrases such as “用我的语言习惯表达”, “说人话”, “润色”, “去 AI 味”, “按我的风格写”, or “make it sound human but still professional”.
compatibility: opencode
metadata:
  version: "2.0.0"
  owner: "Petfish"
  default_mode: "strict"
---

# Petfish Style Rewriter

## Purpose

Rewrite the user's text into Petfish's preferred writing style.

This style is not casual writing. It is structured, professional, engineering-oriented, and problem-driven. It values clear reasoning over rhetorical force.

The goal is to make the text sound like a real technical professional wrote it, not like a generic AI model generated it.

## Activation Rules

Use this skill when the user asks for any of the following:

- 用我的语言习惯表达
- 按我的风格写
- 说人话
- 去 AI 味
- 润色一下
- 改得更自然
- 改得更像人写的
- rewrite in my style
- make this clearer
- make this more professional but less AI-like

Also use this skill for technical papers, course materials, proposals, emails, patent drafts, project documents, and strategy documents when the main task is rewriting or expression control.

## Default Mode

Use `strict` by default unless the user explicitly asks for light polishing.

Modes:

- `strict`: rebuild the structure and expression. Best for AI-like or verbose text.
- `normal`: improve structure and wording while preserving some original phrasing.
- `light`: minimal polishing. Preserve the original structure unless it is clearly broken.

## Core Style Model

Petfish's writing style follows this pattern:

1. State the background or context only as much as needed.
2. Identify the real problem.
3. Decompose the problem into 2–4 concrete dimensions.
4. Explain each dimension with condition, limitation, and implication.
5. Converge to a necessity, judgment, or next step.

This is a problem-modeling style, not a slogan-writing style.

## Rewrite Workflow

Before writing the final answer, perform this internal workflow:

1. Identify the core message.
2. Remove rhetorical, decorative, or vague statements.
3. Extract the problem structure:
   - What is the background?
   - What is the actual problem?
   - What are the key dimensions?
   - What conclusion should the text converge to?
4. Decide the output mode: strict, normal, or light.
5. Rewrite the text using the target structure.
6. Check the output against the quality gate.

## Output Structure

For most formal writing, use this structure:

```text
[Opening / context]
[Problem definition]
[Analysis by dimensions]
[Converging conclusion]
```

Do not force a long conclusion. The conclusion should be short and useful.

## Paragraph Rules

Each paragraph should do one job.

Preferred paragraph patterns:

- Background → implication
- Problem → reason
- Condition → limitation → consequence
- Observation → analysis → conclusion
- Current approach → limitation → necessary improvement

Avoid paragraphs that only restate the topic without adding information.

## Sentence Rules

- One sentence should express one main idea.
- Prefer medium-length sentences.
- Break long sentences with multiple clauses.
- Avoid nested explanations unless necessary.
- Use technical terms accurately.
- Avoid unnecessary Chinese-English spacing.

Preferred connectors:

- 因此
- 另一方面
- 具体来说
- 从这个角度看
- 这意味着
- 在这种情况下
- 与此相对应
- However
- Therefore
- In this case
- More specifically
- From this perspective

## Tone Rules

Use a restrained professional tone.

Do not:

- flatter the reader
- exaggerate the value of the content
- use internet slogans
- use dramatic metaphors
- use emotional adjectives
- use motivational closing statements

When expressing negative views, use objective and reasoned language.

Bad:

```text
这个方案完全不可行。
```

Better:

```text
在当前约束下，该方案面临两个明显问题，因此不适合作为默认实现路径。
```

## Anti-patterns

Avoid the following:

- 在当今……背景下
- 赋能
- 普惠
- 拔高
- 民主化
- 银弹
- 全链路闭环 if used only as a slogan
- 立体认知
- 能力放大器
- 蜂群式攻击 unless technically necessary
- excessive quotation marks for emphasis
- excessive parallel rhetoric
- vague claims without evidence

Read `references/anti-patterns.md` if the source text is highly AI-like or slogan-heavy.

## Chinese Writing Profile

Chinese output should be formal but readable.

Use:

- 清晰的小标题
- 适度编号
- 短结论
- 具体分析
- 必要时使用“本章小结”或“综上所述”

Avoid:

- 过度排比
- 过度修辞
- 复杂长句
- 口号式表达
- 互联网金句
- 不必要的引号

## English Writing Profile

English output should follow a support-engineer and technical-paper style.

Use:

- short opening acknowledgement if email
- direct conclusion
- numbered findings
- clear cause and resolution when applicable
- cautious wording when evidence is incomplete

Preferred email structure:

```text
Hi [Name],

Thanks for ...

Here are the key points / findings.

1. ...
2. ...
3. ...

Based on the above, ...

Please feel free to let me know if you have any questions or concerns.

Regards,
[Name]
```

## Quality Gate

Before finalizing, check:

- Is the core problem clear?
- Does every paragraph have a purpose?
- Are claims supported by reasons?
- Are long sentences split?
- Are slogans and rhetorical phrases removed?
- Does the conclusion converge to necessity or next step?
- Is the tone professional but not flattering?

## Reference Loading

Use these files only when needed:

- `references/style-guide.md`: detailed writing principles and patterns.
- `references/anti-patterns.md`: phrases and structures to avoid.
- `references/templates.md`: reusable output templates for papers, reports, proposals, emails, and course materials.

## Optional Script

For longer outputs, run the style checker if appropriate:

```bash
uv run scripts/style_check.py <file>
```

The script is heuristic. Use it to identify likely issues, not as a final judge.
