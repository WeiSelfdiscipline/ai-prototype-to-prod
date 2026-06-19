# Phase 4：Verifier（回测）

对照原型代码，逐项验证重构后的目标项目功能覆盖率 100%。

---

## 4.1 提取原型功能清单

从 `.agent/codebase_map.json` 提取（**不重新扫描原型代码**，节省 token）：

| 维度 | 提取内容 |
|------|---------|
| 视图 | 所有页面/视图 ID、名称、触发条件 |
| API | 所有接口名、参数、HTTP 方法 |
| 交互 | 所有按钮点击、弹窗触发、抽屉打开、表单提交、路由跳转 |
| 差异配置 | 原型中各使用场景对应的 boolean props 差异点（哪些块显示/隐藏）|
| 状态流转 | 启用/禁用/草稿等状态切换逻辑 |
| 数据展示 | 图表类型、表格列定义、卡片字段 |
| 条件分支 | 所有 if/else/三元的业务含义 |

---

## 4.2 扫描目标代码

**TokenGuard 规则**：优先从 `file_digest.json` 读取，只对摘要信息不足的文件做 Grep 补充。

提取已实现的功能清单，维度与 4.1 对齐。

扫描方式：
1. 读取 `file_digest.json` 获取所有目标文件的 props / apis / exports
2. 对每个原型功能点，在 digest 中搜索对应实现
3. digest 中找不到的 → Grep 目标目录确认
4. Grep 也找不到的 → 标记为 missing

---

## 4.3 交叉比对

逐项匹配原型功能清单与目标项目已实现功能清单，输出覆盖率报告。

`.agent/coverage_report.json`：

```json
{
  "summary": {
    "total": 45,
    "covered": 43,
    "missing": 2,
    "extra": 0,
    "coverageRate": "95.6%"
  },
  "views": [
    { "proto": "subjects", "target": "SubjectsPage/index.jsx", "status": "covered" },
    { "proto": "subject_detail", "target": "SubjectDetailPage/index.jsx", "status": "covered" }
  ],
  "apis": [
    { "proto": "getSubjectList", "target": "aiAnalysis.js:getSubjectListApi", "status": "covered" },
    { "proto": "toggleSubject", "target": null, "status": "missing", "protoRef": "App.tsx:234" }
  ],
  "interactions": [
    { "proto": "点击主题卡片→进入详情", "target": "SubjectCard onClick→history.push", "status": "covered" }
  ],
  "diffProps": [
    { "proto": "某场景展示块A", "target": "ComponentCard props.showBlockA", "status": "covered" }
  ],
  "stateFlows": [
    { "proto": "主题启用/禁用切换", "target": "SubjectsPage handleToggle", "status": "covered" }
  ],
  "dataDisplay": [
    { "proto": "柱状图-销售额分布", "target": "ComponentCard renderChart", "status": "covered" }
  ],
  "missing": [
    { "type": "api", "name": "toggleSubject", "protoRef": "App.tsx:234", "action": "需补充到服务层并在 SubjectsPage 中调用" }
  ]
}
```

---

## 4.4 自动补全缺失项

对 `missing` 清单逐项补全实现：

| 缺失类型 | 补全方式 |
|---------|---------|
| 缺 API | 补充到服务层 `aiAnalysis.js` + 在对应组件中 import 并调用 |
| 缺交互 | 在对应组件中补充事件处理函数 + JSX 绑定 |
| 缺差异配置 | 在对应组件补充 boolean props + 父组件传入对应值 |
| 缺数据展示 | 在对应组件中补充渲染逻辑 |
| 缺状态流转 | 在对应组件中补充状态切换逻辑 |
| 缺视图 | 创建新的页面组件 |

每项修复后更新 `change_log.json` + `file_digest.json`。

---

## 4.5 二次验证

修复后重新比对，直到 `coverageRate` = 100%。

**TokenGuard 规则**：
- 二次验证只检查 `missing` 项涉及的文件，不重新全量扫描
- 已标记为 covered 的项不再重复验证
- 最多 2 轮补全。第 2 轮仍有 missing → 列出剩余项告知用户，不再循环

---

## 输出

回测完成后向用户输出精简报告：

```
回测完成：
- 功能覆盖率：100%（45/45）
- 补全了 2 项缺失：
  - toggleSubject API → aiAnalysis.js:45
  - 主题禁用按钮交互 → SubjectCard/index.jsx:78
```
