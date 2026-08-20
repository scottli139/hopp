# 🐰 Hopp

> 轻量级、跨平台的 API 请求测试工具，Postman 的开源替代品

[English](./README.md) | 简体中文

[![CI](https://github.com/scottli139/hopp/actions/workflows/ci.yml/badge.svg)](https://github.com/scottli139/hopp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.x-0175C2?logo=dart)](https://dart.dev)
[![AI Powered](https://img.shields.io/badge/AI%20Powered-Kimi-orange?logo=artificial-intelligence)](https://www.moonshot.cn)

**🤖 100% AI 开发** — 由 [Kimi Code CLI](https://www.moonshot.cn/) 构建 · 基于 [Kimi 2.5 Model](https://www.moonshot.cn/)

---

## ✨ 特性

| 特性 | 描述 | 状态 |
|------|------|------|
| 🚀 **轻量快速** | 基于 Flutter 构建，原生性能体验 | ✅ |
| 💻 **跨平台** | 支持 macOS、Windows、Linux | ✅ |
| 🎨 **精美界面** | Material Design 3，支持深色/浅色主题 | ✅ |
| 🔧 **完整功能** | HTTP/HTTPS、Params、Headers、Body | ✅ |
| 📦 **数据管理** | 本地 Hive 存储，Collections 组织 | ✅ |
| 🔒 **隐私安全** | 数据本地存储，不上传云端 | ✅ |
| ⚡ **高性能** | Dart 原生编译，响应迅速 | ✅ |
| 🌍 **多语言** | 支持简体中文和英语 | ✅ |
| 🔐 **HTTPS 证书** | 查看 SSL/TLS 证书详情 | ✅ |
| ⏱️ **时间分析** | DNS、TCP、TLS、TTFB、Download 分段时间 | ✅ |
| 📄 **大响应优化** | 虚拟化渲染，支持 >50KB 响应 | ✅ |
| ⌨️ **快捷键** | Cmd+N、Cmd+Enter、Cmd+S、Cmd+W 等 | ✅ |
| 🧪 **UI 测试模式** | 内置 HTTP 指令服务器，支持自动化测试 | ✅ |

---

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
- 📤 导入/导出 Collections

---

## 🚀 快速开始

### 前置要求

- [Flutter](https://flutter.dev/) 3.27+
- [FVM](https://fvm.app/) (推荐用于版本管理)
- [Dart](https://dart.dev/) 3.6+

### 开发环境

```bash
# 进入项目目录
cd hopp

# 安装 FVM（如果尚未安装）
dart pub global activate fvm

# 使用项目指定的 Flutter 版本
fvm use

# 安装依赖
fvm flutter pub get

# 运行开发
fvm flutter run -d macos
```

#### 国内镜像配置

中国大陆开发者需要配置国内镜像以加速 Flutter 下载：

```bash
# 添加到 ~/.zshrc 或 ~/.bashrc
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 构建

```bash
# 构建 macOS 版本
fvm flutter build macos --release

# 构建 Windows 版本
fvm flutter build windows --release

# 构建 Linux 版本
fvm flutter build linux --release
```

---

## 🏗️ 架构

```
hopp/
├── lib/
│   ├── models/          # 数据模型 (Freezed + Hive)
│   ├── providers/       # Riverpod 状态管理
│   ├── services/        # HTTP & 存储服务
│   ├── widgets/         # UI 组件
│   ├── screens/         # 应用页面
│   ├── utils/           # 工具类
│   └── l10n/            # 国际化
├── macos/               # macOS 平台代码
├── windows/             # Windows 平台代码
├── linux/               # Linux 平台代码
├── test/                # 测试文件
└── docs/                # 文档
```

---

## 🛠️ 技术栈

- **框架**: Flutter 3.27.x, Dart 3.6+
- **状态管理**: Riverpod 2.x
- **HTTP 客户端**: Dio 5.x
- **本地存储**: Hive + SharedPreferences
- **UI 组件**: Material Design 3
- **代码生成**: Freezed, json_serializable
- **测试**: Mockito, integration_test, Peekaboo

---

## 📝 许可证

[MIT License](./LICENSE)

---

## 🤝 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解详情，并遵守我们的 [行为准则](./CODE_OF_CONDUCT.md)。

---

<p align="center">用 ❤️ 构建 · 由 Kimi 提供支持</p>
