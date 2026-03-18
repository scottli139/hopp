# Tauri 技术栈归档（历史参考）

> 本文档记录 Hopp 项目从 Tauri 技术栈迁移到 Flutter 之前的技术决策和配置，供历史参考。

---

## 技术栈对比：Flutter vs Tauri

**为什么从 Tauri 迁移到 Flutter？**

| 因素 | Flutter | Tauri |
|------|---------|-------|
| 技术栈 | Dart 单一语言 | TypeScript + Rust |
| 桌面支持 | 成熟稳定 | 较新 |
| UI 一致性 | 自绘引擎，完全一致 | 依赖系统 WebView |
| 性能 | AOT 编译接近原生 | WebView 开销 |
| 热重载 | 优秀 | 较慢 |
| 移动端扩展 | 无缝支持 | 不支持 |

---

## 原技术栈 (Tauri)

| 功能 | 技术 |
|------|------|
| UI 框架 | React 18 |
| 编程语言 | TypeScript + Rust |
| 状态管理 | Zustand |
| HTTP 客户端 | Axios + reqwest |
| 本地存储 | localStorage + SQLite |
| 国际化 | i18next |
| 构建工具 | Vite |

---

## 为什么选择 Tauri 而不是 Electron?

- **包体积小**: Tauri ~5MB vs Electron ~100MB+
- **内存占用低**: 使用系统 WebView
- **安全性**: Rust 后端提供内存安全
- **性能**: 原生 Rust 代码执行效率高

---

## 前端状态管理选择 Zustand

- 轻量级，无需 Provider 包裹
- TypeScript 支持好
- 中间件生态丰富
- API 简洁

---

## 常见问题

### ESLint v10 Flat Config

```javascript
// eslint.config.mjs
import js from '@eslint/js';
import ts from 'typescript-eslint';

export default [
  js.configs.recommended,
  ...ts.configs.recommended,
];
```

### TypeScript React 类型导入

```typescript
// ❌ 不推荐
import React, { FC } from 'react';

// ✅ 推荐
import type { FC } from 'react';
import { useState } from 'react';
```

---

## 命令参考

```bash
# 开发
pnpm tauri dev
pnpm dev

# 测试
pnpm test:unit
pnpm test:e2e

# 构建
pnpm tauri build
```

---

## 迁移时间线

| 日期 | 事件 |
|------|------|
| 2026-03-10 | Flutter 迁移完成，全面替换 Tauri+React |

---

<p align="center">已归档 · 仅作历史参考</p>
