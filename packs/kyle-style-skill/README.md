# Kyle Style Skill Package

This package provides an OpenCode-compatible skill for rewriting text in Kyle Cui's preferred formal writing style.

## What it does

The skill converts AI-style, verbose, or loosely structured text into a clearer engineering-oriented style.

It emphasizes:

- problem definition
- logical decomposition
- concise expression
- restrained professional tone
- evidence-based judgment

## Directory structure

```text
.opencode/
  skills/
    kyle-style-rewriter/
      SKILL.md
      references/style-guide.md
      examples/rewrite-examples.md
      evals/evals.json
      scripts/check_style.py
AGENTS.md
README.md
pack-manifest.json
opencode.example.json
```

## Installation

Copy `.opencode` and `AGENTS.md` into the root of your project:

```bash
cp -r .opencode /path/to/your/project/
cp AGENTS.md /path/to/your/project/
```

Optional: merge `opencode.example.json` into your own `opencode.json`.

## Usage examples

```text
用我的语言习惯表达：
<text>
```

```text
请把这段话说人话，但保持正式技术文档风格：
<text>
```

```text
Rewrite this in Kyle's technical email style:
<text>
```

## Style check

After writing output to a file, run:

```bash
uv run .opencode/skills/kyle-style-rewriter/scripts/check_style.py output.md
```
