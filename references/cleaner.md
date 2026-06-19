# Phase 3：Cleaner（清理）

ESLint 合规，消灭所有重复代码和无用代码。

---

## 3.1 ESLint 规则检查

来源：`project_config.json` 中的 `eslintConfig` 字段（首次配置时自动检测）

### 硬性规则（error 级别）

| 规则 | 要求 |
|------|------|
| `complexity: 15` | 单函数圈复杂度 ≤ 15（if/else/三元/&&/\|\|/case 每个 +1） |
| `@zz-common/nested-complexity` | 嵌套复杂度检查，避免多层嵌套条件 |
| `indent: 2` | 2 空格缩进，switch case 缩进 1 级 |
| `comma-dangle: never` | 末尾不加逗号 |
| `no-undef: error` | 变量必须先声明再使用 |
| `space-before-function-paren: never` | 函数名和括号之间不加空格 |

### 关闭的规则（不需要遵守）

- `semi: 0` — 不加分号
- `eqeqeq: 0` — 可以用 `==`
- `no-nested-ternary: 0` — 允许嵌套三元
- `camelcase: 0` — 命名不强制驼峰

---

## 3.2 降低复杂度的强制写法

**原则：单个 render/函数的分支数 ≤ 10，超过必须拆子组件或提取函数。**

### 提取渲染函数的时机

- JSX 中出现 3 个以上 `&&` 或三元条件 → 提取为 `renderXxx()` 方法
- 一个条件块超过 10 行 → 提取为独立子组件
- 同一组件有多个独立的条件渲染区域 → 每个区域提取一个 `renderXxx()`

```jsx
// ❌ render 内大量条件判断，复杂度超标
render() {
  return (
    <div>
      {showToggleBtn && isEnabled && onToggle && condition1 && condition2 && (
        <Button onClick={...} />
      )}
    </div>
  )
}

// ✅ 提取渲染函数，每个函数复杂度独立计算
renderToggleBtn() {
  const { mode, subject, onToggle } = this.props
  if (mode !== 'hq' || !onToggle) return null
  const isEnabled = subject.status !== 'disabled'
  return (
    <Tooltip title={isEnabled ? '禁用' : '启用'}>
      <Button ... />
    </Tooltip>
  )
}

render() {
  return <div>{this.renderToggleBtn()}</div>
}
```

### 状态数量限制

- 单个 Class Component 的 `this.state` 字段 ≤ 8 个
- 超过时按职责拆分为多个子组件

### 文件行数限制

- 单文件 ≤ 250 行（含注释）
- 超过时必须拆分

---

## 3.3 无用代码清理

- 删除未被任何文件 import 的组件/函数/变量
- 删除注释掉的代码块
- 删除空的 useEffect / 空的生命周期方法
- 删除未使用的 CSS class（通过 Grep 交叉验证）
- 删除未使用的 import 语句

**TokenGuard 规则**：通过 `file_digest.json` 的 imports/exports 字段做静态分析，不全量读文件。

具体方法：
1. 从 `file_digest.json` 收集所有文件的 exports
2. 从 `file_digest.json` 收集所有文件的 imports
3. exports 中未被任何 imports 引用的 → 标记为无用
4. 只对标记为无用的文件做 Grep 确认（防止动态引用遗漏）
5. 确认无用后删除

---

## 3.4 验证（增量批量模式）

只验证 `change_log.json` 中 phase=clean 的文件：

- [ ] 无文件超过 250 行
- [ ] 无函数圈复杂度 > 15
- [ ] 无 render 内分支数 > 10
- [ ] 无未使用的 import / 变量
- [ ] 无重复的 UI 结构
- [ ] 无重复的逻辑代码
- [ ] indent 2 空格
- [ ] comma-dangle never
- [ ] space-before-function-paren never

批量模式：收集所有问题 → 一次性修复 → 验证一次 → 通过则更新 status.json。
