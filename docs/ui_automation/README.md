# Hopp UI 自动化测试方案

> 本文档介绍 Hopp 的 UI 自动化测试方法。

## 推荐方案：UI 测试模式

### 概述

**UI 测试模式** 是 Hopp 内置的测试功能。当以 `--test-mode` 启动应用时，会启动一个 HTTP 指令服务器，接收测试指令并执行相应的 UI 操作。

### 架构

```
┌─────────────────────────────────────────────────────┐
│  测试客户端 (Python 脚本)                            │
│  - 发送 HTTP 指令                                    │
│  - 接收执行结果                                      │
│  - 截图验证                                         │
└────────────────┬────────────────────────────────────┘
                 │ HTTP POST
                 ▼
┌─────────────────────────────────────────────────────┐
│  Hopp 应用 (测试模式)                                │
│  ┌─────────────────────────────────────────────┐   │
│  │  UI 测试指令服务器 (随机端口)                  │   │
│  │  - 接收指令                                  │   │
│  │  - 操作 Flutter Provider 状态                │   │
│  │  - 返回执行结果                               │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 快速开始

#### 1. 启动应用（测试模式）

```bash
# 构建应用
fvm flutter build macos --debug

# 以测试模式启动
./build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp --test-mode
```

查看日志获取服务器端口：
```bash
tail -f ~/Library/Containers/com.example.hopp/Data/Library/Application\ Support/com.example.hopp/logs/hopp_$(date +%Y%m%d).log
```

#### 2. 执行测试

```bash
cd integration_test

# 完整测试流程
python3 test_client.py --port <PORT> full_test

# 单独指令
python3 test_client.py --port <PORT> create_request
python3 test_client.py --port <PORT> set_url --url https://httpbin.org/get
python3 test_client.py --port <PORT> send_request
python3 test_client.py --port <PORT> switch_response_tab --tab certificate
```

### 可用指令

| 指令 | 描述 | 示例 |
|------|------|------|
| `ping` | 测试连接 | `python test_client.py ping` |
| `create_request` | 创建新请求 | `python test_client.py create_request` |
| `set_url` | 设置 URL | `python test_client.py set_url --url https://api.example.com` |
| `set_method` | 设置 HTTP 方法 | `python test_client.py set_method --method POST` |
| `send_request` | 发送请求 | `python test_client.py send_request` |
| `switch_response_tab` | 切换响应 Tab | `python test_client.py switch_response_tab --tab certificate` |
| `add_header` | 添加 Header | `python test_client.py add_header --key "Content-Type" --value "application/json"` |
| `set_body` | 设置 Body | `python test_client.py set_body --body '{"test": 1}' --type json` |
| `get_response_info` | 获取响应信息 | `python test_client.py get_response_info` |
| `wait` | 等待 | `python test_client.py wait --ms 5000` |
| `close_tab` | 关闭 Tab | `python test_client.py close_tab` |
| `save_request` | 保存请求 | `python test_client.py save_request` |
| `full_test` | 完整测试 | `python test_client.py full_test` |

### 实现文件

| 文件 | 描述 |
|------|------|
| `lib/utils/testing/ui_test_mode.dart` | 测试模式核心实现 |
| `integration_test/test_client.py` | Python 测试客户端 |
| `lib/utils/testing/test_helpers.dart` | 测试辅助工具（语义标签、Keys） |

---

## 备选方案：Flutter Integration Test

用于在开发过程中进行快速的 Widget 级别测试。

### 运行测试

```bash
# 运行所有集成测试
fvm flutter test integration_test/

# 运行特定测试
fvm flutter test integration_test/advanced_ui_test.dart
```

### 测试文件

| 文件 | 描述 |
|------|------|
| `integration_test/advanced_ui_test.dart` | 高级 UI 交互测试 |
| `integration_test/http_request_test.dart` | HTTP 请求 E2E 测试 |
| `integration_test/http_service_e2e_test.dart` | HTTP 服务 E2E 测试 |

---

## 测试辅助工具

### 语义标签和 Keys

为了方便测试，关键 Widget 应该添加语义标签和 Keys：

```dart
// 添加 Key
IconButton(
  key: Key(TestKeys.sendButton),
  tooltip: 'Send Request',
  icon: Icon(Icons.send),
  onPressed: _sendRequest,
)

// 添加语义标签
TextField(
  decoration: InputDecoration(
    labelText: 'URL',
  ),
)
```

### 定义的 Keys

`lib/utils/testing/test_helpers.dart` 中定义了常用 Keys：

```dart
TestKeys.sendButton      // 发送按钮
TestKeys.urlInputField   // URL 输入框
TestKeys.saveButton      // 保存按钮
TestKeys.sidebar         // Sidebar
```

---

## 最佳实践

### 1. 日常开发
- 使用 **Flutter Integration Test** 验证 Widget 行为
- 快速反馈，无需启动完整应用

### 2. 集成测试
- 使用 **UI 测试模式** 验证完整功能流程
- 测试真实应用，最接近用户实际使用

### 3. 添加新功能时的测试步骤
1. 为关键 Widget 添加 Keys 和语义标签
2. 在 `ui_test_mode.dart` 中添加新指令（如需要）
3. 在 `test_client.py` 中添加客户端方法
4. 编写测试脚本验证功能

---

## 故障排除

### 测试服务器未启动

检查日志：
```bash
tail -50 ~/Library/Containers/com.example.hopp/Data/Library/Application\ Support/com.example.hopp/logs/hopp_$(date +%Y%m%d).log
```

### 无法连接到服务器

1. 确认应用以 `--test-mode` 启动
2. 检查防火墙设置
3. 确认端口未被占用

### 指令执行失败

1. 检查指令参数是否正确
2. 查看应用日志获取详细错误信息
3. 确认 UI 状态是否符合预期（如是否有活动的请求 Tab）

---

**最后更新**: 2026-03-12
