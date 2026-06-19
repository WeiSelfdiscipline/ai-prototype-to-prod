---
name: proto-refactor-pipeline
description: 原型代码→生产代码逆向重构全流程 Pipeline（迁移→完善→清理→回测），含 TokenGuard 节省策略。当用户说「重构到目标项目」「转成规范代码」「同步改动」「增量同步」「新包来了」「生成需求文档」「反推需求」「回测功能」「检查覆盖率」「完善代码」「清理代码」「检查重复度」时触发。
---

# Pipeline：原型代码 → 生产代码逆向重构

统一编排 4 个阶段（迁移 / 完善 / 清理 / 回测），内置 TokenGuard 控制 token 消耗。支持任意目标项目，首次使用自动初始化配置。

---

## 触发条件与模式路由

| 触发词 | 模式 | 加载的 reference |
|--------|------|-----------------|
| 「重构到目标项目」「转成规范代码」「迁移过去」 | full | token-guard → migrator → refiner → cleaner → verifier |
| 「同步改动」「增量同步」「新包来了」「原型更新了」 | incremental | token-guard → migrator(增量) → verifier |
| 「生成需求文档」「反推需求」 | doc_only | migrator（仅 Reader + Planner） |
| 「完善代码」「组件化」「拆分组件」 | refine_only | token-guard → refiner |
| 「清理代码」「检查重复度」「ESLint 合规」 | clean_only | token-guard → cleaner |
| 「回测功能」「检查覆盖率」「功能对比」 | verify_only | token-guard → verifier |
| 「继续」「接着来」 | resume | 读 status.json → 加载对应阶段 reference |

---

## 执行协议

### 0. 智能模式判断（触发后第一步）

确定原型路径后，从 `project_config.json` 读取目标目录，**检查目标目录现状**再决定实际执行模式：

```
Glob: {targetDir}/components/**/*
```

判断规则：
- 目标目录有 ≥5 个组件文件 → 说明已有大量实现，**自动降级为 incremental 或 verify_only**
  - 如果用户说的是「重构」→ 建议用户选择：增量同步 / 仅回测 / 强制全量覆盖
  - 不要直接执行 full 模式覆盖已有代码
- 目标目录为空或文件 < 5 个 → 正常执行 full 模式
- 目标目录有 `.agent/status.json` → 优先走断点恢复逻辑
- verify_only 模式下如果 `.agent/codebase_map.json` 不存在 → 提示用户先跑 migrator 或提供原型路径重新扫描

### 1. 识别原型路径

1. 用户在触发词后直接提供路径 → 使用该路径
2. 用户说「原型在 xxx」「代码包在 xxx」→ 使用该路径
3. 用户说「原型更新了」「git pull 了」但未提供路径 → 从 `project_config.json` 读取上次的 `protoPath`
4. 未提供路径且无历史记录 → 询问：「请提供原型代码包的路径」

### 2. 项目配置（首次使用自动初始化）

检查 `{原型项目根目录}/.agent/project_config.json` 是否存在：

**存在** → 直接读取，跳到下一步。

**不存在** → 执行首次配置流程：

#### Step 1：询问基础路径
1. 目标项目路径（重构后的代码放哪里）
2. 服务层文件路径
3. 菜单/路由配置文件路径（如 `config/routes.js`，不需要可跳过）

#### Step 2：自动读取目标项目规范
从目标项目中自动读取以下文件（存在则读，不存在则跳过）：
- `.eslintrc.js` / `.eslintrc.json` — 提取 ESLint 规则
- `CLAUDE.md` / `.claude/CLAUDE.md` — 提取团队编码约束
- `package.json` — 提取技术栈（框架、UI 库、构建工具）
- 目标目录结构 — 推断组件组织方式（Glob 扫描）

#### Step 3：基于读取结果生成 spec.md
将上述信息整合为 `.agent/project_spec.md`，包含：
- 技术栈（从 package.json + 目录结构推断）
- 目录结构（从 Glob 结果提取）
- ESLint 硬性规则（从 eslintrc 提取 error 级别规则）
- CLAUDE.md 中的编码约束（原文引用）
- 组件规范（从已有组件文件的写法推断）

#### Step 4：询问用户补充约束
生成 spec 后，询问用户：
「已基于目标项目自动生成规范，还有没有额外的约束要加？比如：命名规则、禁止使用的写法、必须遵守的模式等」

用户补充的内容追加到 `.agent/project_spec.md` 末尾。

#### Step 5：保存配置

```json
// .agent/project_config.json
{
  "targetDir": "<用户提供的目标路径>",
  "serviceFile": "<用户提供的服务层路径>",
  "routeConfig": "<用户提供的菜单/路由配置文件路径，可为 null>",
  "parentRoute": "<Planner 阶段确认的父菜单路径，可为 null>",
  "eslintConfig": "<自动检测到的 eslintrc 路径>",
  "specRef": ".agent/project_spec.md",
  "claudeMd": "<自动检测到的 CLAUDE.md 路径>"
}
```

后续所有阶段从 `project_config.json` 读取路径，从 `project_spec.md` 读取规范。

### 3. 按需加载 reference

确定模式后，**只 Read 该模式需要的 reference 文件**，不加载无关阶段的规范：

```
Read: references/token-guard.md     ← 除 doc_only 外所有模式都加载
Read: references/migrator.md        ← full / incremental / doc_only
Read: references/refiner.md         ← full / refine_only
Read: references/cleaner.md         ← full / clean_only
Read: references/verifier.md        ← full / incremental / verify_only
Read: .agent/project_spec.md        ← 所有涉及写代码的模式（从项目配置中读取）
```

**注意**：规范文件优先读取 `.agent/project_spec.md`（首次配置时自动生成）。如果不存在，回退到 `references/zlj-spec.md` 作为示例参考。

**全流程模式下的分阶段加载**：不要一次性读取所有 reference。每个阶段开始时才读取该阶段的 reference，上一阶段的详细规范已经执行完毕不需要保留在上下文中。

### 4. 状态管理

通过 `.agent/status.json` 追踪进度，支持断点恢复：

```json
{
  "mode": "full",
  "protoPath": "/path/to/proto",
  "currentPhase": "migrate",
  "phases": {
    "migrate": { "status": "pending", "timestamp": null },
    "refine":  { "status": "pending", "timestamp": null },
    "clean":   { "status": "pending", "timestamp": null },
    "verify":  { "status": "pending", "timestamp": null }
  },
  "version": 1
}
```

### 5. 阶段切换

每个阶段完成后：
1. 更新 `status.json` 对应 phase 为 `done`
2. 输出精简摘要（改了几个文件、修复了几个问题）
3. Read 下一阶段的 reference → 继续执行

### 6. 断点恢复

用户说「继续」时：
1. 读取 `status.json`
2. 找到第一个 `status !== "done"` 的 phase
3. `in_progress` → 检查 `task_list.json` 中未完成的 task，从那里继续
4. `pending` → 正常启动该阶段
### 7. 输出纪律

- 中间过程（Grep 结果、文件内容）视为内部数据，**不向用户输出**
- 只输出结论性信息：「改了什么 + 文件路径:行号」或覆盖率摘要
- 禁止在输出中复述已写入文件的完整代码
- 回测报告只输出 summary + missing 项，covered 项不逐条打印

---

## .agent/ 目录结构

```
{原型根目录}/.agent/
├── project_config.json     # 项目配置（首次生成，跨项目复用的关键）
├── project_spec.md         # 自动生成的项目规范（基于目标项目读取）
├── status.json             # 全局状态（断点恢复）
├── codebase_map.json       # 原型代码全景图
├── task_list.json          # 带依赖顺序的任务列表
├── file_digest.json        # 文件摘要缓存（TokenGuard）
├── change_log.json         # 变更追踪（TokenGuard）
├── diff_report.json        # 增量同步变更报告
├── coverage_report.json    # 功能覆盖率报告
└── snapshots/              # 版本快照
    └── v1_codebase_map.json
```
