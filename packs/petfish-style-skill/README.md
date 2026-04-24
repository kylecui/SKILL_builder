# Petfish Style Rewriter Skill V2

This package provides an opencode-compatible writing skill for rewriting Chinese or English text into Petfish's preferred style.

## Goal

The skill is not a generic polishing tool. It is designed to convert AI-like, rhetorical, verbose, or loosely structured text into a clear, professional, problem-driven writing style.

## Core Features

- Petfish-style structural rewrite
- Strict / normal / light modes
- Structure-first analysis workflow
- Anti-pattern rules for AI-like writing
- Chinese and English writing profiles
- Quality checker script
- Eval prompts and expected criteria

## Installation

Copy this package into the root of an opencode project:

```bash
cp -r .opencode /path/to/your/project/
cp AGENTS.md /path/to/your/project/
```

Or copy only the skill directory:

```bash
cp -r .opencode/skills/petfish-style-rewriter /path/to/your/project/.opencode/skills/
```

## Usage Examples

```text
用我的语言习惯表达下面这段内容：
...
```

```text
请把这段话说人话，但保持正式和专业：
...
```

```text
Rewrite this email in my technical support writing style:
...
```

## Modes

- `strict`: strongest Petfish-style fitting; default for formal writing.
- `normal`: preserves some original wording while improving structure.
- `light`: minimal polishing; preserves most original structure.

## Quality Check

```bash
uv run .opencode/skills/petfish-style-rewriter/scripts/style_check.py input.md
```

The checker is heuristic. It helps identify likely problems such as long sentences, rhetorical phrases, buzzwords, and weak structure.
