# 开发环境搭建指南

本文档指导您搭建 Hopp 的本地开发环境。

---

## 📋 系统要求

### macOS

- macOS 10.15 (Catalina) 或更高版本
- Xcode Command Line Tools

```bash
# 安装 Xcode Command Line Tools
xcode-select --install
```

### Windows

- Windows 10 或更高版本
- Microsoft Visual Studio C++ Build Tools
- WebView2 Runtime

```powershell
# 安装 Visual Studio Build Tools（包含在 Visual Studio 中）
# 或使用 winget
winget install Microsoft.VisualStudio.2022.BuildTools

# WebView2 Runtime 通常已预装在 Windows 10/11
```

### Linux

- 主流发行版 (Ubuntu 20.04+, Fedora 35+, Arch)
- 开发工具链

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev

# Fedora
sudo dnf install webkit2gtk4.1-devel openssl-devel curl wget file libappindicator-gtk3-devel librsvg2-devel

# Arch Linux
sudo pacman -S webkit2gtk base-devel curl wget file openssl appindicator-gtk3 librsvg
```

---

## 🛠️ 安装依赖

### 1. 安装 Rust

```bash
# 使用 rustup 安装
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 激活环境
source $HOME/.cargo/env

# 验证安装
rustc --version  # 需要 1.75+
cargo --version
```

### 2. 安装 Node.js

推荐使用 [nvm](https://github.com/nvm-sh/nvm) 或 [fnm](https://github.com/Schniz/fnm) 管理 Node.js 版本。

```bash
# 使用 fnm (推荐)
curl -fsSL https://fnm.vercel.app/install | bash
fnm install 20
fnm use 20

# 验证安装
node --version  # v20.x
npm --version
```

### 3. 安装 pnpm

```bash
# 使用 corepack (Node.js 16.10+ 内置)
corepack enable
corepack prepare pnpm@latest --activate

# 或使用 npm
npm install -g pnpm

# 验证安装
pnpm --version
```

---

## 🚀 项目设置

### 1. 克隆仓库

```bash
git clone https://github.com/scottli139/hopp.git
cd hopp
```

### 2. 安装项目依赖

```bash
# 安装前端依赖
pnpm install

# Rust 依赖会在第一次构建时自动安装
```

### 3. 配置 Git 提交模板

```bash
# 设置提交模板
git config commit.template .gitmessage

# 可选：设置全局编辑器
git config --global core.editor "code --wait"
```

### 4. 配置 Git Hooks (husky)

```bash
# 初始化 husky
pnpm prepare
```

---

## 💻 开发工作流

### 启动开发服务器

```bash
# 同时启动前端 dev server 和 Tauri 应用
pnpm tauri dev

# 应用将在 http://localhost:1420 启动
# 修改前端代码会自动热重载
# 修改 Rust 代码会自动重新编译
```

### 常用命令

```bash
# 前端开发
pnpm dev              # 仅启动前端 dev server
pnpm build            # 构建前端生产版本

# 代码检查
pnpm lint             # ESLint 检查
pnpm lint:fix         # ESLint 自动修复
pnpm format           # Prettier 格式化
pnpm format:check     # Prettier 格式检查
pnpm type-check       # TypeScript 类型检查
pnpm check            # 运行所有检查

# 测试
pnpm test:unit        # 单元测试
pnpm test:unit:coverage # 单元测试 + 覆盖率报告
pnpm test:e2e         # E2E 测试
pnpm test:e2e:ui      # E2E 测试 (UI 模式)

# Tauri
pnpm tauri build      # 构建生产版本
pnpm tauri dev        # 开发模式

# Rust (在 src-tauri 目录下)
cd src-tauri
cargo build           # 构建
cargo run             # 运行
cargo test            # 测试
cargo clippy          # 代码检查
cargo fmt             # 格式化
```

---

## 🐛 调试

### 前端调试

1. 在 VS Code 中打开项目
2. 按 `F5` 或点击 Run → Start Debugging
3. 选择 "Debug Vitest Tests" 或浏览器调试配置

### Rust 调试

1. 在 Rust 代码中设置断点
2. 按 `F5` 或点击 Run → Start Debugging
3. 选择 "Debug Tauri (Development)"

### 查看日志

```bash
# 前端控制台日志
# 在应用内按 Ctrl+Shift+I (Windows/Linux) 或 Cmd+Option+I (macOS)

# Rust 日志
RUST_LOG=debug pnpm tauri dev
```

---

## 📝 代码提交

### 提交前检查

提交代码前会自动运行：

1. ESLint 检查
2. Prettier 格式化
3. rustfmt 格式化
4. Clippy 检查

### 手动运行检查

```bash
# 所有检查
pnpm check

# Rust 检查
cd src-tauri
cargo fmt -- --check
cargo clippy -- -D warnings
```

---

## 🔧 常见问题

### 端口冲突

如果 1420 端口被占用：

```bash
# 设置环境变量使用其他端口
export TAURI_DEV_PORT=3000
pnpm tauri dev
```

### Rust 编译失败

```bash
# 清理缓存
cd src-tauri
cargo clean

# 重新构建
cargo build
```

### 前端依赖问题

```bash
# 删除并重新安装
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### macOS: "无法验证开发者"

```bash
# 开发构建未签名，需要在系统偏好设置中允许
# 系统设置 -> 隐私与安全性 -> 安全性 -> 允许
```

### Windows: WebView2 错误

```bash
# 安装 WebView2 Runtime
winget install Microsoft.EdgeWebView2Runtime
```

---

## 📚 推荐阅读

- [Tauri 文档](https://tauri.app/v1/guides/)
- [React 文档](https://react.dev/)
- [Rust 文档](https://www.rust-lang.org/learn)
- [项目代码规范](./CODING_STANDARDS.md)

---

## 💬 获取帮助

遇到问题？

1. 查看 [Issues](https://github.com/scottli139/hopp/issues)
2. 创建新的 Issue，使用 "question" 标签
3. 查看 [讨论区](https://github.com/scottli139/hopp/discussions)
