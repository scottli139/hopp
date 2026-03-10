# Hopp 开发环境搭建指南

> 本文档介绍如何配置 Flutter 开发环境，适用于 macOS、Windows 和 Linux 平台。

---

## 📋 目录

- [系统要求](#系统要求)
- [环境配置](#环境配置)
- [IDE 配置](#ide-配置)
- [项目设置](#项目设置)
- [常见问题](#常见问题)

---

## 系统要求

### 最低配置

| 组件 | 要求 |
|-----|------|
| 操作系统 | macOS 10.15+ / Windows 10+ / Ubuntu 20.04+ |
| 内存 | 8 GB RAM |
| 磁盘空间 | 10 GB 可用空间 |
| Flutter | 3.27.0+ |
| Dart | 3.6.0+ |

### 推荐配置

| 组件 | 推荐 |
|-----|------|
| 内存 | 16 GB RAM |
| 磁盘空间 | 20 GB SSD |
| Flutter | 最新稳定版 |

---

## 环境配置

### 1. 安装 FVM (推荐)

[FVM](https://fvm.app/) 用于管理 Flutter 版本，确保团队使用一致的 Flutter 版本。

```bash
# 安装 FVM
dart pub global activate fvm

# 验证安装
fvm --version
```

### 2. 配置 Flutter 镜像 (中国大陆用户)

由于网络原因，中国大陆用户需要配置国内镜像。

#### macOS / Linux

编辑 `~/.zshrc` 或 `~/.bashrc`：

```bash
# Flutter 中国社区镜像 (推荐)
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 或者使用上海交通大学镜像
# export PUB_HOSTED_URL=https://mirror.sjtu.edu.cn/dart-pub
# export FLUTTER_STORAGE_BASE_URL=https://mirror.sjtu.edu.cn

# 或者使用清华大学 TUNA 镜像
# export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
# export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
```

使配置生效：

```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

#### Windows

PowerShell:

```powershell
# 临时设置（当前会话）
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# 永久设置（用户环境变量）
[Environment]::SetEnvironmentVariable("PUB_HOSTED_URL", "https://pub.flutter-io.cn", "User")
[Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", "https://storage.flutter-io.cn", "User")
```

### 3. 安装 Flutter SDK

```bash
# 使用 FVM 安装项目指定的 Flutter 版本
cd hopp
fvm install

# 验证安装
fvm flutter --version
```

### 4. 安装 IDE

#### VS Code (推荐)

1. 下载并安装 [VS Code](https://code.visualstudio.com/)

2. 安装扩展：
   - Flutter (Dart Code)
   - Dart (Dart Code)
   - Riverpod Snippets
   - Bracket Pair Colorizer
   - Error Lens

3. 配置 VS Code：

创建 `.vscode/settings.json`：

```json
{
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.rulers": [80, 120],
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    }
  },
  "files.exclude": {
    "**/.dart_tool": true,
    "**/.packages": true,
    "**/build": true,
    "**/*.freezed.dart": true,
    "**/*.g.dart": true
  }
}
```

创建 `.vscode/launch.json`：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "hopp (macOS)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["-d", "macos"]
    },
    {
      "name": "hopp (Windows)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["-d", "windows"]
    },
    {
      "name": "hopp (Linux)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["-d", "linux"]
    }
  ]
}
```

#### Android Studio / IntelliJ IDEA

1. 下载并安装 [Android Studio](https://developer.android.com/studio)

2. 安装插件：
   - Flutter
   - Dart

---

## 项目设置

### 1. 克隆项目

```bash
git clone https://github.com/scottli139/hopp.git
cd hopp
```

### 2. 配置 FVM

```bash
# 使用项目指定的 Flutter 版本
fvm use

# 验证
fvm flutter --version
```

### 3. 安装依赖

```bash
# 使用 FVM 运行 flutter pub get
fvm flutter pub get

# 生成代码（Freezed、Riverpod 等）
fvm dart run build_runner build --delete-conflicting-outputs
```

### 4. 运行项目

```bash
# macOS
fvm flutter run -d macos

# Windows
fvm flutter run -d windows

# Linux
fvm flutter run -d linux

# 查看可用设备
fvm flutter devices
```

### 5. 运行测试

```bash
# 运行所有测试
fvm flutter test

# 运行特定测试文件
fvm flutter test test/models/http_request_test.dart

# 运行测试并生成覆盖率报告
fvm flutter test --coverage
```

---

## 常见问题

### 1. Flutter 命令找不到

**问题**：`flutter: command not found`

**解决**：

```bash
# 确保 FVM 在 PATH 中
export PATH="$HOME/.pub-cache/bin:$PATH"

# 或使用 fvm 的 flutter
fvm flutter --version
```

### 2. 依赖下载失败

**问题**：`Could not resolve package`

**解决**：

```bash
# 1. 检查网络连接和镜像配置
echo $PUB_HOSTED_URL
echo $FLUTTER_STORAGE_BASE_URL

# 2. 清除缓存
fvm flutter clean
rm -rf pubspec.lock

# 3. 重新获取依赖
fvm flutter pub get
```

### 3. 代码生成失败

**问题**：`Could not find generator`

**解决**：

```bash
# 1. 确保依赖已安装
fvm flutter pub get

# 2. 运行 build_runner
fvm dart run build_runner build --delete-conflicting-outputs

# 3. 或者使用 watch 模式（开发时自动重新生成）
fvm dart run build_runner watch --delete-conflicting-outputs
```

### 4. macOS 构建失败

**问题**：`CocoaPods not installed`

**解决**：

```bash
# 安装 CocoaPods
sudo gem install cocoapods

# 或者使用 Homebrew
brew install cocoapods
```

### 5. Windows 构建失败

**问题**：`Visual Studio not installed`

**解决**：

1. 安装 [Visual Studio 2022](https://visualstudio.microsoft.com/)
2. 安装 "Desktop development with C++" 工作负载

### 6. Linux 构建失败

**问题**：缺少依赖库

**解决**：

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Fedora
sudo dnf install -y clang cmake ninja-build pkgconfig gtk3-devel xz-devel

# Arch
sudo pacman -S clang cmake ninja pkgconf gtk3 xz
```

---

## 平台特定配置

### macOS

```bash
# 安装 Xcode Command Line Tools
xcode-select --install

# 同意 Xcode 许可协议
sudo xcodebuild -license accept

# 配置 CocoaPods
cd macos
pod install
cd ..
```

### Windows

1. 启用开发者模式
2. 安装 Visual Studio 2022 with C++
3. 安装 Windows 10 SDK

### Linux

```bash
# 启用桌面支持
fvm flutter config --enable-linux-desktop
```

---

## 开发工作流

### 日常开发命令

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 安装依赖（如果有更新）
fvm flutter pub get

# 3. 生成代码（如果有模型更新）
fvm dart run build_runner build --delete-conflicting-outputs

# 4. 运行应用
fvm flutter run -d macos

# 5. 运行测试
fvm flutter test

# 6. 格式化代码
fvm dart format lib/

# 7. 静态分析
fvm dart analyze
```

### 提交代码前检查

```bash
# 运行完整检查脚本
./scripts/pre_commit.sh
```

---

## 参考资源

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 官方文档](https://dart.dev/guides)
- [FVM 文档](https://fvm.app/documentation/)
- [Flutter 中国社区](https://flutter.cn/)

---

## 获取帮助

如果遇到问题：

1. 查看 [Flutter 官方文档](https://docs.flutter.dev/)
2. 搜索 [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
3. 在 GitHub Issues 中提问
