# 🐰 Hopp

> Lightweight, cross-platform API testing tool built with Flutter

[简体中文](./README.zh-CN.md) | English

[![CI](https://github.com/scottli139/hopp/actions/workflows/ci.yml/badge.svg)](https://github.com/scottli139/hopp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.x-0175C2?logo=dart)](https://dart.dev)
[![AI Powered](https://img.shields.io/badge/AI%20Powered-Kimi-orange?logo=artificial-intelligence)](https://www.moonshot.cn)

**🤖 100% AI Developed** — Built with [Kimi Code CLI](https://www.moonshot.cn/) · Powered by [Kimi 2.5 Model](https://www.moonshot.cn/)

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

---

## 📝 License

[MIT License](./LICENSE)

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
