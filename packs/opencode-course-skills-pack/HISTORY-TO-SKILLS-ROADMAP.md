# 从历史课程沟通沉淀为 Skills 的路线图

## 1. 目标

将历史对话、项目经验、课程方法论和交付偏好，逐步沉淀为可复用的 OpenCode skills，而不是每次从头解释。

## 2. 沉淀原则

1. **先沉淀反复出现的模式**  
   例如：课程总纲设计、模块拆解、实验设计、QA 评审、教师资料与学员资料分离。

2. **先沉淀“方法”，再沉淀“答案”**  
   不是把某次课程内容原样固化，而是提炼成以后还能复用的工作法。

3. **把高频纠偏变成 gotchas**  
   凡是你反复纠正代理的地方，都应进入相应 skill 的 gotchas 或 review checklist。

4. **把重用价值高的文本变成 template / reference**  
   例如：教学计划模板、QA 检查单、QC 报告模板、实验说明模板。

## 3. 优先沉淀的历史能力

### 3.1 战略性课程定位
适合继续拆成：
- `course-positioning-strategy`
- `training-system-architecture`

### 3.2 课程资产映射与客户提案
适合继续拆成：
- `course-proposal-authoring`
- `course-asset-mapping`

### 3.3 AI 安全 / 架构类课程方法论
适合继续拆成：
- `ai-security-course-patterns`
- `agent-architecture-course-patterns`

### 3.4 论坛 / 圆桌 / 讲稿型课程周边材料
适合继续拆成：
- `panel-discussion-materials`
- `speaker-card-authoring`

### 3.5 课程实验与项目实战
适合继续拆成：
- `lab-environment-planning`
- `capstone-project-design`

## 4. 推荐沉淀顺序

### 第一阶段：先把“课程生产线”固化
已纳入当前包：
- 目录结构
- 开发计划
- 课程提纲
- 课程正文
- 实验
- 学员资料
- 教师资料
- QA
- QC

### 第二阶段：再把“你们自己的课程方法论”固化
建议从以下来源提炼：
- CAISP / CAIDCP 融合课程讨论
- AI 人才体系与课程架构讨论
- 圆桌与讲稿策划讨论
- 客户提案书与实施计划讨论
- 对课程“战略写手”的偏好与约束

### 第三阶段：再做“评测与触发优化”
建议为关键 skills 增加：
- `evals/evals.json`
- should-trigger / should-not-trigger 样例
- 常见输入输出样例
- description 调优记录

## 5. 每个新 skill 的建议结构

```text
skill-name/
  SKILL.md
  references/
    workflow.md
    gotchas.md
  assets/
    template.md
  scripts/
    helper.py
  evals/
    evals.json
```

## 6. 建议新增的后续 skill 清单

- `course-proposal-authoring`
- `course-asset-mapping`
- `course-positioning-strategy`
- `training-system-architecture`
- `lab-environment-planning`
- `capstone-project-design`
- `speaker-card-authoring`
- `panel-discussion-materials`
- `course-eval-design`
- `skill-eval-governance`

## 7. 推荐工作方式

每次你和我完成一轮高价值课程工作后，可以立即做三件事：

1. 标记这次工作中“反复使用的方法”
2. 标记这次工作中“反复纠正的错误”
3. 决定它应该进入：
   - `SKILL.md`
   - `references/`
   - `assets/`
   - `scripts/`
   - `evals/`

这样这套包会越来越像你自己的课程开发操作系统。
