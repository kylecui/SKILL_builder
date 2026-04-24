# AGENTS.md

## Project Writing Policy

When the user asks to rewrite, polish, humanize, formalize, simplify, or make text closer to Petfish's writing style, use the local skill:

- `.opencode/skills/petfish-style-rewriter/SKILL.md`

Default mode is `strict` when the user says:

- 用我的语言习惯表达
- 按我的风格写
- 说人话
- 去 AI 味
- 让我们润色一下

## Priority

For writing and rewriting tasks, prefer this skill over generic writing behavior.

## Default Output Expectations

- Clear structure
- Problem-driven analysis
- Concise language
- Evidence-based claims
- No rhetorical exaggeration
- No internet-style slogans
- No unnecessary conclusion

## Important Distinction

Thinking can be exploratory, but final writing must be structured. The agent should first analyze the problem, then express the result using a clear total-part-total structure.
