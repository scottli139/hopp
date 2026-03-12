# Hopp Peekaboo 测试套件 - 文件索引

## 📚 文档

| 文件 | 描述 |
|------|------|
| README.md | 完整使用指南和参考文档 |
| INDEX.md | 本文件，快速导航 |
| TEST_RESULTS.md | 测试运行记录和结果 |

## 🧪 测试脚本

| 文件 | 描述 | 运行时间 |
|------|------|---------|
| run_full_test.sh | 运行所有测试 | ~30s |
| test_basic_request.sh | 基本请求流程测试 | ~15s |
| test_multiple_tabs.sh | 多标签页管理测试 | ~10s |
| test_save_collection.sh | 保存请求测试 | ~10s |
| quick_test.sh | 快速测试（创建+发送） | ~10s |

## 🛠️ 工具脚本

| 文件 | 描述 |
|------|------|
| view_logs.sh | 查看应用日志 |
| cleanup.sh | 清理测试环境 |
| Makefile | 便捷命令集合 |

## 🚀 快速命令参考

```bash
# 进入测试目录
cd /Volumes/hagibis1t/huicom/github/postman/integration_test/peekaboo

# 查看帮助
make help

# 运行测试
make test           # 完整测试套件
make quick          # 快速测试
make test-basic     # 仅基本测试

# 查看日志
make logs           # 实时日志
make logs-error     # 错误日志
make logs-menu      # 菜单日志
make logs-http      # HTTP 日志

# 环境管理
make clean          # 清理环境
make reset          # 重置数据
make app-start      # 启动应用
make app-stop       # 停止应用

# 单次操作
make new-request    # 创建新请求
make send-request   # 发送请求
make save-request   # 保存请求
make screenshot     # 截图
```

## 📝 Peekaboo 命令参考

### 菜单操作
```bash
# File 菜单
peekaboo menu click --app "hopp" --path "File > New Request"
peekaboo menu click --app "hopp" --path "File > New Collection"
peekaboo menu click --app "hopp" --path "File > Save"
peekaboo menu click --app "hopp" --path "File > Save As..."
peekaboo menu click --app "hopp" --path "File > Close Tab"

# Edit 菜单
peekaboo menu click --app "hopp" --path "Edit > Send Request"

# 列出所有菜单
peekaboo menu list --app "hopp"
```

### 应用控制
```bash
# 切换到应用
peekaboo app switch --to "hopp"

# 启动应用
peekaboo app launch "hopp"

# 停止应用
peekaboo app quit --app "hopp"
```

### UI 元素
```bash
# 查看 UI 元素
peekaboo see --app "hopp" --annotate --path /tmp/hopp_ui.png

# 点击坐标
peekaboo click --coords "x,y" --app "hopp"

# 输入文本
peekaboo type "text" --app "hopp"

# 按下快捷键
peekaboo hotkey --keys "cmd,n"
```

## 🔧 已知问题与解决

### 问题1: URL 输入框无法输入
**原因**: Flutter TextField 无法被 Peekaboo 识别
**解决**: 已修改默认 URL 为 `https://httpbin.org/get`

### 问题2: 快捷键不工作
**原因**: Flutter Shortcuts 不接收模拟键盘事件
**解决**: 使用 macOS 系统菜单替代

### 问题3: 应用启动失败（Hive 锁）
**原因**: 前一个实例未正确关闭
**解决**: 运行 `make clean` 或手动删除 `*.lock` 文件

## 📊 测试验证点

- [x] 菜单项可点击
- [x] 新请求创建成功
- [x] HTTP 请求发送成功
- [x] 响应显示正常（200 OK）
- [x] 多标签页创建正常
- [x] 保存功能正常
- [x] 日志记录完整

## 🎯 未来改进

1. 添加更多 HTTP 方法测试（POST, PUT, DELETE）
2. 添加请求 body 输入测试
3. 添加 header 编辑测试
4. 添加响应验证测试
5. 添加性能测试（大量请求）

---

**创建时间**: 2026-03-12
**维护者**: Kimi Code CLI
**版本**: v1.0
