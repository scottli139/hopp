# 快捷键支持实现计划

> 创建时间: 2026-03-12  
> 完成时间: 2026-03-12 ✅  
> 目标: 实现常用操作快捷键，配合 Peekaboo 自动化测试

---

## 一、需求分析

### 1.1 目标快捷键

| 快捷键 | 功能 | 使用场景 | Peekaboo 测试命令 |
|--------|------|----------|-------------------|
| `Cmd+N` | 新建请求 | 创建新标签页 | `peekaboo hotkey "cmd,n"` |
| `Cmd+Enter` | 发送请求 | 发送当前请求 | `peekaboo hotkey "cmd,return"` |
| `Cmd+S` | 保存请求 | 保存到集合 | `peekaboo hotkey "cmd,s"` |
| `Cmd+W` | 关闭标签 | 关闭当前请求 | `peekaboo hotkey "cmd,w"` |
| `Cmd+Shift+S` | 另存为 | 保存到新集合 | `peekaboo hotkey "cmd,shift,s"` |
| `Cmd+1/2/3...` | 切换标签 | 快速切换请求 | `peekaboo hotkey "cmd,1"` |

### 1.2 测试验证方式

使用 Peekaboo 进行端到端测试：

```bash
#!/bin/bash
# shortcuts_test.sh

echo "=== 测试 Cmd+N 新建请求 ==="
peekaboo hotkey "cmd,n" --app hopp
peekaboo sleep 1000
screencapture -x /tmp/test_new_request.png

# 验证截图中是否出现新标签

echo "=== 测试 Cmd+Enter 发送请求 ==="
peekaboo type "https://httpbin.org/get" --app hopp
peekaboo hotkey "cmd,return" --app hopp
peekaboo sleep 3000
screencapture -x /tmp/test_send_request.png

# 验证截图中是否出现响应
```

---

## 二、技术方案

### 2.1 Flutter 快捷键实现

使用 `Shortcuts` + `Actions` 系统：

```dart
// 1. 定义 Intent
class NewRequestIntent extends Intent {}
class SendRequestIntent extends Intent {}
class SaveRequestIntent extends Intent {}
class CloseTabIntent extends Intent {}

// 2. 定义 Action
class NewRequestAction extends Action<NewRequestIntent> {
  @override
  void invoke(NewRequestIntent intent) {
    // 创建新请求
  }
}

// 3. 注册 Shortcuts
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): 
      NewRequestIntent(),
  },
  child: Actions(
    actions: {
      NewRequestIntent: NewRequestAction(),
    },
    child: child,
  ),
)
```

### 2.2 快捷键作用范围

- **全局快捷键**: Cmd+N (新建), Cmd+数字 (切换标签)
- **请求编辑器快捷键**: Cmd+Enter (发送), Cmd+S (保存)

---

## 三、实现步骤

### Step 1: 创建快捷键服务
- [x] 创建 `lib/services/shortcut_service.dart`
- [x] 定义所有 Intent 类
- [x] 定义所有 Action 类
- [x] 提供 Shortcuts 配置

### Step 2: 集成到 MainScreen
- [x] 在 `MainScreen` 包裹 `Shortcuts` widget
- [x] 绑定 Action 到具体业务逻辑
- [x] 处理快捷键冲突

### Step 3: 测试验证
- [x] 使用 Peekaboo 测试 Cmd+N
- [x] 使用 Peekaboo 测试 Cmd+Enter
- [x] 使用 Peekaboo 测试 Cmd+S
- [x] 验证截图结果

---

## 四、开发-测试循环

```
实现 Cmd+N → 启动 Hopp → Peekaboo 测试 Cmd+N → 截图验证 → 
实现 Cmd+Enter → 重启 Hopp → Peekaboo 测试 Cmd+Enter → 截图验证 → 
...
```

每个功能实现后立即用 Peekaboo 验证，确保：
1. 快捷键触发正确
2. UI 响应正确
3. 截图可用于后续回归测试

---

## 五、实际成果 ✅

1. ✅ 6 个常用快捷键已实现：
   - `Cmd+N` - 新建请求
   - `Cmd+Enter` - 发送请求
   - `Cmd+S` - 保存请求
   - `Cmd+W` - 关闭标签
   - `Cmd+Shift+S` - 另存为
   - `Cmd+1/2/3...` - 切换标签
2. ✅ macOS 系统菜单集成 (AppDelegate.swift + MethodChannel)
3. ✅ Peekaboo 测试脚本可稳定运行
4. ✅ UI 测试模式支持快捷键验证
5. ✅ 已更新开发文档

---

*实现完成 - 2026-03-12*
