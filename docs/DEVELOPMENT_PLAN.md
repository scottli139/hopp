# Hopp 开发计划与里程碑

> 本文档记录 Hopp 项目的开发计划、里程碑和任务进度。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | URL Focus 边框对齐修复完成，准备主题切换 |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | **418 个测试全部通过** ✅ |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | 73 | ✅ 通过 |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | 88 | ✅ 通过 |
| 响应优化组件测试 | 新增 | ✅ 通过 |
| UI 优化测试 | 新增 7 个 | ✅ 通过 |
| **总计** | **418** | **全部通过** |

---

## 📅 里程碑规划

### M1: 基础架构 ✅ COMPLETED (2026-03-10)

| 任务 | 状态 | 说明 |
|-----|------|------|
| FVM 环境配置 | ✅ | Flutter 3.27.4 + 国内镜像 |
| 项目结构搭建 | ✅ | 目录结构、依赖配置 |
| 代码规范配置 | ✅ | analysis_options.yaml |
| 核心模型定义 | ✅ | Freezed + Hive 模型 (7个) |
| 基础服务实现 | ✅ | HTTP、存储服务 |

**技术决策**:
- FVM 管理 Flutter 版本
- Riverpod 状态管理
- Dio HTTP 客户端
- Hive + SharedPreferences 存储

---

### M2: 核心功能 ✅ COMPLETED (2026-03-10)

| 任务 | 状态 | 说明 |
|-----|------|------|
| 侧边栏组件 | ✅ | Collection 树形结构 |
| 标签页管理 | ✅ | 多标签页支持 |
| 请求编辑器 | ✅ | Method/URL/Params/Headers/Body |
| 响应展示 | ✅ | Body/Headers/Status/Time/Size |
| HTTP 请求发送 | ✅ | Dio 封装，错误处理 |

**设计规范**:
- Material Design 3
- 可拖拽调整面板宽度
- 响应式布局

---

### M3: 用户体验 ✅ COMPLETED (2026-03-12)

#### M3.1 UI/UX 优化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| 数据一致性修复 | ✅ | P0 | dirtyRequestsProvider + 保存功能 |
| JSON 语法高亮 | ✅ | P1 | flutter_code_editor 集成 |
| 错误信息展示优化 | ✅ | P1 | 可展开错误条 |
| UI 字体优化 | ✅ | P1 | 统一 11-12px 字体系统 |
| 布局溢出修复 | ✅ | P0 | Sidebar/Response 区域 |

#### M3.2 品牌化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| macOS Dock 图标 | ✅ | P0 | AppIcon.icns (16-1024px) |
| About 对话框 Logo | ✅ | P0 | 兔子 logo |
| Sidebar Header Logo | ✅ | P0 | SVG logo |
| StatusBar Logo | ✅ | P0 | 兔子图标 |

#### M3.3 快捷键与 E2E 测试

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| Flutter Shortcuts | ✅ | P0 | Shortcuts + Actions |
| macOS 系统菜单 | ✅ | P0 | File/Edit 菜单 |
| MethodChannel 通信 | ✅ | P0 | Swift ↔ Dart |
| Peekaboo E2E 测试 | ✅ | P1 | 完整自动化测试套件 |

**快捷键**:
- `Cmd+N` - 新建请求
- `Cmd+Enter` - 发送请求
- `Cmd+S` - 保存请求
- `Cmd+W` - 关闭标签
- `Cmd+1-9` - 切换标签

#### M3.4 HTTPS 证书查看 (F1.11)

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| CertificateInfo 模型 | ✅ | P1 | 证书信息存储 |
| Certificate Tab UI | ✅ | P1 | Response 区域动态 Tab |
| 证书详情展示 | ✅ | P1 | Subject/Issuer/有效期/指纹 |
| 单元测试 | ✅ | P1 | 15个测试 |

#### M3.5 响应优化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| OptimizedResponseViewer | ✅ | P1 | 虚拟化大响应显示组件 |
| 多种显示模式 | ✅ | P1 | Auto/Performance/Full/Raw |
| 大响应自动切换 | ✅ | P1 | >50KB 自动切换 Performance 模式 |
| 轻量级 JSON 高亮 | ✅ | P1 | 性能模式下的语法高亮 |
| 虚拟化列表 | ✅ | P1 | 初始 500 行，支持加载更多 |
| UI 测试支持 | ✅ | P1 | 3 个测试指令 |

#### M3.6 请求时间分析 (Timing)

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| TimingInfo 模型 | ✅ | P1 | DNS/TCP/TLS/TTFB/Download 时间 |
| HttpResponse 扩展 | ✅ | P1 | 添加 timingInfo 字段 |
| HttpService 时间测量 | ✅ | P1 | 各阶段时间统计 |
| Timing Tab UI | ✅ | P1 | 总时间卡片、阶段详情、时间线 |
| UI 测试支持 | ✅ | P1 | timing 相关测试指令 |

**优化策略**:
| 响应大小 | 默认模式 | 说明 |
|---------|---------|------|
| < 10KB | Full | 完整语法高亮 |
| 10KB - 50KB | Full | 完整语法高亮 |
| > 50KB | Performance | 虚拟化列表，轻量高亮 |

#### M3.6 UI 细节优化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| Request Tab 样式 | ✅ | P1 | 高度 32px、选中状态增强 |
| +按钮功能修复 | ✅ | P0 | 正确创建新请求 |
| URL 输入框对齐 | ✅ | P1 | 垂直居中、统一边框样式 |
| URL Bar 高度统一 | ✅ | P1 | 36px → 32px，按钮统一 |
| Response Tab 优化 | ✅ | P1 | 字体 10px、高度 28px、添加图标 |
| Content Type 优化 | ✅ | P1 | 高度 32px → 28px |
| Sidebar 弹出菜单 | ✅ | P1 | 样式统一 |

#### M3.7 URL Bar 对齐修复

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| URL Bar 高度统一 36px | ✅ | P0 | Method下拉、URL输入框、按钮统一 |
| Focus 效果修复 | ✅ | P1 | 紫色边框显示正常 |
| 文字垂直居中 | ✅ | P1 | URL 文字在输入框内垂直居中 |

#### M3.8 URL Focus 边框对齐

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| Focus 边框对齐 | ✅ | P0 | 紫色边框与灰色背景区域完全对齐 |
| TextField 完全控制边框 | ✅ | P0 | 移除外层 Container 边框设置 |
| 高度一致性 | ✅ | P1 | URL 输入框与 Method 下拉框 36px |

---

### M4: 高级功能 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 请求名称编辑 | ✅ | **P0** | 4h | 右键菜单重命名 + UI 测试模式支持 |
| 大响应体渲染优化 | ✅ | **P0** | 6h | OptimizedResponseViewer 虚拟化显示 |
| UI 细节优化 | ✅ | P1 | 4h | Tab 样式、输入框对齐、按钮统一 |
| URL Bar 对齐修复 | ✅ | P0 | 2h | Method下拉、URL输入框、按钮统一36px |
| URL Focus 边框对齐 | ✅ | P0 | 2h | 修复紫色边框与背景区域高度不一致 |
| 主题切换 | 🔄 | P1 | 4h | Light/Dark 模式 |
| 国际化完善 | 🔄 | P1 | 6h | 多语言支持 |
| 请求时间分析 | ✅ | P1 | 10h | Timing Tab (DNS/TCP/TLS/TTFB/Download) |
| 收尾检查清单 | ✅ | P0 | 2h | 测试验证、代码规范、文档更新 |
| 请求详情展示 | ⏳ | P1 | 6h | Request Tab |
| 环境变量 | ⏳ | P1 | 12h | 变量替换和多环境 |
| 请求历史 | ⏳ | P2 | 8h | 请求历史记录 |
| 拖拽排序 | ⏳ | P2 | 6h | Collection 拖拽排序 |

---

### M5: 数据管理 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| Postman 导入/导出 | ⏳ | P1 | 12h |
| Insomnia 导入 | ⏳ | P2 | 8h |
| curl 导出 | ⏳ | P2 | 4h |
| 云端同步 | ⏳ | P3 | 20h |
| 团队协作 | ⏳ | P3 | 40h |

---

### M6: 测试与质量保障 ✅ COMPLETED

| 任务 | 状态 | 优先级 | 数量 |
|-----|------|--------|------|
| 单元测试 (Models) | ✅ | P0 | 152 个 |
| 单元测试 (Services) | ✅ | P0 | 73 个 |
| 单元测试 (Providers) | ✅ | P0 | 92 个 |
| Widget 测试 | ✅ | P1 | 88 个 |
| Peekaboo E2E 测试 | ✅ | P2 | 完整套件 |
| CI/CD 配置 | ✅ | P0 | GitHub Actions |

**E2E 测试套件** (`integration_test/peekaboo/`):
```bash
cd integration_test/peekaboo
make test   # 完整测试
make quick  # 快速测试
make logs   # 查看日志
```

---

## 🚀 发布计划

### v0.1.0 - Alpha ✅ CURRENT

- ✅ 基础 HTTP 请求
- ✅ Collection 管理
- ✅ 多标签页
- ✅ 基础 UI

### v0.2.0 - Beta ✅ COMPLETED (2026-03-11)

- ✅ 基础 HTTP 请求
- ✅ Collection 管理
- ✅ 多标签页
- ✅ 品牌化统一
- ✅ HTTPS 证书查看
- ✅ 快捷键支持
- ✅ 单元测试 (405个)

### v0.3.0 - Feature Complete ✅ COMPLETED (2026-03-13)

- ✅ 请求名称编辑
- ✅ UI 测试模式
- ✅ 响应优化 (大响应体虚拟化)
- ✅ UI 细节优化
- ✅ URL Bar 对齐修复
- ✅ URL Focus 边框对齐
- ✅ Widget 测试 (88个)
- ✅ 418 个测试全部通过

### v0.4.0 - RC 🔄 IN PROGRESS

- 🔄 主题切换
- 🔄 国际化
- ⏳ 请求历史
- ⏳ 环境变量
- ⏳ 导入/导出 (Postman/Insomnia/curl)
- ✅ Timing 分析
- ⏳ 请求详情展示

### v1.0.0 - GA ⏳ PLANNED

- ⏳ 完整功能集
- ⏳ 完善文档
- ⏳ 全平台稳定
- ⏳ 应用商店发布

---

## 🛠️ 技术栈

### 核心依赖

| 包名 | 版本 | 用途 |
|-----|------|------|
| flutter_riverpod | ^2.6.1 | 状态管理 |
| dio | ^5.8.0+1 | HTTP 客户端 |
| hive | ^2.2.3 | NoSQL 存储 |
| shared_preferences | ^2.5.2 | 配置存储 |
| freezed_annotation | ^2.4.4 | 不可变类生成 |
| multi_split_view | ^3.6.0 | 可拖拽分割面板 |
| flutter_code_editor | ^0.5.0 | 代码高亮 |

### 开发依赖

| 包名 | 版本 | 用途 |
|-----|------|------|
| build_runner | ^2.4.15 | 代码生成 |
| freezed | ^2.5.7 | 不可变类生成 |
| riverpod_generator | ^2.6.3 | Provider 生成 |
| mockito | ^5.4.5 | 测试 Mock |

---

## 🎨 设计规范

### 颜色系统

```dart
const primaryColor = Color(0xFF6366F1);
const successColor = Color(0xFF10B981);
const warningColor = Color(0xFFF59E0B);
const errorColor = Color(0xFFEF4444);
```

### 间距系统

```dart
const kSpaceXS = 4.0;
const kSpaceS = 8.0;
const kSpaceM = 12.0;
const kSpaceL = 16.0;
const kSpaceXL = 24.0;
```

### 字体规范

| 样式 | 字号 | 用途 |
|------|------|------|
| Display | 24px | 页面标题 |
| Title | 16px | 区块标题 |
| Body | 14px | 正文 |
| Caption | 12px | 按钮文字 |
| Tiny | 11px | 标签、徽章 |

---

## 🔗 参考链接

- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
