# zlj_mht 项目规范

本规范基于目标项目自动生成，包含技术栈、目录结构、ESLint 规则、团队编码约束。

---

## 技术栈

| 分类 | 规范 |
|------|------|
| 框架 | React 16.14，页面级组件用 Class Component |
| 语言 | JSX（非 TSX） |
| 样式 | `.less` 文件，BEM 命名，与组件同目录 |
| UI 库 | antd 4.24 + @ant-design/pro-components 1.1.25 |
| 图表 | echarts 5.6，通过 `import * as echarts from 'echarts'` 引入 |
| 路由 | umi 3.5，使用 `history.push` / `match.params` |
| 请求 | `@zz/fetch` 4.0.8，服务层放 `@/services/report/aiAnalysis.js` |
| 状态管理 | 新代码优先 Zustand，存量可用 `useModel` |
| 路径别名 | `@/` 指向 `src/` |
| 包管理器 | pnpm，私有源 `https://rcnpm.zhuanspirit.com` |

---

## 目录结构

```
pages/report/aiAnalysis/
├── HqSubjectsPage/          # Hq 角色主题列表页
│   └── index.jsx
├── UserSubjectsPage/        # User 角色主题列表页
│   └── index.jsx
├── HqSubjectDetailPage/     # Hq 角色主题详情页
│   └── index.jsx
├── UserSubjectDetailPage/   # User 角色主题详情页
│   └── index.jsx
├── HqTemplateDetailPage/    # Hq 角色模板详情页
│   └── index.jsx
├── UserTemplateDetailPage/  # User 角色模板详情页
│   └── index.jsx
├── components/
│   ├── common/              # 通用组件（无业务依赖）
│   │   ├── StatusTag/
│   │   ├── SaveButton/
│   │   ├── SectionHeader/
│   │   ├── AIInsightPanel/
│   │   ├── VizRenderer/
│   │   ├── PageHeader/
│   │   ├── CardGrid/
│   │   ├── ModalFooter/
│   │   ├── SelectableCard/
│   │   └── StatusToggleField/
│   └── business/            # 业务组件（含业务逻辑）
│       ├── SubjectCard/
│       ├── TemplateCard/
│       ├── TemplateHero/
│       ├── ComponentCard/
│       ├── ComponentPicker/
│       ├── DrillDownDrawer/
│       ├── DrillConfigModal/
│       ├── HQEditor/
│       ├── SubjectModal/
│       └── TemplateModal/
├── hooks/
│   ├── useSubjectsList.js
│   ├── useSubjectDetail.js
│   ├── useTemplateDetail.js
│   ├── useSaveState.js
│   ├── useModalState.js
│   ├── useToggleStatus.js
│   ├── useArrayMove.js
│   └── useTextareaInsert.js
├── styles/                  # 共享样式
│   ├── subjects.less
│   ├── subjectDetail.less
│   └── templateDetail.less
└── utils/
    ├── utils.js
    └── tableHelpers.js
```

---

## 组件规范

### 组件分类

- **页面组件**（`*Page`）：Class Component，只做组合，不含业务逻辑
- **业务组件**（`business/`）：函数组件或 Class Component，通过 props 控制 user/hq 模式差异，禁止重复实现两套 UI
- **通用组件**（`common/`）：函数组件，无业务依赖，可跨模块复用
- **Hooks**：函数式，消除跨组件重复逻辑

### 组件文件夹命名

- 大驼峰：`SubjectCard/`、`TemplateCard/`、`ComponentCard/`
- 文件夹内只有两个文件：`index.jsx` + `index.less`
- 组件使用 `export default` 导出

### 引用方式

```js
import SubjectCard from '../components/business/SubjectCard'
import StatusTag from '../components/common/StatusTag'
```

---

## 服务层规范

```js
// @/services/report/aiAnalysis.js
import request from '@/utils/request.js'

export async function getSubjectListApi(params) {
  return request.get('/getSubjectList', params, { moduleName: 'aiAnalysis' })
}
```

---

## 样式规范

- 每个组件的样式写在同级 `index.less`
- 在 `index.jsx` 中 `import './index.less'`
- BEM 命名：`.subject-card__title`、`.subject-card--disabled`
- 禁止内联样式，除非动态计算值

---

## ESLint 硬性规则（error 级别）

从 `.eslintrc.js` 提取的强制规则：

| 规则 | 配置 | 说明 |
|------|------|------|
| `indent` | `['error', 2, { SwitchCase: 1 }]` | 2 空格缩进，switch case 1 空格 |
| `space-before-function-paren` | `['error', 'never']` | 函数括号前不加空格 |
| `comma-dangle` | `['error', 'never']` | 禁止拖尾逗号 |
| `complexity` | `['error', 15]` | 单函数圈复杂度 ≤ 15 |
| `@zz-common/nested-complexity/complexity` | `['error']` | 嵌套复杂度检查 |
| `no-undef` | `'error'` | 不能有未定义的变量 |

---

## CLAUDE.md 团队编码约束

以下内容引用自 `/Users/zz/Desktop/zlj_mht/CLAUDE.md`：

### 核心原则

1. **复用优先**：写代码前先搜索项目中是否已有类似实现
2. **组件库优先**：优先使用 ProComponents > Ant Design > 业务自定义
3. **简单直接**：遵循 KISS 原则，避免过度设计
4. **类型安全**：TypeScript 严格模式，禁止使用 `any`（本项目为 JSX，但仍需注意类型注释）
5. **质量红线**：单文件 < 1000 行，圈复杂度 < 15，注释密度 > 10%

### 依赖版本规则

**不要假设或硬编码任何库的版本号。**

开始任何编码任务前，必须先读取当前项目根目录的 `package.json`，以其中 `dependencies` 和 `devDependencies` 中声明的版本为准。

### 转转内部库

| 能力 | 包 / 约定 | 要求 |
|------|----------|------|
| HTTP | `@zz/fetch` 或本仓库 `request` 封装 | 走统一层，勿再叠一套平行客户端 |
| 登录 / 权限 | `@zz-common/zz-permission`，`getInitialState`，`@umijs/plugin-access` | 沿用本仓库既有接入 |
| zant-ui | `@zz-common/zant-ui` | 仅强业务组件优先用 |
| 错误上报 | `@zz-common/sentry` | 已接入则与存量用法一致 |
| 工具 | `@zz-common/zz-utils` | 编写前先查是否已有 |

### 双轨升级策略（兼容存量）

- 新代码优先：ahooks `useRequest` + ProComponents `request` + Zustand
- 存量代码兼容：useModel/dva + ahooks `useRequest` + umi-request
- 不强制一次性迁移，按功能迭代逐步替换

### 规范未覆盖时的决策原则

- 优先参考**同文件或同目录的存量代码风格**，保持局部一致性
- 其次参考**项目内同类页面**（如已有列表页的实现方式）
- 若仍无参考，按规范精神推断：可维护性 > 简洁性 > 新技术偏好

---

## 角色模式规范

本项目采用 Hq/User 双角色独立页面设计：

- **Hq 角色**：总部管理员，有编辑权限，页面名带 `Hq` 前缀（如 `HqSubjectsPage`）
- **User 角色**：普通用户，只读权限，页面名带 `User` 前缀（如 `UserSubjectsPage`）
- **业务组件**：通过 `isHq` prop 控制权限差异，不重复实现两套 UI

示例：

```jsx
function SubjectCard({ subject, isHq, onClick, onEdit }) {
  return (
    <div className="ai-subject-card">
      {isHq && <StatusTag type={subject.status} />}
      {isHq && onEdit && <Button onClick={onEdit}>编辑</Button>}
    </div>
  )
}
```

---

## 路由与维度切换

- 通过路由参数 `dimensionId` 实现维度切换
- 使用自定义 hook `useDimensionId(pathname)` 从路径提取维度 ID
- 页面路径格式：`/report/aiAnalysis/subjects/:dimensionId`

---

## 禁止事项

- 禁止使用内联样式（除非动态计算值）
- 禁止在组件内直接写 API 请求，必须通过服务层
- 禁止硬编码业务数据（如状态枚举、配置项），应提取为常量
- 禁止在循环/条件中使用 Hooks
- 禁止使用 `any` 类型（如果是 TS 项目）
- 禁止跳过 ESLint 规则（`eslint-disable`），除非有充分理由并注释说明

---

## 补充约束

（用户首次配置时可在此追加额外约束）
