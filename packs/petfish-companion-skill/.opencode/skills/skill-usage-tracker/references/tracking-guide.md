# Tracking Guide — Implementation Details / 追踪指南——实现细节

Data storage schema, metric formulas, retention policies, and integration patterns for skill usage tracking.

技能使用追踪的数据存储架构、指标计算公式、数据保留策略及集成模式。

---

## 1. JSON Schema Specification / JSON架构规范

### 1.1 根对象结构

```json
{
  "tracker_version": "1.0",
  "platform": "opencode|claude|cursor|codex|copilot|windsurf|antigravity",
  "project_root": "/absolute/path/to/project",
  "created_at": "2026-05-01T10:00:00Z",
  "updated_at": "2026-05-02T15:30:00Z",
  "schema_updated_at": "2026-01-01T00:00:00Z",
  "metadata": {
    "total_activations": 87,
    "total_skills": 15,
    "active_skills": 12,
    "dormant_skills": 3
  },
  "skills": { /* 见1.2 */ }
}
```

**约束条件：**
- `tracker_version`：固定为 `"1.0"`，用于版本检查和迁移判断
- `platform`：必须与当前项目平台匹配（否则警告）
- `created_at`, `updated_at`：ISO 8601格式，毫秒精度
- `project_root`：绝对路径，用于检测项目移动

### 1.2 Skill 对象结构

```json
{
  "skills": {
    "petfish-companion": {
      "metadata": {
        "first_seen": "2026-05-01T10:00:00Z",
        "last_used": "2026-05-02T15:30:00Z",
        "install_source": "global|project|builtin",
        "activation_context": "call_omo_agent|skill_trigger|manual_invocation"
      },
      "activation": {
        "total": 45,
        "by_session": [
          { "session_id": "ses_abc123", "count": 3, "first_at": "2026-05-01T10:05:00Z", "last_at": "2026-05-01T11:30:00Z" },
          { "session_id": "ses_def456", "count": 5, "first_at": "2026-05-02T09:15:00Z", "last_at": "2026-05-02T15:30:00Z" }
        ]
      },
      "feedback": {
        "helpful": { "count": 8, "ratings": [5, 5, 4, 5, 5, 4, 5, 5], "avg_score": 4.75 },
        "not_helpful": { "count": 1, "ratings": [2], "avg_score": 2 },
        "neutral": { "count": 2, "ratings": [3, 3], "avg_score": 3 }
      },
      "performance": {
        "avg_response_time_ms": 324,
        "max_response_time_ms": 1200,
        "min_response_time_ms": 45,
        "timeout_count": 0
      }
    }
  }
}
```

**字段约束：**

| 字段 | 类型 | 范围/枚举 | 必须 | 说明 |
|------|------|---------|------|------|
| `install_source` | string | `global\|project\|builtin` | ✓ | skill来源标记，用于追踪生命周期 |
| `activation_context` | string | `call_omo_agent\|skill_trigger\|manual_invocation` | ✓ | 激活来源，区分自动vs人工 |
| `ratings` | array<1-5> | [1, 5] | — | 用户评分，仅在feedback时记录 |
| `avg_score` | float | [1, 5] | — | 该类反馈的平均评分，自动计算 |
| `avg_response_time_ms` | int | [0, ∞) | — | 平均响应时间，性能分析用 |

---

## 2. Metric Calculation Formulas / 指标计算公式

### 2.1 激活相关指标

**激活率 (Activation Rate)**

```
激活率 = (该skill的月激活次数) / (所有skill的月激活次数) × 100%

用途：识别热门skill与冷门skill的分布
边界条件：
- 若总激活为0，则为 undefined（不记录）
- 若新skill（<7天），单独统计为"新skill"不纳入基准
```

**会话覆盖率 (Session Coverage)**

```
会话覆盖率 = (该skill被用过的会话数) / (项目总会话数)

用途：衡量skill的跨会话使用广度
边界条件：
- 同一会话中多次激活只计1次
- 会话开始时间由OpenCode/Claude等平台自动标记
```

**激活浓度 (Activation Density)**

```
激活浓度 = (该skill的总激活数) / (该skill的首用至末用的天数)

用途：衡量使用的集中程度（高浓度=经常用，低浓度=间歇使用）
边界条件：
- 若首用=末用（同天首次且唯一），则分母=1
- 若天数>365，标记为"长期低频"
```

### 2.2 反馈相关指标

**满意度 (Satisfaction Score)**

```
满意度 = (Σ helpful_ratings - Σ not_helpful_ratings) / (总反馈数) × 2

范围：[-2, 2]，其中：
  ≥ 1.5    ⟹ 高满意 (Very Satisfied)
  [0.5, 1.5) ⟹ 中满意 (Satisfied)
  [-0.5, 0.5) ⟹ 中立 (Neutral)
  < -0.5   ⟹ 不满 (Unsatisfied)

示例计算：
- 8个5分反馈 + 1个2分反馈 = (40 - 2) / 9 × 2 = 8.44 / 9 = 0.938 ✓ 中满意
```

**反馈覆盖率 (Feedback Coverage)**

```
反馈覆盖率 = (给过反馈的激活数) / (总激活数) × 100%

目标：≥ 20% 时反馈数据可信
警告：< 10% 时标记为"反馈不足"
```

### 2.3 健康度综合指标

**Skill健康度 (Health Score) — 100分制**

```
Health = A × 激活率权重 + B × 满意度权重 + C × 会话覆盖率权重

权重分布：
A = 激活率百分位 ÷ 100 × 40    （40分：使用量）
B = (满意度 + 2) ÷ 4 × 40       （40分：质量，转换到[0,1]）
C = 会话覆盖率 × 20              （20分：覆盖广度）

Health 分层：
≥ 80  ⟹ ★★★★★ 优秀（核心skill）
70-80 ⟹ ★★★★   良好（常用且满意）
50-70 ⟹ ★★★    中等（有用但使用不足）
30-50 ⟹ ★★     警告（需改进或推广）
< 30  ⟹ ★      风险（候选移除或重构）
```

---

## 3. Feedback Scoring Methodology / 反馈评分方法

### 3.1 五级制评分体系

| 分数 | 标签 | 用户行为 | 含义 |
|------|------|--------|------|
| 5 | Very Helpful | 👍 + 评论"完全解决问题" | Skill直接解决用户需求，输出高质量 |
| 4 | Helpful | 👍 | Skill有用但有小问题（轻微改进空间） |
| 3 | Neutral | 😐 | Skill输出有用但不符合期望；或部分有用 |
| 2 | Not Helpful | 👎 | Skill激活成功但输出无关或低质 |
| 1 | Harmful | 👎 + 标记问题 | Skill导致错误决策或浪费时间 |

### 3.2 加权反馈权值

为了防止极端反馈扭曲数据，采用 **时间衰减加权**：

```
反馈权值 = 基础权值 × 时间衰减因子

基础权值：
- 5分：1.0
- 4分：0.8
- 3分：0.5（中立，权值最低）
- 2分：0.2（负面但权值小于1）
- 1分：0.0（有害，完全排除）

时间衰减因子（指数衰减，7天半衰期）：
decay = 2^(-(距今天数 / 7))

示例：
- 今天的5分反馈：1.0 × 2^0 = 1.0
- 7天前的5分反馈：1.0 × 2^(-1) = 0.5
- 14天前的5分反馈：1.0 × 2^(-2) = 0.25
```

### 3.3 反馈异常检测

标记可疑反馈（防止水军或误操作）：

```
异常条件：
1. 同skill在5分钟内连续反馈 ≥5次
   ⟹ 标记为"批量反馈"，分别记录但加 × 0.5 权值

2. 同session内反馈与激活次数比 > 0.8
   ⟹ 标记为"过度反馈"，该session反馈 × 0.7 权值

3. 同用户（OpenCode会话ID）给某skill反馈 > 20次
   ⟹ 该用户对该skill的后续反馈 × 0.5 权值（防止重度用户偏差）
```

---

## 4. Data Retention & Rotation Policy / 数据保留与轮换策略

### 4.1 保留周期

| 数据类型 | 保留时长 | 触发操作 |
|---------|--------|---------|
| 实时激活事件 | 当前会话 | 会话结束时聚合到`by_session` |
| 按session聚合 | 90天 | 自动压缩到月维度 |
| 按月聚合 | 12个月 | 自动压缩到年维度 |
| 按年聚合 | 永久 | 保留用于长期趋势 |

### 4.2 压缩 (Compression) 规则

**从session级压缩到月级：**

```json
/* 压缩前：90条by_session记录 */
"by_session": [
  { "session_id": "ses_abc123", "count": 3, ... },
  { "session_id": "ses_def456", "count": 5, ... },
  ...
]

/* 压缩后：12条月度统计 */
"by_month": [
  {
    "year_month": "2026-05",
    "session_count": 45,      /* 该月总会话数 */
    "activation_count": 245,   /* 该月总激活数 */
    "avg_per_session": 5.4,
    "feedback_summary": {
      "helpful": 35,
      "not_helpful": 2,
      "neutral": 8
    }
  }
]
```

### 4.3 自动清理 (Auto-Cleanup)

```python
# 伪代码：在每次生成report时执行
def cleanup_old_data(usage_json, retention_days=90):
    cutoff_date = now() - timedelta(days=retention_days)
    
    # 1. 压缩old sessions
    old_sessions = [s for s in skills[name]['activation']['by_session'] 
                    if parse_iso(s['last_at']) < cutoff_date]
    if len(old_sessions) > 30:
        compress_to_monthly_view(old_sessions)
        remove_session_entries(old_sessions)
    
    # 2. 清理僵尸反馈（>1年无激活但有旧反馈）
    if skill['last_used'] < cutoff_date - 365:
        archive_feedback_to_separate_file()
        clear_recent_feedback()
    
    # 3. 重新计算metadata.dormant_skills
```

---

## 5. Integration Patterns / 集成模式

### 5.1 其他Skill如何上报数据

任何skill可通过调用tracker来上报自定义事件：

```bash
# 基础激活上报（companion自动调用）
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action activate \
  --skill-name my-skill \
  --target /path/to/project \
  --context "call_omo_agent"

# 带元数据的激活上报
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action activate \
  --skill-name my-skill \
  --target /path/to/project \
  --context "skill_trigger" \
  --metadata '{"execution_time_ms": 324, "output_tokens": 1250}'

# 用户反馈上报
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action feedback \
  --skill-name my-skill \
  --target /path/to/project \
  --rating 4 \
  --comment "有用但有小问题"

# 批量上报（用于离线会话）
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action batch-upload \
  --events-file /tmp/events.jsonl \
  --target /path/to/project
```

### 5.2 Skill内嵌集成

Skill脚本可导入tracker的Python库直接调用：

```python
# my_skill/scripts/my_main.py
from skill_usage_tracker.lib import UsageTracker

tracker = UsageTracker(project_root="/path/to/project")

# 在skill执行前
tracker.record_activation(
    skill_name="my-skill",
    context="skill_trigger",
    metadata={"input_tokens": 450}
)

# 在skill执行后
try:
    result = run_skill_logic()
    tracker.record_feedback(
        skill_name="my-skill",
        rating=5,
        session_id=os.getenv("OPENCODE_SESSION_ID")
    )
except Exception as e:
    tracker.record_feedback(
        skill_name="my-skill",
        rating=1,
        comment=f"Error: {str(e)}"
    )
```

### 5.3 监听模式 (Webhook)

对于需要被动监听所有skill激活的用例（如实时仪表板），tracker支持简单的文件监听模式：

```bash
# 监听 .opencode/skill-usage.json 变更，并运行自定义处理脚本
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action watch \
  --target /path/to/project \
  --on-change /path/to/my_handler.py
```

---

## 6. Privacy & Data Minimization / 隐私与数据最小化

### 6.1 不可记录的数据

设计上严格禁止以下数据进入usage.json：

| 禁止项 | 原因 | 检查方式 |
|-------|------|--------|
| 用户输入/提示词 | PII风险，可能包含代码/密钥 | 脚本参数白名单，非白名单参数拦截 |
| 文件路径/文件内容 | 项目隐私 | 只记录skill名，不记录target |
| 用户身份/邮箱 | PII直接关联 | 仅用session ID（平台生成，匿名） |
| 输出内容摘要 | 可能泄露项目信息 | 禁止记录output字段 |
| 网络请求/响应体 | 外部API隐私 | 只记录响应时间，不记录payload |

### 6.2 数据最小化原则

```python
# ✓ 记录
{
  "skill_name": "petfish-companion",
  "activations": 45,
  "session_id": "ses_abc123",  # 由平台自动生成，匿名
  "response_time_ms": 324,
  "rating": 5
}

# ✗ 禁止
{
  "user_email": "john@example.com",
  "project_path": "/Users/john/secret-startup",
  "input_prompt": "explain how to exploit CVE-2024-xxxx",
  "output_summary": "The API uses basic auth without HTTPS",
  "file_modified": "src/auth.ts"
}
```

### 6.3 用户控制

```bash
# 查看当前记录的所有skill
cat .opencode/skill-usage.json | jq '.skills | keys'

# 删除特定skill的所有记录
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action purge \
  --skill-name unwanted-skill \
  --target .

# 清空整个项目的tracking数据
rm .opencode/skill-usage.json

# 导出数据副本（用于外部分析）
uv run .opencode/skills/skill-usage-tracker/scripts/track_usage.py \
  --action export \
  --target . \
  --output /tmp/my_usage_backup.json
```

---

## 7. Example Tracking Records / 示例追踪记录

### 7.1 完整的usage.json示例

```json
{
  "tracker_version": "1.0",
  "platform": "opencode",
  "project_root": "/home/user/my-project",
  "created_at": "2026-05-01T10:00:00Z",
  "updated_at": "2026-05-02T15:30:00Z",
  "schema_updated_at": "2026-01-01T00:00:00Z",
  "metadata": {
    "total_activations": 87,
    "total_skills": 15,
    "active_skills": 12,
    "dormant_skills": 3,
    "period": "2026-05-01 ~ 2026-05-02"
  },
  "skills": {
    "petfish-companion": {
      "metadata": {
        "first_seen": "2026-05-01T10:00:00Z",
        "last_used": "2026-05-02T15:30:00Z",
        "install_source": "global",
        "activation_context": "call_omo_agent",
        "health_score": 92
      },
      "activation": {
        "total": 45,
        "by_session": [
          {
            "session_id": "ses_abc123",
            "count": 3,
            "first_at": "2026-05-01T10:05:00Z",
            "last_at": "2026-05-01T11:30:00Z"
          },
          {
            "session_id": "ses_def456",
            "count": 5,
            "first_at": "2026-05-02T09:15:00Z",
            "last_at": "2026-05-02T15:30:00Z"
          }
        ],
        "by_month": [
          {
            "year_month": "2026-04",
            "session_count": 25,
            "activation_count": 120,
            "avg_per_session": 4.8
          }
        ]
      },
      "feedback": {
        "helpful": {
          "count": 8,
          "ratings": [5, 5, 4, 5, 5, 4, 5, 5],
          "avg_score": 4.75,
          "weighted_avg": 4.62
        },
        "not_helpful": {
          "count": 1,
          "ratings": [2],
          "avg_score": 2,
          "weighted_avg": 1.8
        },
        "neutral": {
          "count": 2,
          "ratings": [3, 3],
          "avg_score": 3,
          "weighted_avg": 2.7
        }
      },
      "performance": {
        "avg_response_time_ms": 324,
        "max_response_time_ms": 1200,
        "min_response_time_ms": 45,
        "p95_response_time_ms": 950,
        "timeout_count": 0
      },
      "metrics": {
        "activation_rate": 51.7,
        "session_coverage": 0.64,
        "activation_density": 22.5,
        "satisfaction_score": 0.94,
        "feedback_coverage": 0.22
      }
    },
    "skill-lint": {
      "metadata": {
        "first_seen": "2026-05-01T12:00:00Z",
        "last_used": "2026-05-02T14:00:00Z",
        "install_source": "project",
        "activation_context": "manual_invocation",
        "health_score": 75
      },
      "activation": {
        "total": 15,
        "by_session": [
          {
            "session_id": "ses_abc123",
            "count": 8,
            "first_at": "2026-05-01T12:10:00Z",
            "last_at": "2026-05-01T14:20:00Z"
          },
          {
            "session_id": "ses_xyz789",
            "count": 7,
            "first_at": "2026-05-02T13:00:00Z",
            "last_at": "2026-05-02T14:00:00Z"
          }
        ]
      },
      "feedback": {
        "helpful": {
          "count": 3,
          "ratings": [5, 4, 5],
          "avg_score": 4.67
        },
        "not_helpful": {
          "count": 0,
          "ratings": [],
          "avg_score": null
        }
      },
      "performance": {
        "avg_response_time_ms": 156,
        "max_response_time_ms": 420,
        "min_response_time_ms": 78,
        "p95_response_time_ms": 380,
        "timeout_count": 0
      }
    },
    "marketplace-connector": {
      "metadata": {
        "first_seen": "2026-04-20T08:00:00Z",
        "last_used": "2026-04-25T10:30:00Z",
        "install_source": "global",
        "activation_context": "skill_trigger",
        "health_score": 45,
        "status": "DORMANT"
      },
      "activation": {
        "total": 2,
        "by_session": [
          {
            "session_id": "ses_old001",
            "count": 2,
            "first_at": "2026-04-25T09:00:00Z",
            "last_at": "2026-04-25T10:30:00Z"
          }
        ]
      },
      "feedback": {
        "helpful": {
          "count": 0
        },
        "not_helpful": {
          "count": 1,
          "ratings": [2]
        }
      }
    }
  }
}
```

### 7.2 字段注解

| 字段 | 示例 | 注释 |
|------|------|------|
| `health_score` | 92 | 综合评分，用于UI展示排序 |
| `weighted_avg` | 4.62 | 应用时间衰减后的加权平均，用于报告 |
| `p95_response_time_ms` | 950 | 第95百分位响应时间，识别性能瓶颈 |
| `activation_density` | 22.5 | 每天激活次数（avg），高值=重度依赖 |
| `session_coverage` | 0.64 | 使用该skill的会话占比，广度指标 |
| `feedback_coverage` | 0.22 | 反馈数/激活数，低值=反馈不足，需提醒用户 |
| `status: DORMANT` | — | 7天+未用时自动标记，提示可能问题 |
