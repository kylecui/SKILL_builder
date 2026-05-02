# Usage Tracking Reference

## 1. 为什么要追踪使用

Skill生态的健康度不能只看数量，还要看实际使用情况：

- **高激活 + 高满意** → 核心skill，优先维护
- **高激活 + 低满意** → 需要改进（可能是描述误导触发）
- **低激活 + 高满意** → 小众但有价值，保留
- **低激活 + 低满意** → 候选淘汰或重构
- **已安装 + 零激活** → 描述问题或不匹配项目类型

## 2. 使用事件类型

| 事件 | 触发条件 | 记录内容 |
|------|---------|---------|
| activate | Skill被agent选中并执行 | skill名、时间戳 |
| feedback_helpful | 用户表示满意 | skill名、正向计数+1 |
| feedback_not_helpful | 用户表示不满 | skill名、负向计数+1 |
| session_start | 新会话中首次激活该skill | session计数+1 |

## 3. 指标定义

### 3.1 基础指标

| 指标 | 计算方式 | 用途 |
|------|---------|------|
| 总激活次数 | sum(activations) | 衡量skill使用量 |
| 独立会话数 | count(distinct sessions) | 衡量使用广度 |
| 平均每会话激活 | activations / sessions | 衡量单次会话依赖度 |
| 最后使用距今 | now - last_used | 衡量活跃度 |
| 满意率 | helpful / (helpful + not_helpful) | 衡量质量 |

### 3.2 衍生指标

| 指标 | 计算方式 | 用途 |
|------|---------|------|
| 使用集中度 | top1_activations / total_activations | 是否过度依赖单个skill |
| 覆盖率 | used_skills / installed_skills | 已装skill的利用率 |
| 休眠率 | dormant_skills / installed_skills | 多少skill超过7天未用 |

## 4. 报告周期

- **实时**：每次activate事件立即写入
- **会话级**：会话结束时汇总
- **项目级**：按需生成（/petfish stats）

## 5. 数据格式

使用JSON存储，位于项目的平台目录下：
- OpenCode: `.opencode/skill-usage.json`
- Claude Code: `.claude/skill-usage.json`
- Cursor: `.cursor/skill-usage.json`
- 其他平台: `.agents/skill-usage.json`

## 6. 隐私设计

### 记录什么
- Skill名称（公开信息）
- 时间戳（本地时间）
- 激活/反馈计数（纯数字）

### 不记录什么
- 用户输入/对话内容
- 文件内容/路径
- 用户身份/设备信息
- 项目代码

### 数据位置
- 仅本地项目目录
- 不同步到远程
- 用户可随时 `rm .opencode/skill-usage.json` 清除
