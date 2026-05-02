# 胖鱼 PEtFiSh — 一句话安装提示词

将以下提示词粘贴到任意AI编程助手的对话框中，AI会自动执行安装。

---

## 通用安装提示词（中文版）

```
请帮我安装胖鱼PEtFiSh skill管理工具。执行以下步骤：

1. 检测当前操作系统（Windows用PowerShell，macOS/Linux用Bash）
2. 运行对应的远程安装命令：
   - Bash: curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init --detect
   - PowerShell: & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack init -Detect
3. 安装完成后运行 /initproject 命令，根据项目类型选择skill pack
```

## Universal Install Prompt (English)

```
Install PEtFiSh skill management tool for me. Steps:

1. Detect current OS (use PowerShell on Windows, Bash on macOS/Linux)
2. Run the matching remote install command:
   - Bash: curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init --detect
   - PowerShell: & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack init -Detect
3. After install, run /initproject to set up skill packs for this project
```

## 极简版（一行）

```
帮我装胖鱼：curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init --detect
```

```
Install PEtFiSh: curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init --detect
```

---

## 说明

- `--detect` 让胖鱼自动检测当前AI平台（Cursor/Claude Code/OpenCode等），将skill安装到正确路径
- `--pack init` 安装初始化器，后续通过`/initproject`按需装其他pack
- 适用于所有支持终端命令执行的AI编程助手：OpenCode、Claude Code、Cursor、Copilot、Windsurf、Codex、Antigravity等
- 如需安装全部pack，将`init`替换为`all`

---

*><(((^> 胖鱼 PEtFiSh — AI Worker's Companion*
