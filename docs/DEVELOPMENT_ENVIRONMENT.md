# 开发环境搭建指南

## 系统要求

### macOS
- macOS 10.15+
- Xcode Command Line Tools

### Windows
- Windows 10+
- Visual Studio C++ Build Tools

### Linux
```bash
sudo apt install libwebkit2gtk-4.0-dev build-essential libssl-dev libgtk-3-dev
```

## 安装依赖

### 1. Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustc --version  # 1.75+
```

### 2. Node.js
```bash
fnm install 20 && fnm use 20
node --version  # v20+
```

### 3. pnpm
```bash
corepack enable
corepack prepare pnpm@latest --activate
```

## 项目设置

```bash
git clone https://github.com/scottli139/hopp.git
cd hopp
pnpm install
pnpm tauri dev
```

## 常用命令

```bash
# 开发
pnpm dev              # 启动前端 dev server
pnpm tauri dev        # 启动 Tauri 应用

# 代码检查
pnpm lint             # ESLint
pnpm format           # Prettier
pnpm type-check       # TypeScript
pnpm check            # 所有检查

# 测试
pnpm test:unit        # 单元测试
pnpm test:e2e         # E2E 测试

# 构建
pnpm tauri build      # 构建桌面应用
```
