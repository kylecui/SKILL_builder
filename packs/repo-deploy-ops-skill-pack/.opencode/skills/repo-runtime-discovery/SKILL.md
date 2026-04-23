---
name: repo-runtime-discovery
description: 读取本地仓库或 GitHub repo，识别技术栈、构建方式、启动入口、配置与密钥需求、数据库/缓存/MQ 依赖，以及适合的部署方法。Use when the user asks to inspect a repo before deployment, infer runtime/build/test/run commands, understand Docker/systemd/compose/k8s signals, or generate a deployment brief.
compatibility: Requires git and Python 3.11+; uv recommended for scripts. Helpful for local repos and GitHub repositories.
license: Internal use
---

# 目标

这个技能负责回答一个问题：

**“这个 repo 到底该怎么被部署和运行？”**

它不直接做高风险部署，而是先把 repo 的运行模型讲清楚。

## 何时使用

- 用户要求先读 repo / 看 GitHub 项目
- 用户不知道如何构建、启动、部署
- 需要先判断适合 Docker、compose、systemd 还是 k8s
- 需要生成部署简报
- 需要盘点运行依赖、环境变量和阻塞项

## 首选做法

### 1. 先收集顶层信号

优先检查：

- `README*`
- `Makefile`, `Taskfile.yml`
- `Dockerfile*`
- `compose.yaml`, `docker-compose.yml`
- `package.json`
- `pyproject.toml`, `requirements.txt`, `uv.lock`
- `go.mod`
- `Cargo.toml`
- `pom.xml`, `build.gradle*`
- `Procfile`
- `.env.example`, `.env.sample`
- `deploy/`, `ops/`, `infra/`, `scripts/`, `k8s/`, `helm/`

### 2. 识别最可能的运行方式

判断优先级：

1. **repo 自带部署材料** 最可信  
   如 compose、helm chart、systemd unit、deploy 脚本
2. **README 中明确写明的开发/生产运行方式**
3. **构建文件推导出的默认方式**
4. **通用保底方式**
   - Python: virtualenv/uv + process manager/systemd
   - Node: install + build + runtime command
   - Go/Rust: build binary + systemd/container
   - Java: jar/service/container

### 3. 识别环境依赖与状态依赖

特别留意：

- 数据库连接串
- Redis、MQ
- 外部 API key
- S3/OSS/MinIO
- 域名/TLS 证书
- 挂载目录、缓存目录、上传目录
- 是否需要迁移脚本
- 是否包含 worker / cron / scheduler / websocket

### 4. 提取构建、测试、启动线索

尽量找到：

- build command
- test command
- run command
- health endpoint
- default port
- config file path
- log path / stdout logging behavior

## 推荐脚本

先运行：

```bash
uv run scripts/repo_inventory.py --root . --output -
```

对于 GitHub repo，先用 `git clone --depth=1` 到临时目录，或用工具/网页读取关键文件，再运行同样的盘点逻辑。

## 输出格式

必须输出一个“部署简报”，至少包含：

```markdown
## Repo source
## Stack summary
## Deployment signals
## Runtime dependencies
## Required configuration
## Candidate deployment methods
## Risks / blockers
```

可直接使用模板：
`assets/deployment-brief-template.md`

## 决策规则

### 适合 Docker / Compose 的信号
- 明确存在 `Dockerfile` 或 compose 文件
- README 写明使用容器运行
- 依赖较多，容器化能显著降低环境差异

### 适合 systemd 的信号
- 已有二进制/虚拟环境/明确启动命令
- 目标环境就是传统 Linux 主机
- 需要稳定后台运行并便于 journalctl 管理

### 适合 k8s / Helm 的信号
- repo 已带 chart / manifest
- 用户明确要求 k8s
- 环境本身是集群，不是单机

## gotchas

- `.env.example` 只能说明“变量名”，不能说明“真实值”
- `README` 里的开发启动方式不等于生产部署方式
- 有 `Dockerfile` 不代表它就是唯一或最佳方案
- 测试命令存在，不代表 smoke test 足够覆盖上线验证
- 没有明确 health endpoint 时，要从代码、路由、反向代理配置中找线索

## 何时读取参考文件

- 遇到多种部署方式冲突时，读取：
  `references/deployment-signal-priority.md`
- 遇到配置/密钥梳理问题时，读取：
  `references/config-and-secret-audit.md`
