# 🐰 Hopp

> Lightweight, cross-platform API testing tool, an open-source alternative to Postman

[简体中文](./README.zh-CN.md) | English

[![CI](https://github.com/scottli139/hopp/actions/workflows/ci.yml/badge.svg)](https://github.com/scottli139/hopp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tauri](https://img.shields.io/badge/Tauri-2.x-blue?logo=tauri)](https://tauri.app)
[![React](https://img.shields.io/badge/React-18.x-61DAFB?logo=react)](https://react.dev)
[![AI Powered](https://img.shields.io/badge/AI%20Powered-Kimi-orange?logo=artificial-intelligence)](https://www.moonshot.cn)

**🤖 100% AI Developed** — Frontend by [Kimi Code CLI](https://www.moonshot.cn/) · Backend by [Kimi 2.5 Model](https://www.moonshot.cn/)

## 📸 Screenshots

### Sending HTTP Requests
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

### Managing Request Collections
- 📁 Create folders to organize requests
- ⭐ Bookmark frequently used requests
- 🕐 Automatically save request history
- 📤 Import/Export Postman collections

### Environment Variables
```
Environment: Production
├─ baseUrl: https://api.production.com
├─ apiKey: sk_live_xxx
└─ version: v2
```

### WebSocket Testing
- 🔌 Support for ws/wss protocols
- 📨 Real-time message sending/receiving
- 📜 Message history records

## ✨ Features

| Feature | Description | Status |
|---------|-------------|--------|
| 🚀 **Lightweight & Fast** | Built with Tauri, starts in < 2s, memory < 200MB | ✅ |
| 💻 **Cross-Platform** | Supports macOS, Windows, Linux | ✅ |
| 🎨 **Beautiful UI** | Modern UI with dark/light theme support | ✅ |
| 🔧 **Full-Featured** | HTTP/HTTPS, WebSocket, environment variables, collections | ✅ |
| 📦 **Data Management** | Local SQLite storage, Postman import/export | ✅ |
| 🔒 **Privacy & Security** | Data stored locally, no cloud upload | ✅ |
| ⚡ **High Performance** | Rust backend for fast response | ✅ |
| 🌍 **Multi-Language** | Supports English and Simplified Chinese | ✅ |

## 🚀 Quick Start

### Download & Install

Download the appropriate package for your platform from [Releases](https://github.com/scottli139/hopp/releases):

| Platform | Download |
|----------|----------|
| macOS (Apple Silicon) | `Hopp_0.1.0_aarch64.dmg` |
| macOS (Intel) | `Hopp_0.1.0_x64.dmg` |
| Windows | `Hopp_0.1.0_x64-setup.exe` |
| Linux | `Hopp_0.1.0_amd64.AppImage` |

### User Guide

1. **Send Requests** - Enter URL, select HTTP method, click send
2. **Manage Collections** - Create folders in sidebar, right-click to save requests
3. **Environment Variables** - Create environment configs, use `{{variable}}` in URL/Headers
4. **WebSocket** - Switch to WebSocket tab, enter ws/wss URL to connect
5. **Language** - Switch between English and Chinese in settings

## 🛠️ Development Environment

### Prerequisites

- [Node.js](https://nodejs.org/) 18+
- [Rust](https://www.rust-lang.org/) 1.75+
- [pnpm](https://pnpm.io/) 8+

```bash
# Verify environment
node --version    # v18+
rustc --version   # 1.75+
pnpm --version    # 8+
```

### Local Development

```bash
# 1. Clone repository
git clone https://github.com/scottli139/hopp.git
cd hopp

# 2. Install dependencies
pnpm install

# 3. Start development server
pnpm tauri dev

# 4. Run tests
pnpm test:unit      # Unit tests
pnpm test:e2e       # E2E tests

# 5. Build production version
pnpm tauri build
```

### Project Scripts

```bash
# Code checks
pnpm lint           # ESLint check
pnpm lint:fix       # ESLint auto-fix
pnpm format         # Prettier formatting
pnpm type-check     # TypeScript type check
pnpm check          # Run all checks

# Testing
pnpm test:unit      # Unit tests
pnpm test:unit:coverage  # Unit tests + coverage
pnpm test:e2e       # E2E tests

# Building
pnpm dev            # Development mode
pnpm build          # Build frontend
pnpm tauri build    # Build desktop app
```

## 🏗️ Tech Stack

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

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Requirements Specification](./docs/PRD.md) | Detailed functional requirements |
| [Architecture Design](./docs/ARCHITECTURE.md) | Technical architecture & module design |
| [Development Plan](./docs/DEVELOPMENT_PLAN.md) | Milestones & task planning |
| [Coding Standards](./docs/CODING_STANDARDS.md) | Coding standards & best practices |
| [Testing Strategy](./docs/TESTING.md) | Automated testing strategy |
| [Development Environment](./docs/DEVELOPMENT_ENVIRONMENT.md) | Environment setup guide |

## 🤝 Contributing

We welcome all forms of contributions!

```bash
# 1. Fork this repository
# 2. Create feature branch
git checkout -b feature/amazing-feature

# 3. Commit changes
git commit -m "feat: add amazing feature"

# 4. Push branch
git push origin feature/amazing-feature

# 5. Create Pull Request
```

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation update
- `style`: Code formatting
- `refactor`: Refactoring
- `perf`: Performance optimization
- `test`: Testing related
- `chore`: Build/dependencies

## 📅 Roadmap

- [x] M1: Basic Framework (v0.1.0)
- [ ] M2: Data Management (v0.2.0) - Collections, history
- [ ] M3: Environment Variables (v0.3.0) - Environments, cookies, themes
- [ ] M4: Advanced Features (v0.4.0) - WebSocket, code generation
- [ ] M5: Release Preparation (v1.0.0) - Testing, documentation, signing

See [BACKLOG.md](./docs/BACKLOG.md) for future plans.

## 📄 License

[MIT License](./LICENSE) © 2024 Hopp Contributors

## 🙏 Acknowledgements

- [Tauri](https://tauri.app/) - Framework for building cross-platform desktop apps
- [React](https://react.dev/) - UI library
- [Radix UI](https://www.radix-ui.com/) - Unstyled UI components
- [Reqwest](https://docs.rs/reqwest/) - Rust HTTP client
- [i18next](https://www.i18next.com/) - Internationalization framework

---

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/scottli139">Hopp Team</a></sub>
  <br>
  <sub>🐰 Hop to your APIs!</sub>
</p>
