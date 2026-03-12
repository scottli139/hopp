# Hopp - Peekaboo 自动化测试指南

> 本文档记录如何使用 Peekaboo CLI 自动化测试 Hopp API 客户端

## 环境准备

### 1. 安装 Peekaboo CLI

```bash
# 使用 Homebrew 安装
brew install peekaboo

# 验证安装
peekaboo --version
```

### 2. 启动 Hopp 应用

```bash
# 开发版本
/Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp &

# 或生产版本
open /Applications/hopp.app
```

## 快速开始

### 运行完整测试套件

```bash
cd /Volumes/hagibis1t/huicom/github/postman/integration_test/peekaboo

# 运行完整测试
./run_full_test.sh

# 运行单个测试
./test_basic_request.sh
```

## 可用菜单命令

### File 菜单
| 命令 | 功能 | Peekaboo 调用 |
|------|------|--------------|
| New Request | 创建新请求 | `peekaboo menu click --app "hopp" --path "File > New Request"` |
| New Collection | 创建新集合 | `peekaboo menu click --app "hopp" --path "File > New Collection"` |
| Save | 保存请求 | `peekaboo menu click --app "hopp" --path "File > Save"` |
| Save As... | 另存为 | `peekaboo menu click --app "hopp" --path "File > Save As..."` |
| Close Tab | 关闭标签 | `peekaboo menu click --app "hopp" --path "File > Close Tab"` |

### Edit 菜单
| 命令 | 功能 | Peekaboo 调用 |
|------|------|--------------|
| Send Request | 发送请求 | `peekaboo menu click --app "hopp" --path "Edit > Send Request"` |

## 测试脚本详解

### 1. 基本请求测试

```bash
#!/bin/bash

# 确保应用在前台
peekaboo app switch --to "hopp"
sleep 1

# 创建新请求（使用默认 URL: https://httpbin.org/get）
peekaboo menu click --app "hopp" --path "File > New Request"
sleep 2

# 发送请求
peekaboo menu click --app "hopp" --path "Edit > Send Request"
sleep 5

# 截图验证
screencapture -x /tmp/test_result.png
```

### 2. 多标签页测试

```bash
#!/bin/bash

# 创建多个请求
for i in {1..3}; do
    peekaboo menu click --app "hopp" --path "File > New Request"
    sleep 1
done

# 截图验证多个标签页
screencapture -x /tmp/test_multiple_tabs.png
```

### 3. 保存和关闭测试

```bash
#!/bin/bash

# 创建并保存请求
peekaboo menu click --app "hopp" --path "File > New Request"
sleep 1
peekaboo menu click --app "hopp" --path "File > Save"
sleep 1

# 关闭标签
peekaboo menu click --app "hopp" --path "File > Close Tab"
```

## 验证方法

### 1. 日志验证

日志文件位置：
```
~/Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs/hopp_YYYYMMDD.log
```

查看日志：
```bash
LOG_FILE="$HOME/Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs/hopp_$(date +%Y%m%d).log"
tail -50 "$LOG_FILE"
```

### 2. 截图验证

所有测试脚本都会自动截图保存到 `/tmp/` 目录：
- `/tmp/test_result.png` - 测试结果
- `/tmp/test_flow_1.png` - 流程步骤1
- `/tmp/test_flow_2.png` - 流程步骤2

## 已知限制

### 1. URL 输入限制
Flutter 的 TextField 无法被 Peekaboo 直接识别和输入。解决方案：
- **方案1**: 修改默认 URL（已实施：`https://httpbin.org/get`）
- **方案2**: 手动输入 URL 进行测试
- **方案3**: 未来添加 "Set URL" 菜单项

### 2. 快捷键限制
Flutter 的 `Shortcuts` widget 无法接收 Peekaboo 模拟的键盘事件。解决方案：
- 使用 **macOS 系统菜单** 触发操作（已实施）
- 不依赖快捷键进行自动化测试

## 故障排除

### 问题1: 菜单项不存在

**错误**: `Error: Menu item not found`

**解决**: 
1. 确保 Hopp 应用已启动
2. 检查应用是否有焦点
```bash
peekaboo app switch --to "hopp"
```

### 问题2: 应用无响应

**错误**: 应用无法启动或崩溃

**解决**:
1. 清理 Hive 数据库锁文件
```bash
rm -f ~/Library/Containers/com.example.hopp/Data/Documents/hopp/*.lock
```
2. 重新启动应用

### 问题3: 请求发送失败

**现象**: 显示连接错误

**检查**:
1. 确认网络连接正常
2. 检查日志中的详细错误信息
3. 验证 httpbin.org 是否可访问

## 测试清单

### 基础功能测试
- [ ] 启动应用
- [ ] 创建新请求
- [ ] 发送请求
- [ ] 查看响应
- [ ] 保存请求
- [ ] 关闭标签

### 菜单功能测试
- [ ] File > New Request
- [ ] File > New Collection
- [ ] File > Save
- [ ] File > Save As...
- [ ] File > Close Tab
- [ ] Edit > Send Request

### 响应验证测试
- [ ] HTTP 200 OK
- [ ] 响应时间显示
- [ ] 响应大小显示
- [ ] JSON 响应格式化
- [ ] Headers 显示

## 持续集成

### GitHub Actions 示例

```yaml
name: Peekaboo E2E Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Peekaboo
        run: brew install peekaboo
      
      - name: Build app
        run: flutter build macos --debug
      
      - name: Run E2E tests
        run: |
          ./build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp &
          sleep 5
          ./integration_test/peekaboo/run_full_test.sh
```

## 参考文档

- [Peekaboo CLI 文档](https://peekaboo.dev/docs)
- [Flutter 集成测试](https://docs.flutter.dev/testing/integration-tests)
- [macOS 辅助功能](https://developer.apple.com/documentation/accessibility)

---

**最后更新**: 2026-03-12
**测试版本**: Hopp v0.1.0
**Peekaboo 版本**: v3.0.0-beta3
