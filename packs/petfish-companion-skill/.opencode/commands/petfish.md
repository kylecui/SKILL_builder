---
name: petfish
description: >
  胖鱼PEtFiSh伙伴入口。查看已装skill状态、搜索技能目录、
  获取安装建议、检测当前平台。
  Trigger: /petfish [subcommand]
  Subcommands: status, catalog, suggest, install <alias>, detect
---

# /petfish — 胖鱼PEtFiSh Companion

根据用户输入的子命令执行对应操作。如果没有子命令，默认显示status。

## 子命令路由

### /petfish 或 /petfish status

运行以下脚本获取当前项目的skill安装状态：

```bash
uv run .opencode/skills/petfish-companion/scripts/check_installed.py --target .
```

将输出格式化为状态卡片展示：
- 当前检测到的平台
- 已安装的pack列表（含版本）
- 未安装但可用的pack列表
- 安装提示

### /petfish catalog

运行以下脚本列出全量技能目录：

```bash
uv run .opencode/skills/petfish-companion/scripts/catalog_query.py --list
```

### /petfish search <keyword>

搜索技能目录：

```bash
uv run .opencode/skills/petfish-companion/scripts/catalog_query.py --search "<keyword>"
```

### /petfish suggest

1. 运行`detect_platform.py`检测当前平台
2. 运行`check_installed.py`获取已装状态
3. 分析当前项目的文件结构（检查是否有课程目录、Dockerfile、测试文件等）
4. 基于项目特征推荐缺失的skill pack

推荐逻辑：
- 存在`docs/01-outline/`或`docs/02-content/` → 推荐`course`
- 存在`Dockerfile`、`docker-compose.yml`、`deploy/` → 推荐`deploy`
- 存在`tests/`、`__tests__/`、`*.test.*` → 推荐`testdocs`
- 存在`*.pptx`或`slides/` → 推荐`ppt`

### /petfish install <alias>

提示用户运行安装命令：

```bash
# 本地安装
./install.ps1 -Pack <alias> -Target .   # PowerShell
./install.sh --pack <alias> --target .   # Bash

# 远程安装
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack <alias>
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack <alias>
```

注意：companion自身不直接执行安装，而是生成并展示正确的安装命令让用户执行。

### /petfish detect

运行平台检测：

```bash
uv run .opencode/skills/petfish-companion/scripts/detect_platform.py --target .
```

## 行为规则

1. 所有输出使用用户的对话语言（中文对话→中文输出，英文→英文）
2. 技术术语保持紧凑混排（`Docker部署`而非`Docker 部署`）
3. 不自动执行安装，只提供命令
4. 遇到错误时给出明确的排查建议
