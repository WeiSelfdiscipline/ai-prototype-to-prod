# Phase 1：Migrator（迁移）

将原型代码迁移到目标项目规范目录结构，完成基础组件化。

---

## 1.1 Reader — 扫描原型代码

**角色约束：只读不写，只描述不判断。**

扫描顺序：
1. glob 扫描项目结构，确认入口文件
2. 优先读取：`App.tsx/jsx`、`types.ts/js`、`constants.ts/js`、`services/`、`components/`
3. 逐文件统计：行数、state 数量、条件分支数

识别重点：
- 视图结构（页面切换逻辑、路由条件）
- 状态管理（全局 state、组件内 state）
- API 调用清单（接口名、参数、调用位置）
- 差异点配置（重复结构中某个块在不同位置显隐不同，识别这些差异点，后续抽离为 boolean props，如 `showXxx={true/false}`）
- 重复 UI 结构（出现 ≥2 次的卡片、弹窗、状态标签、保存按钮）
- 重复逻辑（保存状态机、数据加载模式，出现 ≥2 次）
- 交互行为（按钮点击、弹窗触发、抽屉打开、表单提交、路由跳转）
- 数据展示（图表类型、表格列定义、卡片字段）

输出：`.agent/codebase_map.json` + `.agent/file_digest.json`

```json
{
  "views": [{ "id": "", "name": "", "trigger": "", "stateCount": 0 }],
  "components": [{ "name": "", "file": "", "lines": 0, "issues": [] }],
  "apis": [{ "name": "", "method": "", "params": [], "calledIn": [] }],
  "diffProps": [{ "component": "", "prop": "showXxx", "trueAt": [], "falseAt": [] }],
  "duplicates": [{ "pattern": "", "locations": [], "severity": "high|medium" }],
  "interactions": [{ "trigger": "", "action": "", "location": "" }],
  "dataDisplay": [{ "type": "chart|table|card", "fields": [], "location": "" }],
  "stateFlows": [{ "entity": "", "states": [], "transitions": [], "location": "" }]
}
```

---

## 1.2 Planner — 规划重构方案

**角色约束：只输出计划，不写业务代码。**

输入：`codebase_map.json` + zlj_mht 规范（Read references/zlj-spec.md）+ 目标目录现状

工作：
1. 检查目标目录已有文件，确认哪些已完成
2. 将原型组件映射到规范目录结构（common / business / hooks / pages）
3. 识别哪些逻辑提取为 hook，哪些下沉到服务层
4. 生成带依赖顺序的任务列表（无依赖项先执行）
5. 生成需求文档
6. 如果 `project_config.json` 中 `routeConfig` 有值，询问用户父菜单路径：
   > 「检测到以下页面需要注册路由：[列出从原型识别到的页面路径]
   > 请选择父菜单挂载方式：
   > A. 我来指定：请输入父菜单路径（如 `/report`）
   > B. 自动推断：根据原型路由路径和目标项目现有路由结构自动判断」
   - 选 A → 将用户指定的路径写入 `project_config.json` 的 `parentRoute` 字段
   - 选 B → Planner 读取 `routeConfig` 文件，分析现有路由层级，推断最合适的父节点，输出推断结果让用户确认，确认后写入 `parentRoute`

输出：`需求文档.md` + `.agent/task_list.json`

```json
{
  "tasks": [
    {
      "id": "t1",
      "status": "pending",
      "type": "common_component|business_component|hook|page|service",
      "target": "components/common/StatusTag/index.jsx",
      "dependsOn": [],
      "protoRef": "App.tsx:行号",
      "spec": "从 App.tsx 第 xx 行提取，消除 3 处重复的状态 badge"
    }
  ]
}
```

### 需求文档结构

```
# AI 自助分析中心 - 产品需求文档

## 一、项目概述
## 二、页面与视图清单（视图 ID / 名称 / 触发条件 / 核心功能）
## 三、组件差异配置表（同一组件在不同场景下，哪些块显示 / 隐藏，对应 boolean props）
## 四、核心数据模型（TypeScript 接口定义）
## 五、可复用组件库（组件名 / Props 接口 / 使用场景 / 当前重复位置）
## 六、功能模块详述（每模块：功能描述 + 交互规则 + 权限控制）
## 七、视图流转（流程图 + 面包屑规则）
## 八、图表与可视化（支持类型 + 数据映射规则）
## 九、非功能性需求（交互体验 / 数据安全 / 可扩展性）
## 十、重复度与复杂度诊断（问题点 + 消除方案 + 重构优先级）
## 十一、待确认事项
## 变更记录（增量同步时追加）
```

---

## 1.3 Implementer — 逐任务实现

**角色约束：严格按 task 描述写代码，不自行发挥，不超出 task 范围。**

执行顺序（从无依赖到有依赖）：
1. 通用组件：StatusTag → SectionHeader → AIInsightPanel → SaveButton → DevPermissionBar
2. Hooks：useSaveState → useComponentData
3. 业务组件：SubjectCard → TemplateCard → ComponentCard → ComponentPicker → DrillDownDrawer → DrillConfigModal → HQEditor → SubjectModal → TemplateModal
4. 页面：SubjectsPage → SubjectDetailPage → TemplateDetailPage
5. 服务层：补全 `aiAnalysis.js` 中缺失的接口

每个文件完成后：
- 更新 `task_list.json` 中对应 task 的 `status` 为 `done`
- 追加到 `change_log.json`
- 更新 `file_digest.json`

所有组件/页面完成后，追加最后一步：
- 检查 `project_config.json` 中 `routeConfig` 字段是否有值
- 有值 → 读取路由配置文件，根据原型的视图结构追加对应路由和菜单项
- 无值（null）→ 跳过，在阶段摘要中提示用户手动配置路由

---

## 1.4 Review — 规范校验（批量模式）

**角色约束：对照清单逐条验证，收集所有问题后批量修复。**

只检查 `change_log.json` 中本阶段涉及的文件：

- [ ] 无单文件超过 300 行
- [ ] 无单组件 state 超过 8 个
- [ ] 重复结构中的差异点已抽离为 boolean props（`showXxx`），而非在组件内用条件判断硬编码
- [ ] 无相同 UI 结构在两处以上重复定义
- [ ] 页面组件（`*Page`）只做组合，不含内联业务逻辑
- [ ] 保存状态机统一走 `useSaveState`
- [ ] 数据加载 + AI 洞察统一走 `useComponentData`
- [ ] 每个组件目录含 `index.jsx` + `index.less`
- [ ] 服务层接口覆盖所有 API 调用
- [ ] Mock 数据集中在 `mockData.js`，不散落在组件内

发现不符合项 → 收集完整清单 → 一次性批量修复 → 重新验证修复项 → 通过后更新 `status.json`。

---

## 增量同步模式（触发词：「同步改动」「增量同步」「新包来了」）

### Differ — 对比变更

输入：新版 `codebase_map.json` + `.agent/snapshots/` 下上一版快照

```json
// .agent/diff_report.json
{
  "added": [{ "type": "component|api|view", "name": "", "detail": "" }],
  "modified": [{ "name": "", "changes": "" }],
  "deleted": [{ "name": "" }],
  "affectedTargetFiles": ["components/business/SubjectCard/index.jsx"]
}
```

### 增量流程

1. Reader：扫描新包，生成新版 `codebase_map.json`
2. Differ：对比上一版快照
3. Planner：只针对变更范围生成 task_list
4. Implementer：只修改受影响的文件
5. Reviewer：校验受影响文件
6. 更新需求文档变更记录
7. 存快照到 `snapshots/v{n}_codebase_map.json`
