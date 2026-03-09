# 🐰 Hopp

> 轻量级、跨平台的 API 请求测试工具，Postman 的开源替代品

English | [简体中文](./README.zh-CN.md)

[![CI](https://github.com/scottli139/hopp/actions/workflows/ci.yml/badge.svg)](https://github.com/scottli139/hopp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tauri](https://img.shields.io/badge/Tauri-2.x-blue?logo=tauri)](https://tauri.app)
[![React](https://img.shields.io/badge/React-18.x-61DAFB?logo=react)](https://react.dev)
[![AI Powered](https://img.shields.io/badge/AI%20Powered-Kimi-orange?logo=artificial-intelligence)](https://www.moonshot.cn)

**🤖 100% AI 开发** — 前端 [Kimi Code CLI](https://www.moonshot.cn/) · 后端 [Kimi 2.5 Model](https://www.moonshot.cn/)

## 📸 场景展示

### 发送 HTTP 请求
```
┌─────────────────────────────────────────────────────────────┐
│  📁 Sidebar  │  Request Tab Bar                              │
│  ┌────────┐ │  ┌─────┐┌─────┐┌─────┐┌─+─┐                  │
│  │ History│ │  │ GET ││ POST││ 🗙 ││   │                  │
│  ├────────┤ │  └──┬──┘└─────┘└─────┘└───┘                  │
│  │ ⭐     │ │     │                                         │
│  │Favorites│ │  ┌──┴────────────────────────────────────┐   │
│  ├────────┤ │  │ [GET] https://api.example.com/users │ ▶  │   │
│  │ 📂     │ │  └────────────────────────────────────────┘   │   │
│  │Collection│ │  [Params] [Headers] [Body] [Auth]            │   │
│  └────────┘ │                                             │   │
│             │  Response: 200 OK | 234ms | 1.2KB           │   │
│             │  {                                         │   │
│             │    "id": 1,                                │   │
│             │    "name": "John Doe"                      │   │
│             │  }                                         │   │
└─────────────────────────────────────────────────────────────┘
```

### 管理请求集合
- 📁 创建文件夹组织请求
- ⭐ 收藏常用请求
- 🕐 自动保存请求历史
- 📤 导入/导出 Postman 集合

### 环境变量
```
Environment: Production
├─ baseUrl: https://api.production.com
├─ apiKey: sk_live_xxx
└─ version: v2
```

### WebSocket 测试
- 🔌 支持 ws/wss 协议
- 📨 实时消息收发
- 📜 消息历史记录

## ✨ 特性

| 特性 | 描述 | 状态 |
|------|------|------|
| 🚀 **轻量快速** | 基于 Tauri 构建，启动 < 2s，内存 < 200MB | ✅ |
| 💻 **跨平台** | 支持 macOS、Windows、Linux | ✅ |
| 🎨 **精美界面** | 现代化 UI，支持深色/浅色主题 | ✅ |
| 🔧 **完整功能** | HTTP/HTTPS、WebSocket、环境变量、集合 | ✅ |
| 📦 **数据管理** | 本地 SQLite 存储，Postman 导入/导出 | ✅ |
| 🔒 **隐私安全** | 数据本地存储，不上传云端 | ✅ |
| ⚡ **高性能** | Rust 后端，响应迅速 | ✅ |
| 🌍 **多语言** | 支持简体中文和英语 | ✅ |

## 🚀 快速开始

### 下载安装

从 [Releases](https://github.com/scottli139/hopp/releases) 下载对应平台的安装包：

| 平台 | 下载 |
|------|------|
| macOS (Apple Silicon) | `Hopp_0.1.0_aarch64.dmg` |
| macOS (Intel) | `Hopp_0.1.0_x64.dmg` |
| Windows | `Hopp_0.1.0_x64-setup.exe` |
| Linux | `Hopp_0.1.0_amd64.AppImage` |

### 使用指南

1. **发送请求** - 输入 URL，选择 HTTP 方法，点击发送
2. **管理集合** - 在侧边栏创建文件夹，右键保存请求
3. **环境变量** - 创建环境配置，在 URL/Headers 中使用 `{{variable}}`
4. **WebSocket** - 切换到 WebSocket 标签，输入 ws/wss URL 连接
5. **语言切换** - 在设置中切换中文/英文界面

## 🛠️ 开发环境

### 前置要求

- [Node.js](https://nodejs.org/) 18+
- [Rust](https://www.rust-lang.org/) 1.75+
- [pnpm](https://pnpm.io/) 8+

```bash
# 验证环境
node --version    # v18+
rustc --version   # 1.75+
pnpm --version    # 8+
```

### 本地开发

```bash
# 1. 克隆仓库
git clone https://github.com/scottli139/hopp.git
cd hopp

# 2. 安装依赖
pnpm install

# 3. 启动开发服务器
pnpm tauri dev

# 4. 运行测试
pnpm test:unit      # 单元测试
pnpm test:e2e       # E2E 测试

# 5. 构建生产版本
pnpm tauri build
```

### 项目脚本

```bash
# 代码检查
pnpm lint           # ESLint 检查
pnpm lint:fix       # ESLint 自动修复
pnpm format         # Prettier 格式化
pnpm type-check     # TypeScript 类型检查
pnpm check          # 运行所有检查

# 测试
pnpm test:unit      # 单元测试
pnpm test:unit:coverage  # 单元测试 + 覆盖率
pnpm test:e2e       # E2E 测试

# 构建
pnpm dev            # 开发模式
pnpm build          # 构建前端
pnpm tauri build    # 构建桌面应用
```

## 🏗️ 技术栈

```
Frontend                    Backend
─────────────────────────────────────────
React 18        ←──────→    Rust 1.75+
TypeScript 5.x              Tauri 2.x
Vite 5.x                    Tokio
Tailwind CSS                Reqwest
Radix UI                    SQLite
Zustand                     thiserror
i18next                     -
```

## 📚 文档

| 文档 | 描述 |
|------|------|
| [需求规格说明书](./docs/PRD.md) | 功能需求详细说明 |
| [架构设计文档](./docs/ARCHITECTURE.md) | 技术架构与模块设计 |
| [开发计划](./docs/DEVELOPMENT_PLAN.md) | 里程碑与任务规划 |
| [代码规范](./docs/CODING_STANDARDS.md) | 编码规范与最佳实践 |
| [测试方案](./docs/TESTING.md) | 自动化测试策略 |
| [开发环境](./docs/DEVELOPMENT_ENVIRONMENT.md) | 环境搭建指南 |

## 🤝 贡献指南

我们欢迎所有形式的贡献！

```bash
# 1. Fork 本仓库
# 2. 创建功能分支
git checkout -b feature/amazing-feature

# 3. 提交更改
git commit -m "feat: add amazing feature"

# 4. 推送分支
git push origin feature/amazing-feature

# 5. 创建 Pull Request
```

请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解详细信息。

### 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/)：

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/依赖

## 📅 路线图

- [x] M1: 基础框架 (v0.1.0)
- [ ] M2: 数据管理 (v0.2.0) - 集合、历史记录
- [ ] M3: 环境变量 (v0.3.0) - 环境、Cookie、主题
- [ ] M4: 高级功能 (v0.4.0) - WebSocket、代码生成
- [ ] M5: 发布准备 (v1.0.0) - 测试、文档、签名

查看 [BACKLOG.md](./docs/BACKLOG.md) 了解未来计划。

## 📄 许可证

[MIT License](./LICENSE) © 2024 Hopp Contributors

## 🙏 致谢

- [Tauri](https://tauri.app/) - 构建跨平台桌面应用的框架
- [React](https://react.dev/) - 用户界面库
- [Radix UI](https://www.radix-ui.com/) - 无样式 UI 组件
- [Reqwest](https://docs.rs/reqwest/) - Rust HTTP 客户端
- [i18next](https://www.i18next.com/) - 国际化框架

---

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/scottli139">Hopp Team</a></sub>
  <br>
  <sub>🐰 Hop to your APIs!</sub>
</p>
