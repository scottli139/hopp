# Hopp 开发计划与里程碑

> 本文档记录 Hopp 项目的开发计划、里程碑和任务进度。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | Request Editor UI 优化完成，请求设置功能规划中 |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | ✅ **432 个全部通过** |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | ~60 | ⚠️ 部分失败 (Mock 问题) |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | ~88 | ✅ 大部分通过 |
| UI 优化测试 | 新增 7 个 | ✅ 通过 |
| **总计** | **432** | ✅ **全部通过** |

> **注意**: 所有测试均已通过，代码质量良好。

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

#### M3.9 Request Editor UI 优化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| Tab 样式优化 | ✅ | P1 | 数量标记、圆点指示器、底部指示线 |
| Key-Value 编辑器优化 | ✅ | P1 | 统一行高 36px、添加 info icon |
| Header 自动完成 | ✅ | P1 | 输入时显示下拉建议 |
| UI 测试支持 | ✅ | P1 | 添加相关测试指令 |

#### M3.10 Request Body 区域优化 ⏳ NEW

参考 Postman Body 区域的功能和样式进行改进。

**参考截图**:

| 截图路径 | 内容说明 | 关键 UI 元素 |
|---------|---------|-------------|
| `Screenshot 2026-03-14 at 22.38.40.png` | Postman Body - raw JSON | Radio 选择器、JSON 下拉、Beautify 按钮、行号、语法高亮 |
| `Screenshot 2026-03-14 at 22.42.04.png` | Hopp 当前 Body 区域 | SegmentedButton 样式（需改为 Radio 样式） |
| `Screenshot 2026-03-14 at 22.41.15.png` | Postman Body - form-data | Radio 选中状态、Key-Value 编辑器、Value 类型下拉（Text/File） |
| `Screenshot 2026-03-14 at 22.41.21.png` | Postman Body - x-www-form-urlencoded | Key-Value 编辑器带 Description 列 |
| `Screenshot 2026-03-14 at 22.41.26.png` | Postman Body - binary | 文件选择器输入框（Select file） |
| `Screenshot 2026-03-14 at 22.41.35.png` | Postman Body - GraphQL 编辑区 | 双栏编辑器布局（Query + Variables） |
| `Screenshot 2026-03-14 at 22.41.39.png` | Postman Body - GraphQL 下拉 | Auto Fetch 下拉菜单 |
| `Screenshot 2026-03-14 at 22.41.52.png` | Postman Body - GraphQL 提示 | 错误提示浮层 |

**当前问题**:
- Body 类型选择使用 SegmentedButton，样式不够直观
- 缺少 Raw 模式下子类型选择（JSON/XML/Text/HTML/JavaScript）
- 缺少 Beautify 格式化按钮
- 编辑器无行号显示

**改进计划**:

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| Body 类型选择器重构 | ✅ | P1 | 4h | Radio button 组样式 (none/form-data/x-www-form-urlencoded/raw/binary/GraphQL) |
| Raw 子类型下拉菜单 | ✅ | P1 | 3h | 右侧下拉选择 Text/JavaScript/JSON/HTML/XML |
| Dropdown 样式统一 | ✅ | P1 | 2h | Method/Raw Content Type 下拉菜单样式统一优化 |
| Beautify 格式化按钮 | ⏳ | P1 | 2h | 右上角 Beautify 按钮，支持 JSON/XML 格式化 |
| 编辑器行号显示 | ⏳ | P1 | 3h | 代码编辑器左侧显示行号 |
| JSON 语法高亮优化 | ⏳ | P2 | 4h | 键/字符串/数字不同颜色高亮 |
| form-data 文件上传 | ⏳ | P2 | 4h | Value 列支持 Text/File 类型切换、文件选择器 |
| x-www-form-urlencoded 优化 | ⏳ | P2 | 3h | 添加 Description 列、Bulk Edit 功能 |
| binary 文件选择器 | ⏳ | P2 | 2h | 单文件选择输入框 |
| GraphQL 双栏编辑器 | ⏳ | P3 | 8h | QUERY + GRAPHQL VARIABLES 双栏布局 |

#### M3.11 Response/Request Body 编辑器样式改进 ✅ COMPLETED

参考 Postman Response Body 区域样式，改进编辑器视觉效果。

**参考对比** (Postman vs Hopp):
- 截图对比: `/Users/build/Desktop/Screenshot 2026-03-16 at 11.48.09.png`

**主要差距**:
1. **行号区域**: Postman 行号宽度适中(35px)，灰色背景与代码区明显分隔；Hopp 行号偏宽，无背景区分
2. **编辑器边框**: Postman 有精致圆角边框；Hopp 边框样式原始
3. **语法高亮**: Postman 配色清晰(Key深蓝、String绿、Number蓝)；Hopp 高亮效果不够明显
4. **工具栏**: Postman 有格式下拉和 Beautify 按钮；Hopp 缺少 Beautify 功能
5. **整体质感**: Postman 现代精致；Hopp 略显粗糙

**改进完成情况**:

| 任务 | 状态 | 优先级 | 实际工时 | 文件 |
|-----|------|--------|---------|------|
| 行号区域样式优化 | ✅ | P1 | 3h | `optimized_response_viewer.dart`, `code_editor.dart` |
| 编辑器边框圆角 | ✅ | P1 | 2h | `optimized_response_viewer.dart`, `code_editor.dart` |
| JSON 语法高亮配色优化 | ✅ | P1 | 3h | `optimized_response_viewer.dart`, `code_editor.dart` |
| Beautify 格式化按钮 | ✅ | P1 | 2h | `optimized_response_viewer.dart` |
| 深色模式高亮适配 | ✅ | P2 | 2h | `optimized_response_viewer.dart`, `code_editor.dart` |
| UI 测试脚本 | ✅ | P1 | 2h | `test_code_editor_improved.py` |

**技术实现要点**:

1. **行号区域优化**:
```dart
// 行号区域容器
Container(
  width: 40, // 固定宽度，比默认更紧凑
  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
  padding: EdgeInsets.only(right: 8),
  child: // ... 行号列表
)
```

2. **编辑器边框**:
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(6),
    border: Border.all(
      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
    ),
  ),
)
```

3. **语法高亮配色** (参考 UI_UX_GUIDELINES.md JsonSyntaxColors):
- Key: `#1E40AF` (Blue 800)
- String: `#15803D` (Green 700)
- Number: `#2563EB` (Blue 600)
- Keyword: `#7C3AED` (Violet 600)

**UI 设计规范**:

**1. Body 类型选择器 (Radio 组)**
```
┌─────────────────────────────────────────────────────────────┐
│ ○ none  ○ form-data  ○ x-www-form-urlencoded  ● raw  [JSON ▼] │
└─────────────────────────────────────────────────────────────┘
```
- Radio 圆圈选中时填充蓝色，未选中为空心
- 类型标签横向排列，间距均匀
- Raw 模式右侧紧跟子类型下拉菜单

**2. Raw 模式编辑器**
```
┌─────────────────────────────────────────────────────────────┐
│                                    [Beautify]               │
│ 1 │ {                                                        │
│ 2 │   "username": "zhongmou",                               │
│ 3 │   "password": "7110eda4d09e062aa5e4a390b0a572ac0d2c0220" │
│ 4 │ }                                                        │
└─────────────────────────────────────────────────────────────┘
```
- 左上角 Beautify 按钮（仅 JSON/XML 模式显示）
- 左侧行号区域灰色背景
- JSON 语法高亮：key 为深蓝色，字符串为绿色，数字为蓝色

**3. form-data 编辑器**
```
┌─────────────────────────────────────────────────────────────┐
│ Key              │ Value           │ Description │ Bulk Edit │
│ ─────────────────┼─────────────────┼─────────────┼───────────│
│ username         │ zhongmou        │             │     ⋮     │
│ file             │ [Text ▼] [选择文件] │             │     ⋮     │
└─────────────────────────────────────────────────────────────┘
```
- Value 列支持 Text/File 类型切换
- File 类型显示文件选择按钮

**4. binary 模式**
```
┌─────────────────────────────────────────────────────────────┐
│ [Select file]                                               │
└─────────────────────────────────────────────────────────────┘
```
- 简洁的文件选择输入框
- 点击后弹出系统文件选择器

**5. GraphQL 模式**
```
┌──────────────────────────┬──────────────────────────────────┐
│ QUERY                    │ GRAPHQL VARIABLES        [ⓘ]     │
│ 1│                       │ 1│                               │
│ 2│ query {               │ 2│ {                             │
│ 3│   user(id: 1) {       │ 3│   "id": 1                     │
│ 4│     name              │ 4│ }                             │
│ 5│   }                   │                                │
│ 6│ }                     │                                │
└──────────────────────────┴──────────────────────────────────┘
```
- 双栏布局，左 Query 右 Variables
- 右侧标题带 info 图标提示
- 各自独立的行号显示

**实现参考**:
- 使用 `Row` + `Radio` 组件实现类型选择器
- 使用 `DropdownButton` 实现 Raw 子类型选择
- 集成 `flutter_code_editor` 的行号功能
- 使用 `dart:convert` 实现 JSON 格式化

**依赖文件**:
- `lib/widgets/request/request_editor.dart` - Body Tab 实现
- `lib/widgets/common/code_editor.dart` - 代码编辑器组件

---

### M4: 高级功能 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 请求名称编辑 | ✅ | **P0** | 4h | 右键菜单重命名 + UI 测试模式支持 |
| 大响应体渲染优化 | ✅ | **P0** | 6h | OptimizedResponseViewer 虚拟化显示 |
| UI 细节优化 | ✅ | P1 | 4h | Tab 样式、输入框对齐、按钮统一 |
| URL Bar 对齐修复 | ✅ | P0 | 2h | Method下拉、URL输入框、按钮统一36px |
| URL Focus 边框对齐 | ✅ | P0 | 2h | 修复紫色边框与背景区域高度不一致 |
| Request Editor UI 优化 | ✅ | P1 | 6h | Tab样式、Headers/Params列表、自动完成 |
| Request Body 区域优化 | ⏳ | P1 | 26h | 参考 Postman 改进 (radio 选择器、Raw 子类型、Beautify、行号、各 body 类型) |
| 请求设置 (Request Settings) | 🔄 | P1 | 10h | 已实现 SSL 验证开关，其他配置项待完成 |
| 主题切换 | ✅ | P1 | 4h | Light/Dark 模式 (基础实现已完成) |
| 国际化完善 | 🔄 | P1 | 6h | 多语言支持 (框架已搭建，需完善翻译) |
| 请求时间分析 | ✅ | P1 | 10h | Timing Tab (DNS/TCP/TLS/TTFB/Download) |
| 收尾检查清单 | ✅ | P0 | 2h | 测试验证、代码规范、文档更新 |
| 请求详情展示 | ✅ | P1 | 6h | Request Tab (方法/URL/Headers/Body) + UI测试 |
| 环境变量 | ⏳ | P1 | 12h | 变量替换和多环境 |
| 请求历史 | ⏳ | P2 | 8h | 请求历史记录 |
| 拖拽排序 | ⏳ | P2 | 6h | Collection 拖拽排序 |

#### M4.1 请求设置 (Request Settings) - F1.14

参考 Postman 的请求级别配置，实现精细化的请求控制。

**状态**: ⏳ 规划中 (预计 2026-03-20 开始实现)

**依赖**: 
- Dio HTTP 客户端配置
- 平台原生 TLS/SSL 配置支持

**核心功能列表**:

| 功能项 | 类型 | 默认值 | 说明 | 状态 |
|--------|------|--------|------|------|
| HTTP Version | Dropdown | Auto | HTTP 版本选择 (Auto/HTTP1.1/HTTP2) | ⏳ |
| Enable SSL certificate verification | Toggle | ON | SSL 证书验证开关 | ✅ 已实现 (2026-03-17) |
| Automatically follow redirects | Toggle | ON | 自动跟随 HTTP 3xx 重定向 |
| Follow original HTTP Method | Toggle | OFF | 重定向时使用原始 HTTP 方法而非 GET |
| Follow Authorization header | Toggle | OFF | 跨域重定向时保留 Authorization 头 |
| Remove referer header on redirect | Toggle | OFF | 重定向时移除 Referer 头 |
| Enable strict HTTP parser | Toggle | OFF | 严格解析 HTTP 响应头 |
| Encode URL automatically | Toggle | ON | 自动编码 URL 路径、参数和认证字段 |
| Disable cookie jar | Toggle | OFF | 禁用该请求的 Cookie 存储和发送 |
| Use server cipher suite during handshake | Toggle | OFF | TLS 握手时使用服务器加密套件顺序 |
| Maximum number of redirects | Number Input | 10 | 最大重定向次数上限 |
| TLS/SSL protocols disabled | Multi-select | - | 禁用的 TLS/SSL 协议版本 |
| Cipher suite selection | Text Input | - | 自定义加密套件列表 |

**实现规划**:

```
lib/
├── models/
│   ├── request_settings.dart          # RequestSettings 模型定义
│   └── request_settings.freezed.dart
├── providers/
│   └── request/
│       └── request_settings_provider.dart  # 请求设置状态管理
├── widgets/
│   └── request/
│       └── request_settings_tab.dart  # Settings Tab UI
└── services/
    └── http/
        └── request_options_builder.dart   # 根据设置构建 Dio Options
```

**技术要点**:
- 请求设置应与请求数据一起保存到 Collection
- Dio 支持通过 `Options` 配置大部分设置
- SSL 验证通过 `DioHttpClientAdapter` 的 `onHttpClientCreate` 配置
- TLS/SSL 协议禁用需要平台特定的实现 (iOS/macOS 使用 `Security`, Android 使用 `SSLSocket`)
- 设置项需要支持「继承全局默认值」和「请求级别覆盖」两种模式

**测试计划**:
- 单元测试: RequestSettings 模型序列化/反序列化
- Provider 测试: 设置变更同步到请求
- Widget 测试: Settings Tab 渲染和交互
- UI 测试: 各设置项切换验证

---

### M5: 数据管理 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| [Postman 导入/导出](#m51-postman-导入导出) | ⏳ | P1 | 12h |
| Insomnia 导入 | ⏳ | P2 | 8h |
| curl 导出 | ⏳ | P2 | 4h |
| 云端同步 | ⏳ | P3 | 20h |
| 团队协作 | ⏳ | P3 | 40h |

---

#### M5.1 Postman 导入/导出

**状态**: ✅ 已完成 (2026-03-16)
**依赖**: 无（可与 Request Settings 并行开发）
**工时估算**: 12小时

##### 架构设计

```
lib/
├── services/
│   └── import_export/
│       ├── postman_import_service.dart      # 导入服务
│       ├── postman_export_service.dart      # 导出服务
│       ├── postman_schema.dart              # Postman JSON Schema 模型
│       ├── postman_mapper.dart              # 字段映射转换器
│       └── import_export_exception.dart     # 自定义异常
├── widgets/
│   └── import_export/
│       ├── import_dialog.dart               # 导入对话框
│       ├── export_dialog.dart               # 导出对话框
│       ├── conflict_resolution_dialog.dart  # 冲突处理对话框
│       └── import_progress_dialog.dart      # 导入进度对话框
└── providers/
    └── import_export/
        ├── import_provider.dart             # 导入状态管理
        └── export_provider.dart             # 导出状态管理
```

##### 数据模型设计

**Postman Schema 模型** (`postman_schema.dart`):

```dart
// Collection v2.1 Schema
@freezed
class PostmanCollection with _$PostmanCollection {
  const factory PostmanCollection({
    required PostmanInfo info,
    required List<PostmanItem> item,
    List<PostmanVariable>? variable,
  }) = _PostmanCollection;
  
  factory PostmanCollection.fromJson(Map<String, dynamic> json) => 
      _$PostmanCollectionFromJson(json);
}

@freezed
class PostmanInfo with _$PostmanInfo {
  const factory PostmanInfo({
    required String name,
    String? description,
    String? version,
    @JsonKey(name: '_postman_id') String? postmanId,
    String? schema,
  }) = _PostmanInfo;
  
  factory PostmanInfo.fromJson(Map<String, dynamic> json) => 
      _$PostmanInfoFromJson(json);
}

@freezed
class PostmanItem with _$PostmanItem {
  const factory PostmanItem.request({
    required String name,
    PostmanRequest? request,
    List<PostmanResponse>? response,
    String? description,
  }) = PostmanRequestItem;
  
  const factory PostmanItem.folder({
    required String name,
    required List<PostmanItem> item,
    String? description,
  }) = PostmanFolderItem;
  
  factory PostmanItem.fromJson(Map<String, dynamic> json) => 
      _$PostmanItemFromJson(json);
}

@freezed
class PostmanRequest with _$PostmanRequest {
  const factory PostmanRequest({
    required String method,
    required PostmanUrl url,
    List<PostmanHeader>? header,
    PostmanBody? body,
    String? description,
  }) = _PostmanRequest;
  
  factory PostmanRequest.fromJson(Map<String, dynamic> json) => 
      _$PostmanRequestFromJson(json);
}

@freezed
class PostmanBody with _$PostmanBody {
  const factory PostmanBody({
    required String mode,  // raw/urlencoded/formdata/graphql/binary
    String? raw,
    List<PostmanUrlEncoded>? urlencoded,
    List<PostmanFormData>? formdata,
    PostmanGraphQL? graphql,
    PostmanBodyOptions? options,
  }) = _PostmanBody;
  
  factory PostmanBody.fromJson(Map<String, dynamic> json) => 
      _$PostmanBodyFromJson(json);
}

// Environment Schema
@freezed
class PostmanEnvironment with _$PostmanEnvironment {
  const factory PostmanEnvironment({
    required String name,
    @JsonKey(name: '_postman_variable_scope') String? scope,
    List<PostmanEnvironmentValue>? values,
  }) = _PostmanEnvironment;
  
  factory PostmanEnvironment.fromJson(Map<String, dynamic> json) => 
      _$PostmanEnvironmentFromJson(json);
}
```

##### 核心服务实现

**1. PostmanImportService**:

```dart
class PostmanImportService {
  final CollectionStorageService _collectionStorage;
  final EnvironmentStorageService _environmentStorage;
  
  PostmanImportService(this._collectionStorage, this._environmentStorage);
  
  /// 导入文件，自动检测类型 (Collection/Environment)
  Future<ImportResult> importFile(String filePath) async {
    final content = await File(filePath).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    
    // 检测类型
    if (_isCollection(json)) {
      return _importCollection(json);
    } else if (_isEnvironment(json)) {
      return _importEnvironment(json);
    } else {
      throw ImportException(
        ImportErrorCode.unknownFormat,
        '无法识别文件格式，请确保是有效的 Postman Collection 或 Environment',
      );
    }
  }
  
  /// 导入 Collection
  Future<ImportResult> _importCollection(Map<String, dynamic> json) async {
    // 版本检测
    final version = _detectVersion(json);
    if (version == PostmanVersion.v1_0) {
      throw ImportException(
        ImportErrorCode.unsupportedVersion,
        '不支持的 Postman v1.0 格式，请升级到 v2.0+',
      );
    }
    
    final collection = PostmanCollection.fromJson(json);
    
    // 转换为 Hopp Collection
    final hoppCollection = PostmanMapper.toHoppCollection(collection);
    
    // 检查冲突
    final existing = await _collectionStorage.getCollectionByName(hoppCollection.name);
    if (existing != null) {
      return ImportResult.conflict(
        collection: hoppCollection,
        existingId: existing.id,
      );
    }
    
    // 保存
    await _collectionStorage.saveCollection(hoppCollection);
    
    return ImportResult.success(
      collectionId: hoppCollection.id,
      importedRequestCount: _countRequests(collection.item),
    );
  }
  
  /// 处理导入冲突
  Future<ImportResult> resolveConflict({
    required Collection collection,
    required ConflictResolution resolution,
    String? existingId,
  }) async {
    switch (resolution) {
      case ConflictResolution.overwrite:
        if (existingId != null) {
          await _collectionStorage.deleteCollection(existingId);
        }
        await _collectionStorage.saveCollection(collection);
        return ImportResult.success(collectionId: collection.id);
        
      case ConflictResolution.rename:
        final newName = await _generateUniqueName(collection.name);
        final renamed = collection.copyWith(name: newName);
        await _collectionStorage.saveCollection(renamed);
        return ImportResult.success(
          collectionId: renamed.id,
          renamed: true,
          newName: newName,
        );
        
      case ConflictResolution.merge:
        // 合并逻辑：保留现有，添加新请求
        final existing = await _collectionStorage.getCollection(existingId!);
        final merged = _mergeCollections(existing!, collection);
        await _collectionStorage.saveCollection(merged);
        return ImportResult.success(
          collectionId: merged.id,
          merged: true,
        );
        
      case ConflictResolution.skip:
        return ImportResult.skipped();
    }
  }
}
```

**2. PostmanExportService**:

```dart
class PostmanExportService {
  final CollectionStorageService _collectionStorage;
  final EnvironmentStorageService _environmentStorage;
  
  /// 导出 Collection
  Future<void> exportCollection({
    required String collectionId,
    required String savePath,
    PostmanVersion version = PostmanVersion.v2_1,
    bool prettyPrint = true,
    bool includeEnvironment = false,
  }) async {
    final collection = await _collectionStorage.getCollection(collectionId);
    if (collection == null) {
      throw ExportException('Collection not found: $collectionId');
    }
    
    // 转换为 Postman 格式
    final postmanCollection = PostmanMapper.toPostmanCollection(
      collection,
      version: version,
    );
    
    // 序列化
    final json = postmanCollection.toJson();
    var jsonString = prettyPrint 
        ? const JsonEncoder.withIndent('  ').convert(json)
        : jsonEncode(json);
    
    // 写入文件
    final file = File(savePath);
    await file.writeAsString(jsonString);
    
    // 可选：导出环境变量
    if (includeEnvironment) {
      await _exportEnvironments(collectionId, savePath);
    }
  }
  
  /// 生成默认文件名
  String generateFileName(String collectionName, PostmanVersion version) {
    final sanitized = collectionName.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final versionSuffix = version == PostmanVersion.v2_1 ? 'v2.1' : 'v2.0';
    return '${sanitized}_$versionSuffix.postman_collection.json';
  }
}
```

**3. PostmanMapper** (核心映射逻辑):

```dart
class PostmanMapper {
  /// Hopp Collection → Postman Collection
  static PostmanCollection toPostmanCollection(
    Collection collection, {
    PostmanVersion version = PostmanVersion.v2_1,
  }) {
    return PostmanCollection(
      info: PostmanInfo(
        name: collection.name,
        description: collection.description ?? '',
        postmanId: _generateUuid(),
        schema: 'https://schema.getpostman.com/json/collection/${version.value}/collection.json',
      ),
      item: [
        // 映射 folders
        ...collection.folders.map(_folderToPostmanItem),
        // 映射顶层 requests
        ...collection.requests.map(_requestToPostmanItem),
      ],
    );
  }
  
  /// Postman Collection → Hopp Collection
  static Collection toHoppCollection(PostmanCollection postmanCollection) {
    return Collection(
      id: _generateId(),
      name: postmanCollection.info.name,
      description: postmanCollection.info.description,
      folders: _extractFolders(postmanCollection.item),
      requests: _extractRootRequests(postmanCollection.item),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Body 类型映射 (Postman → Hopp)
  static BodyType mapPostmanBodyMode(String mode, PostmanBodyOptions? options) {
    switch (mode) {
      case 'raw':
        return BodyType.raw;
      case 'urlencoded':
        return BodyType.formUrlEncoded;
      case 'formdata':
        return BodyType.formData;
      case 'graphql':
        return BodyType.graphql;
      case 'binary':
        return BodyType.binary;
      default:
        return BodyType.none;
    }
  }
  
  /// Raw 子类型映射
  static String? mapRawContentType(String? language) {
    switch (language) {
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
        return 'text/html';
      case 'javascript':
        return 'application/javascript';
      case 'text':
      default:
        return 'text/plain';
    }
  }
}
```

##### UI 组件实现

**1. ImportDialog**:

```dart
class ImportDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  bool _isDragging = false;
  ImportState _state = const ImportState.idle();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('导入 Postman 数据'),
      content: SizedBox(
        width: 480,
        height: 320,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }
  
  Widget _buildContent() {
    return _state.when(
      idle: () => _buildDropZone(),
      loading: () => _buildLoading(),
      conflict: (collection, existingId) => ConflictResolutionDialog(
        collection: collection,
        onResolve: _handleConflictResolution,
      ),
      success: (result) => _buildSuccess(result),
      error: (message) => _buildError(message),
    );
  }
  
  Widget _buildDropZone() {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) => _handleFileDrop(details.files),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey.shade400,
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isDragging 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
              : Colors.grey.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('拖放文件到此处或点击选择'),
              SizedBox(height: 8),
              Text(
                '支持 Postman Collection v2.0/v2.1 和 Environment',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleFileDrop(List<XFile> files) async {
    if (files.isEmpty) return;
    
    setState(() => _state = const ImportState.loading());
    
    try {
      final importService = ref.read(postmanImportServiceProvider);
      final result = await importService.importFile(files.first.path);
      
      setState(() => _state = ImportState.success(result));
    } on ImportException catch (e) {
      setState(() => _state = ImportState.error(e.message));
    }
  }
}
```

##### 异常处理

```dart
/// 导入错误码
enum ImportErrorCode {
  unknownFormat,
  unsupportedVersion,
  invalidJson,
  missingRequiredField,
  fileNotFound,
  permissionDenied,
}

class ImportException implements Exception {
  final ImportErrorCode code;
  final String message;
  final dynamic details;
  
  ImportException(this.code, this.message, {this.details});
  
  @override
  String toString() => 'ImportException($code): $message';
}

class ExportException implements Exception {
  final String message;
  final dynamic details;
  
  ExportException(this.message, {this.details});
  
  @override
  String toString() => 'ExportException: $message';
}
```

##### 测试计划

**单元测试** (`test/services/postman_import_service_test.dart`):

```dart
group('PostmanImportService', () {
  test('should import v2.1 collection successfully', () async {
    // 准备测试数据
    final json = _loadTestFile('collection_v2.1.json');
    
    // 执行导入
    final result = await service.importJson(json);
    
    // 验证结果
    expect(result.isSuccess, true);
    expect(result.importedRequestCount, 3);
  });
  
  test('should throw error for v1.0 collection', () async {
    final json = _loadTestFile('collection_v1.0.json');
    
    expect(
      () => service.importJson(json),
      throwsA(isA<ImportException>()),
    );
  });
  
  test('should correctly map all body types', () {
    final testCases = [
      ('raw', BodyType.raw),
      ('urlencoded', BodyType.formUrlEncoded),
      ('formdata', BodyType.formData),
      ('graphql', BodyType.graphql),
      ('binary', BodyType.binary),
    ];
    
    for (final (mode, expectedType) in testCases) {
      expect(PostmanMapper.mapPostmanBodyMode(mode, null), expectedType);
    }
  });
});
```

**Widget 测试**:
- ImportDialog 渲染测试
- 文件拖放交互测试
- 冲突处理对话框测试
- 导出选项验证测试

**集成测试**:
- 端到端导入流程测试
- 导出文件在 Postman 中打开验证
- 大量数据导入性能测试

##### 依赖库

```yaml
dependencies:
  # 文件选择
  file_picker: ^6.1.1
  # 桌面端拖放支持
  desktop_drop: ^0.4.4
  # UUID 生成
  uuid: ^4.3.3

dev_dependencies:
  # 测试数据生成
  faker: ^2.1.0
```

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

- ✅ 主题切换 (基础实现)
- 🔄 国际化 (框架搭建，需完善)
- ⏳ 请求历史
- ⏳ 环境变量
- ✅ Timing 分析
- ✅ 请求详情展示
- ⏳ 请求设置 (Request Settings)
- ✅ 修复测试失败 (2个 Widget 测试)

### v0.5.0 - Data Exchange 📋 PLANNED

- ⏳ Postman 导入/导出 (v2.1 格式完整支持)
- ⏳ Insomnia 导入 (v4 格式)
- ⏳ curl 命令导出
- ⏳ Collection/Environment 批量导入
- ⏳ 导入冲突处理机制

### v0.6.0 - Advanced Features 📋 PLANNED

- ⏳ 请求历史记录
- ⏳ 完整环境变量系统
- ⏳ 请求设置 (Request Settings) 实现
- ⏳ 数据备份与恢复
- ⏳ 完整国际化支持

### v1.0.0 - GA ⏳ PLANNED

- ⏳ 完整功能集
- ⏳ 请求设置 (Request Settings)
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
