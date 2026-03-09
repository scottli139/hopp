# 代码规范与风格指南

## 核心原则

1. **可读性优先** - 代码是写给人看的
2. **显式优于隐式** - 避免魔法值、隐式转换
3. **DRY** - 提取重复逻辑
4. **单一职责** - 函数/组件只做一件事
5. **类型安全** - 充分利用 TypeScript 和 Rust 的类型系统

## 前端规范 (TypeScript/React)

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 组件目录 | kebab-case | `request-editor/` |
| 组件文件 | PascalCase | `RequestEditor.tsx` |
| 工具函数 | camelCase | `formatDate.ts` |
| 自定义 Hook | camelCase (use 前缀) | `useRequest.ts` |

### 组件规则

```typescript
// ✅ 正确示例
import { FC, useCallback, useState } from 'react';

interface RequestEditorProps {
  requestId: string;
  readOnly?: boolean;
  onSave?: (data: RequestData) => void;
}

export const RequestEditor: FC<RequestEditorProps> = ({
  requestId,
  readOnly = false,
  onSave,
}) => {
  const [isLoading, setIsLoading] = useState(false);

  const handleSave = useCallback(() => {
    if (readOnly) return;
    // 保存逻辑
  }, [readOnly]);

  return <div>...</div>;
};
```

### TypeScript 规则

1. **严格模式开启** - `strict: true`
2. **禁止 any** - 特殊情况需注释说明
3. **显式返回类型** - 公共函数必须声明

## 后端规范 (Rust)

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 模块文件 | snake_case | `http_client.rs` |
| 结构体/枚举 | PascalCase | `HttpRequest` |
| 函数/变量 | snake_case | `send_request` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |

### 错误处理

```rust
#[derive(Debug, Error)]
pub enum AppError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("Not found: {entity} with id {id}")]
    NotFound { entity: String, id: String },
}
```

## 提交规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试
- `chore`: 构建/依赖
