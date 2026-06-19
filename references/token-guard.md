# TokenGuard 策略

贯穿所有阶段的 token 节省规则。每个阶段执行前必须遵守。

---

## 策略 1：读一次，缓存摘要

首次读取文件后，生成摘要存入 `.agent/file_digest.json`。后续阶段先读摘要，只在需要修改时才读原文。

```json
{
  "components/business/SubjectCard/index.jsx": {
    "lines": 186,
    "states": ["loading", "expanded"],
    "props": ["subject", "mode", "onToggle", "onClick"],
    "apis": ["getSubjectDetail"],
    "diffProps": ["showXxx=true 控制某块显示"],
    "imports": ["react", "antd/Button", "@/services/report/aiAnalysis"],
    "exports": ["default SubjectCard"],
    "hash": "a3f2b1c...",
    "mtime": "2026-05-15T10:30:00"
  }
}
```

**执行规则**：
- 每个阶段启动时先读 `file_digest.json`
- 需要改某个文件 → 对比 hash + mtime → 未变则用摘要 → 已变则重读并更新摘要
- **禁止**在同一阶段内对同一文件做 2 次全量读取

---

## 策略 2：分段读取

| 文件行数 | 读取方式 |
|---------|---------|
| ≤ 120 行 | 全量读取 |
| 120-250 行 | 先读摘要定位，再 `Read(file, offset, limit)` 分段读 |
| > 250 行 | **禁止全量读取**，必须 Grep 定位 → 分段读取目标区域 |

---

## 策略 3：增量验证

Review 时只验证 `change_log.json` 中本轮修改过的文件及其直接依赖，不全量扫描。

```json
// .agent/change_log.json
{
  "changes": [
    { "file": "components/business/SubjectCard/index.jsx", "action": "created", "phase": "migrate", "lines": 186 },
    { "file": "hooks/useSaveState.js", "action": "modified", "phase": "refine", "lines": 45 }
  ]
}
```

---

## 策略 4：批量修复

发现问题时先收集所有问题清单，一次性批量修复，再统一验证一次。

```
❌ 禁止：scan → fix1 → scan → fix2 → scan → fix3 → scan
✅ 要求：scan → collect [fix1, fix2, fix3] → batch fix → scan → pass
```

最多 2 轮验证。第 2 轮仍不通过 → 列出剩余问题告知用户，不再循环。

---

## 策略 5：输出精简

- 阶段之间传递：只传 JSON 中间产物路径，不传代码文本
- 向用户输出：只输出「改了什么 + 文件路径:行号」，不复述代码块
- Review 结果：只列不通过项，已通过的不逐条打印
- 禁止在输出中重复打印已写入文件的完整代码

---

## 策略 6：hash + mtime 跳过

每个文件在 `file_digest.json` 中记录 content hash 和修改时间。下一阶段启动时：
- hash 未变且 mtime 未变 → 跳过，直接用摘要
- mtime 变了 → 重新读取 + 更新摘要和 hash

计算 hash 方式：前 50 字符 + 行数 + 最后 50 字符拼接。mtime 通过 `ls -l` 或 Bash 获取。

---

## 策略 7：写入前不重读

写文件前**不需要**再读一遍确认当前内容。直接基于已有摘要和本轮修改计划写入。

```
❌ 禁止：Read(file) → 确认内容 → Write(file)（多一次无意义的 Read）
✅ 要求：基于 digest 摘要 + task spec → 直接 Write(file)
```

例外：Edit 工具需要 old_string 精确匹配时，允许读取目标区域（分段读，不全量）。

---

## 策略 8：Grep 代替 Read 做存在性检查

确认某个函数、组件、import 是否存在时，用 Grep 而不是 Read 整个文件。

```
❌ 禁止：Read("aiAnalysis.js") → 肉眼找 toggleSubjectApi 是否存在
✅ 要求：Grep("toggleSubjectApi", path="aiAnalysis.js") → 有/无
```

适用场景：
- 检查某个 API 是否已在服务层定义
- 检查某个组件是否已被 import
- 检查某个 hook 是否已被调用
- 回测时验证功能点是否已实现

---

## 策略 9：并行工具调用

多个独立的 Grep/Glob/Read 操作，合并为一次并行调用，减少对话轮次。

```
❌ 禁止：
  Grep("toggleSubject") → 等结果
  Grep("saveTemplate") → 等结果
  Grep("selectTemplate") → 等结果

✅ 要求：一次性并行发出 3 个 Grep 调用
```

判断标准：如果多个查询之间没有依赖关系（后一个不需要前一个的结果），必须并行。

---

## 策略 10：禁止探索性读取

每次读取文件必须有明确目的。禁止"先看看这个文件有什么"的行为。

```
❌ 禁止：「让我看看 utils.js 里有什么」→ Read(utils.js)
✅ 要求：「需要确认 utils.js 是否有 hasDrillDownConfig 函数」→ Grep("hasDrillDownConfig", "utils.js")
```

合法的读取理由：
- 需要修改该文件（且摘要信息不足以完成修改）
- 需要提取该文件的结构信息生成摘要（首次扫描）
- 需要精确的代码上下文来写 Edit 的 old_string

不合法的读取理由：
- 好奇这个文件里有什么
- 想确认一下之前写的对不对（应该用 Grep 验证具体点）
- 没有明确目标的浏览
