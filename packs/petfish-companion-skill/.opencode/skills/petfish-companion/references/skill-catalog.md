# 胖鱼PEtFiSh Skill Catalog

> 本文件是胖鱼全量技能包的能力索引。companion skill通过此文件了解每个pack的能力范围。

## Pack索引

### init — project-initializer-skill
- **定位**：项目初始化器
- **默认安装方式**：全局
- **核心能力**：
  - 创建标准项目目录结构
  - 根据项目类型（profile）自动安装推荐skill pack
  - 运行post-init wizard（双语、每步可跳过）
- **包含skill**：project-initializer
- **包含command**：/initproject
- **触发关键词**：初始化、新项目、project init、scaffold、创建项目

### companion — petfish-companion-skill
- **定位**：常驻伙伴
- **默认安装方式**：全局
- **核心能力**：
  - 感知用户需求、推荐skill
  - 管理已装skill状态
  - 连接三方市场搜索skill
  - 平台自动检测与适配
- **包含skill**：petfish-companion
- **包含command**：/petfish
- **触发关键词**：/petfish、what skills、what can you do、help with

### course — opencode-course-skills-pack
- **定位**：课程开发全生命周期
- **默认安装方式**：项目级
- **核心能力**：
  - 课程规划与项目治理
  - 提纲设计与模块拆分
  - 正文编写与重构
  - 实验、演示与作业设计
  - 学员/教师资料制作
  - QA/QC流程
  - 方法论沉淀
- **包含skill数**：15
- **包含command数**：10
- **包含agent数**：8
- **触发关键词**：课程、教学、大纲、课时、模块、学员、教师、实验、QA、QC、发布、讲义

### deploy — repo-deploy-ops-skill-pack
- **定位**：部署与运维
- **默认安装方式**：项目级
- **核心能力**：
  - 仓库运行时识别（技术栈、构建方式、启动入口）
  - 目标主机就绪检查
  - 部署执行（Docker/compose/systemd/k8s）
  - 功能验证（health check、smoke test）
  - 持续运维（巡检、版本管理、变更留痕）
  - 故障回滚
- **包含skill数**：7
- **触发关键词**：部署、上线、deploy、Docker、服务器、运维、回滚、health check、systemctl、nginx

### petfish — petfish-style-skill
- **定位**：工程写作风格改写
- **默认安装方式**：项目级
- **核心能力**：
  - 中英文技术文档风格改写
  - 去AI味、说人话
  - 工程化表达（结构清晰、证据驱动、简洁）
  - 中英文混排规范（紧凑排版，无多余空格）
  - 批量文件风格检查与修正
- **包含skill数**：1
- **触发关键词**：说人话、润色、去AI味、风格、改写、rewrite、polish、humanize

### ppt — opencode-ppt-skills
- **定位**：PPT设计与制作
- **默认安装方式**：项目级
- **核心能力**：
  - 读取/解析PPTX文件结构
  - 生成PPTX幻灯片
  - Slide QA检查
  - 视觉渲染（soffice/pdftoppm）
- **包含skill数**：2
- **触发关键词**：PPT、幻灯片、演示、slide、deck、presentation、PPTX

### testdocs — opencode-skill-pack-testcases-usage-docs
- **定位**：测试用例与使用文档生成
- **默认安装方式**：项目级
- **核心能力**：
  - 从代码/配置/接口自动生成测试用例
  - 生成使用文档、README、quick start
  - 测试矩阵、回归用例、验收用例
- **包含skill数**：2
- **触发关键词**：测试用例、test case、测试矩阵、文档、README、usage docs、API docs

## 内置Skill（companion pack自带）

### marketplace-connector
- **定位**：跨市场skill搜索
- **核心能力**：
  - 统一搜索胖鱼自有仓库、SkillKit、Smithery、Glama、anthropics/skills、GitHub
  - 按来源优先级排序结果
  - 支持JSON输出便于自动化
- **脚本**：`marketplace-connector/scripts/marketplace_search.py`
- **触发关键词**：搜索skill、找MCP、marketplace、search skills

### skill-author
- **定位**：skill创建与脚手架
- **核心能力**：
  - 从需求描述生成完整skill目录结构
  - 支持automation/workflow/knowledge三种模板
  - 生成SKILL.md、references/、scripts/骨架
  - 符合胖鱼skill规范（name≤64 chars, kebab-case）
- **脚本**：`skill-author/scripts/generate_skill.py`
- **触发关键词**：创建skill、新建技能、generate skill、scaffold skill

### skill-lint
- **定位**：skill质量验证
- **核心能力**：
  - 检查SKILL.md结构、frontmatter、description长度
  - 检查目录规范（references/、scripts/）
  - 检查脚本安全性（危险命令、hardcoded路径）
  - 支持递归扫描、自动修复
  - 100分制评分
- **脚本**：`skill-lint/scripts/lint_skill.py`
- **触发关键词**：检查skill、lint skill、验证技能质量、skill quality

### repo-skill-miner
- **定位**：从开源仓库挖掘可复用skill
- **核心能力**：
  - 分析GitHub或本地仓库结构
  - 识别可复用工作流（CI/CD、Docker、脚本、Agent框架）
  - 评估候选skill的复杂度、工具需求、安全风险
  - 生成mining报告（markdown/json）
  - 支持quick/standard/deep三种扫描深度
- **脚本**：`repo-skill-miner/scripts/mine_repo.py`
- **触发关键词**：分析仓库、挖掘skill、mine repo、skillize、extract skills

### skill-security-auditor
- **定位**：skill安全审计
- **核心能力**：
  - 静态分析scripts/中的危险命令（rm -rf、eval、curl|bash）
  - 检测secret访问（.env、.ssh、token）
  - 检测远程代码执行风险
  - 检测过宽文件系统权限
  - 输出风险评分(0.0-1.0)和pass/fail判定
  - 支持递归批量审计
- **脚本**：`skill-security-auditor/scripts/audit_skill.py`
- **触发关键词**：安全审计、security audit、skill安全、audit skill

### quality-gate
- **定位**：skill发布门禁
- **核心能力**：
  - 依次运行lint + security audit + metadata验证
  - 综合评审生成发布决策：PASS/CONDITIONAL/FAIL
  - 支持递归批量门禁
  - 可集成GitHub Action和pre-commit hook
- **脚本**：`quality-gate/scripts/run_gate.py`
- **触发关键词**：发布门禁、quality gate、publish skill、can this skill be released

### skill-description-optimizer
- **定位**：skill描述优化
- **核心能力**：
  - 分析描述长度、触发短语密度、特异性
  - 与兄弟skill做关键词重叠检测
  - 生成优化建议和改进版描述
- **脚本**：`skill-description-optimizer/scripts/optimize_description.py`
- **触发关键词**：优化描述、improve trigger、fix description、description too broad

### skill-trigger-evaluator
- **定位**：skill触发准确率测试
- **核心能力**：
  - 正向/反向查询集测试
  - 计算触发通过率、误触率、漏触率
  - 跨触发冲突检测（兄弟skill间）
  - 支持自定义测试集和自动生成
- **脚本**：`skill-trigger-evaluator/scripts/evaluate_triggers.py`
- **触发关键词**：测试触发、trigger accuracy、evaluate triggers、false positive

### skill-usage-tracker
- **定位**：skill使用追踪与分析
- **核心能力**：
  - 记录skill激活事件和用户反馈
  - 生成使用统计报告（Top skills、休眠skill、满意率）
  - 数据驱动的推荐优化
  - 本地存储、隐私安全
- **脚本**：`skill-usage-tracker/scripts/track_usage.py`
- **触发关键词**：使用统计、usage stats、skill analytics、which skills popular

## Profile→Pack映射

| Profile | 自动安装的Pack |
|---------|---------------|
| minimal | petfish |
| course | course, petfish |
| code | deploy, petfish, testdocs |
| ops | deploy, petfish |
| security | deploy, petfish, testdocs |
| writing | petfish, ppt |
| skills-package | petfish, testdocs |
| comprehensive | course, deploy, petfish, ppt, testdocs |

## 三方市场数据源

| 市场 | URL | 类型 | API |
|------|-----|------|-----|
| SkillKit | skillkit CLI / npm | Skill聚合 | HTTP :3737 |
| Smithery | smithery.ai | MCP Server | REST API |
| Glama | glama.ai/mcp | MCP Server | REST+GraphQL |
| anthropics/skills | GitHub | 官方Claude Skills | Git |
| github/awesome-copilot | GitHub | Copilot社区 | llms.txt |
| awesome-claude-code | GitHub | Claude Code社区 | Git |
