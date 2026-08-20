# 🐰 Hopp

> Local-first, private AI API workbench — keep your data on your machine

[简体中文](./README.zh-CN.md) | English

[![CI](https://github.com/scottli139/hopp/actions/workflows/ci.yml/badge.svg)](https://github.com/scottli139/hopp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.x-0175C2?logo=dart)](https://dart.dev)
[![AI Powered](https://img.shields.io/badge/AI%20Powered-Kimi%20K3%20%26%20DeepSeek-orange?logo=artificial-intelligence)](https://www.moonshot.cn)

**🤖 100% AI Developed** — Built with [Kimi Code CLI](https://www.moonshot.cn/) · Powered by [Kimi K3](https://www.moonshot.cn/) & [DeepSeek V4 Pro](https://platform.deepseek.com/)

**Positioning** — not a Postman clone: Hopp puts AI convenience on top of local API tooling, private by default.

---

## ✨ Features

- 🔥 **Lightweight & Fast** - Native performance with Flutter
- 🖥️ **Cross-Platform** - macOS, Windows, Linux
- 📝 **Request Editor** - Support for Params, Headers, Body (JSON, Form, Text)
- 🗂️ **Collections** - Organize requests into folders
- 📑 **Multiple Tabs** - Work with multiple requests simultaneously
- 🌓 **Dark Mode** - Support for light/dark/system themes
- 🌍 **Internationalization** - English and Chinese support
- 📊 **Response Viewer** - View response body, headers, and timing information
- 🔒 **HTTPS Certificate** - View SSL/TLS certificate details
- ⏱️ **Timing Analysis** - DNS, TCP, TLS, TTFB, Download time breakdown
- ⚡ **Optimized Display** - Virtualized rendering for large responses (>50KB)
- ⌨️ **Keyboard Shortcuts** - Cmd+N, Cmd+Enter, Cmd+S, Cmd+W, etc.
- 🧪 **UI Test Mode** - Built-in HTTP command server for automated testing

---

## 🧭 Direction

Hopp is moving from "another Postman clone" to a **local-first, private AI workbench**:

- **Environment variables** — reusable `{{var}}` with scopes (global > environment > local)
- **Pre-request chain + variable transforms** — login → token, password sha1/aes encryption, declarative (no JS sandbox)
- **Three-tier AI** — Tier 0 deterministic (OpenAPI/Swagger file or URL import), Tier 1 local model (Ollama/LM Studio), Tier 2 BYOK cloud (opt-in)
- **Lightweight assertions + CLI** — status/header/body/JSONPath, AI-generated, `hopp run` for CI

> Status: planned — see [PRD](docs/PRD.md) and [FEATURE_UI_DESIGN](docs/FEATURE_UI_DESIGN.md).

---

## 🚀 Quick Start

### Prerequisites

- [Flutter](https://flutter.dev/) 3.27+
- [FVM](https://fvm.app/) (recommended for version management)
- [Dart](https://dart.dev/) 3.6+

### Development

```bash
# Clone the repository
git clone https://github.com/scottli139/hopp.git
cd hopp

# Install FVM (if not installed)
dart pub global activate fvm

# Use project Flutter version
fvm use

# Install dependencies
fvm flutter pub get

# Run development
fvm flutter run -d macos
```

#### China Mirror Setup

For developers in mainland China, configure Flutter mirrors:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### Build

```bash
# Build for macOS
fvm flutter build macos --release

# Build for Windows
fvm flutter build windows --release

# Build for Linux
fvm flutter build linux --release
```

---

## 🏗️ Architecture

```
hopp/
├── lib/
│   ├── models/          # Data models (Freezed + Hive)
│   ├── providers/       # Riverpod state management
│   ├── services/        # HTTP & Storage services
│   ├── widgets/         # UI components
│   ├── screens/         # App screens
│   ├── utils/           # Utilities
│   └── l10n/            # Localization
├── macos/               # macOS platform code
├── windows/             # Windows platform code
├── linux/               # Linux platform code
├── test/                # Unit tests
└── docs/                # Documentation
```

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.27.x, Dart 3.6+
- **State Management**: Riverpod 2.x
- **HTTP Client**: Dio 5.x
- **Local Storage**: Hive + SharedPreferences
- **UI Components**: Material Design 3
- **Code Generation**: Freezed, json_serializable
- **Testing**: Mockito, integration_test, Peekaboo

---

## 📝 License

[MIT License](./LICENSE)

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details, and be respectful of our [Code of Conduct](./CODE_OF_CONDUCT.md).

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
