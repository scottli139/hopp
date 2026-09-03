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
| Flutter | 3.35.4（项目用 `.fvmrc` 锁定，见下文 FVM） |
| Dart | 3.9.2（随 Flutter SDK；`pubspec.yaml` 要求 `^3.6.2`，兼容满足） |

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
  "editor.rulers": [80],
  "dart.lineLength": 80,
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
    "**/*.g.dart": true,
    "**/*.mocks.dart": true
  }
}
```

> 行宽说明：项目未在 `analysis_options.yaml` 自定义 `formatter.page_width`，
> `dart format` 使用默认 80 列（CI 的 Format check 与 pre-push hook 均按此执行），
> 因此 `dart.lineLength` 必须保持 80，否则本地保存会产生与 CI 冲突的格式差异。

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

### 6. 配置 Git Hooks（pre-push 格式检查）

仓库自带 `.githooks/pre-push`，在 `git push` 前自动执行与 CI 完全一致的格式检查
（`dart format --output=none --set-exit-if-changed lib/ test/`），避免 CI 的
Format check 失败。每个 clone 只需启用一次：

```bash
git config core.hooksPath .githooks
```

Hook 优先使用 `.fvm/flutter_sdk` 锁定的 SDK 自带 dart（与 CI 的 Flutter 3.35.4
格式化行为一致），不依赖 `fvm` 在 PATH 中，GUI Git 客户端同样生效。
检查失败时运行 `fvm dart format lib/ test/` 修复后重新提交即可。

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

**问题**：`CocoaPods not installed`（常见于 Homebrew Ruby 升级到 4.0 后，`pod` 因缺默认 gem 无法启动）

**解决**（无 sudo、装到用户目录，2026-08-20 实测可用）：

```bash
# 1. 安装 CocoaPods 到用户 gem 目录
gem install --user-install cocoapods --no-document

# 2. Ruby 4.0 移除了若干默认 gem，CocoaPods 依赖它们，需一并补装
gem install --user-install base64 drb bigdecimal logger mutex_m ostruct csv benchmark securerandom rexml nkf --no-document

# 3. 构建时把用户 gem 目录接到 PATH/GEM_*
UGD=$(gem env user_gemhome)
export PATH="$UGD/bin:$PATH"
export GEM_HOME="$UGD"
export GEM_PATH="$UGD"
fvm flutter build macos --release
```

> 备选：`sudo gem install cocoapods` 或 `brew install cocoapods`（会写系统目录，需 sudo/网络；若仍报缺 gem，同样按第 2 步补装默认 gem）。

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

### 7. Linux 界面频繁闪白/闪黑

**现象**：窗口在滚动、动画、切换主题时整窗闪一下（ARM64 + Mesa 软渲染环境）。

**原因**：llvmpipe 与 Flutter 按区域重绘配合有缺陷，半绘制帧被送出；非应用代码问题。

**解决**：用引擎自带软件渲染器启动，绕开 GL（详见「平台特定配置 → Linux → ARM64 与软件渲染」）：

```bash
FLUTTER_LINUX_RENDERER=software fvm flutter run -d linux
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

#### ARM64 与软件渲染（华为擎云等国产 ARM 设备，2026-09 实测）

ARM64 Linux（鲲鹏/麒麟等）与 x86_64 有几处差异，按顺序处理：

**1. Flutter SDK**：官方 releases 只有 x64 Linux SDK（`releases_linux.json` 中无 arm64），需用社区 ARM64 构建（如 [flutter-native-arm64](https://github.com/MohamedAlkindi/flutter-native-arm64)）。项目自 2026-09-03 起锁定 **3.35.4**（该社区构建有对应版本，本机与 CI 完全一致）；`intl` 已在 `pubspec.yaml` 升到 `^0.20.2`（3.35 的 flutter_localizations 固定 0.20.2），无需任何 override。

**2. linux-arm64 引擎产物**：国内镜像 `storage.flutter-io.cn` 不同步 linux-arm64 引擎产物（403）。构建时**不要**设置 `FLUTTER_STORAGE_BASE_URL`，默认走 `storage.googleapis.com`（国内实测可达）；`PUB_HOSTED_URL=https://pub.flutter-io.cn` 包镜像不受影响。

**3. 系统依赖**：与 x64 相同（`clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`）。

**4. GPU / 渲染（关键）**：国产 ARM 整机常配 Mali GPU，但厂商 libmali 只提供 GLES 配置，Flutter 桌面端需要桌面 GL，直接启动会 FATAL（`glGetString(GL_VERSION) failed`）。两条路：

- Mesa llvmpipe 软渲染可跑（GLVND + `LIBGL_ALWAYS_SOFTWARE=1`），但与 Flutter 的按区域重绘配合有缺陷：重绘量大的窗口会把**半绘制帧**送显，表现为界面频繁闪白/闪黑（滚动、动画、切主题时尤甚）。
- **推荐：引擎自带软件渲染器，完全绕开 GL**。启动加 `FLUTTER_LINUX_RENDERER=software`，无闪烁、无 GPU 依赖，对本应用（无视频/着色器）无功能损失。

```bash
# 直接运行构建产物
FLUTTER_LINUX_RENDERER=software ./build/linux/arm64/debug/bundle/hopp

# 开发期
FLUTTER_LINUX_RENDERER=software fvm flutter run -d linux
```

> 任务栏图标：Deepin 的 GTK3 补丁会使 `gtk_window_set_icon` 不生效（任务栏显示 X 占位图标）。runner 已内置 X11 手动写 `_NET_WM_ICON`（见 `linux/runner/my_application.cc` 的 `set_window_icon`），各 Linux 发行版通用，无需额外配置。
>
> 中文字体：社区 ARM64 引擎通常未编译 fontconfig（无 `SkFontMgr_fontconfig`，退回 `SkFontMgr_New_Custom_Directory` 目录扫描，其逐字符回退是空操作），界面中文会显示为方块。应用已在主题层显式声明 CJK 回退链（`lib/theme/app_text_styles.dart` 的 `kAppFontFamilyFallback` / `kAppCodeFontFamilyFallback`，经 `ThemeData(fontFamilyFallback:)` 全局生效），系统装有常见 CJK 字体（Noto Sans CJK / 思源黑体等）即可正常显示，macOS / Windows / x64 Linux 行为不变（同名家族不存在时自动跳过，退回系统回退）。

**5. 本机 SDK 与 CI 版本一致性（2026-09-03 起已对齐）**：ARM64 曾被迫用社区 3.35.4 与 CI 锁定的 3.27.4 错位开发（官方 Linux SDK 只有 x64）；2026-09-03 起 CI 与 `.fvmrc` 统一升到 3.35.4，错位消除。留档两条经验教训：

- **dart format 按 language version 选风格**：Dart 3.7 起 formatter 改为 tall style，但只作用于 language version ≥ 3.7 的代码。本项目 `pubspec.yaml` sdk 约束为 `^3.6.2`（language version 3.6），实测 Dart 3.9.2 与 3.6.2 的 `dart format` 对 `lib/` `test/` 输出逐字节一致；**哪天把 sdk 约束升到 3.7+，全仓会被 tall style 重排，须单独成 commit**。
- **Color API 代差**：`Color.toARGB32()` 是 Flutter 3.29+ 新增；旧 `Color.value` 已 deprecated，warning 会让 `flutter analyze --no-fatal-infos` 失败。写颜色转换用 `.r/.g/.b` 通道（如 `(c.r * 255).round()`）或 `toARGB32()`，`lib/services/title_bar_sync.dart` 的 `_hex()` 即前者。

**6. deb 打包**（ARM64 / x64 通用，架构自动识别）：

```bash
# 一条命令：release 构建 + 组装 + dpkg-deb，产物在 build/deb/
FLUTTER=/path/to/flutter ./scripts/build_deb.sh

# 安装 / 卸载
sudo dpkg -i build/deb/hopp_<version>_arm64.deb
sudo dpkg -r hopp
```

安装内容：`/usr/lib/hopp/`（release bundle）、`/usr/bin/hopp`（wrapper，内置 `FLUTTER_LINUX_RENDERER=software`）、`/usr/share/applications/hopp.desktop`（桌面快捷方式，`StartupWMClass` 与 `linux/CMakeLists.txt` 的 `APPLICATION_ID` 一致）、hicolor 图标。打包定义在 `packaging/linux/`（control / desktop / wrapper）。

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

仓库没有独立的检查脚本，提交前按顺序执行以下三项（与 CI 一致）：

```bash
# 1. 格式检查（配置 pre-push hook 后，git push 时会自动执行该项，见上文）
fvm dart format --output=none --set-exit-if-changed lib/ test/

# 2. 静态分析
fvm dart analyze

# 3. 全部测试
fvm flutter test
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
