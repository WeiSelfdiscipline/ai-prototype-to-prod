# Phase 2：Refiner（完善）

深度组件化拆分，抽取 hook，收敛权限，降低复杂度和重复度。

---

## 2.1 扫描当前目标代码

**TokenGuard 规则**：先读 `.agent/file_digest.json`，只对 hash 变化的文件重新扫描。

诊断四类问题：

### 结构问题
- 文件职责不清（页面逻辑混在组件里）
- 分层不足（hooks / services 缺失）

### 重复问题
- 相同 UI 结构出现 ≥2 次但未抽组件
- 相同接口调用逻辑在多处复制
- 相同样式类名在多个文件重复定义

### 复杂度问题
- 单文件行数 > 250 行
- 单组件条件分支 > 4 个（if/三元/&&）
- 单组件 state > 8 个

### 差异配置问题
- 重复结构中的差异点（某个块显隐不同）未抽离为 boolean props，仍以条件判断硬编码在 JSX 中

---

## 2.2 规划完善任务

只针对诊断出的问题生成任务列表，没问题的文件不碰。

输出追加到 `.agent/task_list.json`（phase 标记为 refine）。

---

## 2.3 实施完善

按任务列表执行，每个任务完成后更新 `change_log.json` + `file_digest.json`。

重点操作：
- 提取遗漏的通用 hooks（useSaveState、useComponentData）
- 拆分过大组件为子组件（超 250 行的必须拆）
- 收敛散落的差异点条件判断为 boolean props（由父组件传入）
- 合并重复的 UI 结构为通用组件
- 将散落的接口调用收敛到服务层

### 拆分规则

| 情况 | 操作 |
|------|------|
| 文件 > 250 行 | 按职责拆为子组件 |
| state > 8 个 | 按职责拆分，各子组件管理自己的 state |
| 相同 UI ≥ 2 处 | 抽为 common 组件，差异点用 boolean props（`showXxx`）控制 |
| 相同逻辑 ≥ 2 处 | 抽为 hook |

---

## 2.4 验证（增量批量模式）

只验证 `change_log.json` 中 phase=refine 的文件。

检查清单：
- [ ] 无单文件超过 250 行
- [ ] 无单组件 state 超过 8 个
- [ ] 重复结构中的差异点已抽离为 boolean props，不在组件内硬编码条件判断
- [ ] 无相同 UI 结构在两处以上重复定义
- [ ] 页面组件只做组合，不含业务逻辑
- [ ] 保存状态机统一走 `useSaveState`
- [ ] 数据加载统一走 `useComponentData`
- [ ] 每个组件目录含 `index.jsx` + `index.less`

批量模式：收集所有问题 → 一次性修复 → 验证一次 → 通过则更新 status.json。
