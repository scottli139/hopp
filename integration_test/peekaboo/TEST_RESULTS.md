# 测试运行记录

## 2026-03-12 - 首次完整测试

### 环境
- macOS: 15.x
- Hopp: v0.1.0 (Debug)
- Peekaboo: v3.0.0-beta3

### 测试结果
| 测试项目 | 状态 | 备注 |
|---------|------|------|
| 基本请求测试 | ✅ 通过 | 创建请求、发送、响应正常 |
| 多标签页测试 | ✅ 通过 | 创建多个标签页正常 |
| 保存集合测试 | ✅ 通过 | 保存功能正常 |

### 已验证功能
1. ✅ File > New Request (Cmd+N)
2. ✅ File > New Collection (Cmd+Shift+N)
3. ✅ File > Save (Cmd+S)
4. ✅ File > Save As... (Cmd+Shift+S)
5. ✅ File > Close Tab (Cmd+W)
6. ✅ Edit > Send Request (Cmd+Enter)

### 已知限制
- Flutter TextField 无法通过 Peekaboo 直接输入
- 快捷键模拟不工作（使用菜单替代）
- 解决方案：修改默认 URL 为 httpbin.org/get

### 截图示例
- test_flow_1.png: 创建请求后状态
- test_flow_2.png: 收到 200 OK 响应
