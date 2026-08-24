# Hopp 开发计划与里程碑

> 本文档只记录开发计划、里程碑和任务进度。设计规范见 [UI_UX_GUIDELINES.md](./UI_UX_GUIDELINES.md)，技术栈与依赖见 [ARCHITECTURE.md](./ARCHITECTURE.md)，详细实现说明见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md)，测试方案见 [TESTING.md](./TESTING.md)。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | 战略转向：本地 + 私有 AI（M8.0 UX 审计、M8.1 环境变量系统完成于 2026-08-21；设计系统 P1–P5 完成于 2026-08-22；当前版本 v0.9.2） |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | ✅ **649 通过 / 2 跳过**（2026-08-24 实测） |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 185 | ✅ 通过 |
| Services 测试 | 178 | ✅ 通过 |
| Providers 测试 | 114 | ✅ 通过 |
| Widgets 测试 | 129 (+2 跳过) | ✅ 通过 |
| Utils 测试 | 41 | ✅ 通过 |
| 根目录（design_guard / app_version） | 2 | ✅ 通过 |
| **总计** | **649** | ✅ **全部通过** |

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

### M3: 用户体验 ✅ COMPLETED (2026-03-13)

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

快捷键清单见 [UI_UX_GUIDELINES.md](./UI_UX_GUIDELINES.md#快捷键)。

#### M3.4 HTTPS 证书查看 (F1.11)

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| CertificateInfo 模型 | ✅ | P1 | 证书信息存储 |
| Certificate Tab UI | ✅ | P1 | Response 区域动态 Tab |
| 证书详情展示 | ✅ | P1 | Subject/Issuer/有效期/指纹 |
| 真实证书获取 | ✅ | P1 | 使用 SecureSocket 预连接获取 |
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

显示模式切换策略见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#响应优化-optimizedresponseviewer)。

#### M3.6 请求时间分析 (Timing)

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| TimingInfo 模型 | ✅ | P1 | DNS/TCP/TLS/TTFB/Download 时间 |
| HttpResponse 扩展 | ✅ | P1 | 添加 timingInfo 字段 |
| HttpService 时间测量 | ✅ | P1 | 各阶段时间统计（TCP/TLS 为估算值） |
| Timing Tab UI | ✅ | P1 | 总时间卡片、阶段详情、时间线 |
| UI 测试支持 | ✅ | P1 | timing 相关测试指令 |

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

#### M3.10 Request Body 区域优化 ✅ COMPLETED

参考 Postman Body 区域的功能和样式进行改进。

**完成情况**:

| 任务 | 状态 | 优先级 | 实际工时 | 说明 |
|-----|------|--------|---------|------|
| Body 类型选择器重构 | ✅ | P1 | 4h | Radio button 组样式 (none/form-data/x-www-form-urlencoded/raw/binary/GraphQL) |
| Raw 子类型下拉菜单 | ✅ | P1 | 3h | 右侧下拉选择 Text/JavaScript/JSON/HTML/XML |
| Dropdown 样式统一 | ✅ | P1 | 2h | Method/Raw Content Type 下拉菜单样式统一优化 |
| Beautify 格式化按钮 | ⚠️ | P1 | 2h | 现仅响应侧保留（`optimized_response_viewer.dart`）；请求侧 Raw 编辑器无 Beautify，见 Issue #15 |
| 编辑器行号显示 | ✅ | P1 | 3h | 代码编辑器左侧显示行号 |
| JSON 语法高亮优化 | ✅ | P2 | 4h | 键/字符串/数字不同颜色高亮 |
| Body 编辑器边框优化 | ✅ | P1 | 2h | 隐藏左侧边框线，Request Body 左右靠边 |
| Code Editor 字体优化 | ✅ | P1 | 2h | Menlo 等宽字体 12px，行号 11px |

#### M3.11 Response/Request Body 编辑器样式改进 ✅ COMPLETED

参考 Postman Response Body 区域样式，改进编辑器视觉效果。

**改进完成情况**:

| 任务 | 状态 | 优先级 | 实际工时 | 文件 |
|-----|------|--------|---------|------|
| 行号区域样式优化 | ✅ | P1 | 3h | `optimized_response_viewer.dart`, `code_editor.dart` |
| 编辑器边框圆角 | ✅ | P1 | 2h | `optimized_response_viewer.dart`, `code_editor.dart` |
| JSON 语法高亮配色优化 | ✅ | P1 | 3h | `optimized_response_viewer.dart`, `code_editor.dart` |
| Beautify 格式化按钮 | ✅ | P1 | 2h | `optimized_response_viewer.dart` |
| 深色模式高亮适配 | ✅ | P2 | 2h | `optimized_response_viewer.dart`, `code_editor.dart` |
| UI 测试脚本 | ✅ | P1 | 2h | `test_code_editor_improved.py` |

---

### M4: 高级功能 ✅ COMPLETED (2026-03-17)

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 请求名称编辑 | ✅ | **P0** | 4h | 右键菜单重命名 + UI 测试模式支持 |
| 大响应体渲染优化 | ✅ | **P0** | 6h | OptimizedResponseViewer 虚拟化显示 |
| UI 细节优化 | ✅ | P1 | 4h | Tab 样式、输入框对齐、按钮统一 |
| URL Bar 对齐修复 | ✅ | P0 | 2h | Method下拉、URL输入框、按钮统一36px |
| URL Focus 边框对齐 | ✅ | P0 | 2h | 修复紫色边框与背景区域高度不一致 |
| Request Editor UI 优化 | ✅ | P1 | 6h | Tab样式、Headers/Params列表、自动完成 |
| Request Body 区域优化 | ✅ | P1 | 26h | 参考 Postman 改进 (radio 选择器、Raw 子类型、Beautify、行号、各 body 类型) |
| 请求设置 (Request Settings) | ✅ | P1 | 10h | SSL/TLS + Follow Redirects 实现完成 (Issue #5, #9) |
| 主题切换 | ✅ | P1 | 4h | Light/Dark 模式 (基础实现已完成) |
| 国际化完善 | 🔄 | P1 | 6h | 多语言支持 (框架已搭建，需完善翻译) |
| 请求时间分析 | ✅ | P1 | 10h | Timing Tab (DNS/TCP/TLS/TTFB/Download) |
| 收尾检查清单 | ✅ | P0 | 2h | 测试验证、代码规范、文档更新 |
| 请求详情展示 | ✅ | P1 | 6h | Request Tab (方法/URL/Headers/Body) + UI测试 |
| 4XX/5XX 响应修复 | ✅ | P0 | 4h | 正确显示服务端返回的错误内容 (Issue #1) |
| 真实证书获取 | ✅ | P1 | 4h | Certificate Tab 显示真实 SSL/TLS 证书 (Issue #2) |
| 数据库兼容性修复 | ✅ | P0 | 6h | Hive 数据库版本控制 + 向后兼容适配器 (Issue #5) |

#### M4.1 请求设置 (Request Settings) - F1.14

参考 Postman 的请求级别配置，实现精细化的请求控制。

**状态**: ✅ 已实现 (SSL/TLS 设置 UI 完成，SSL 验证开关可用)

**依赖**: 
- Dio HTTP 客户端配置
- 平台原生 TLS/SSL 配置支持

**功能清单**: 13 项请求级设置中已实现 3 项（SSL 证书验证开关、自动跟随重定向、最大重定向次数），完整清单与 Dio 支持度分析见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#请求设置-request-settings)。

#### M4.2 数据库迁移框架

**状态**: ✅ 已实现 (2026-03-18)

**问题背景**: 
当 `HttpRequest` 模型新增字段时，旧版本存储的数据缺少这些字段，导致 Hive 读取时抛出异常。

**解决方案**:
- 数据库版本控制 (`database_migration_service.dart`)
- 向后兼容适配器 (`models/adapters/`)
- 自动迁移流程

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#数据库迁移框架)。

---

### M5: 数据管理 ✅ COMPLETED (2026-03-16)

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| Postman 导入/导出 | ✅ | P1 | 12h | Collection/Environment v2.0/v2.1 |
| Environment 格式支持 | ✅ | P1 | 4h | 导入导出时支持环境变量格式 |
| Insomnia 导入 | ⏳ | P2 | 8h | Insomnia 数据格式支持 |
| curl 导出 | ⏳ | P2 | 4h | 请求 → cURL 导出 |
| 云端同步 | ⏳ | P3 | 20h | 用户数据云存储 |
| 团队协作 | ⏳ | P3 | 40h | 多人实时协作编辑 |

#### M5.1 Postman 导入/导出

**状态**: ✅ 已完成 (2026-03-16)
**依赖**: 无
**工时估算**: 12小时

**功能概述**:
- Collection v2.0/v2.1 导入支持
- Environment 导入支持
- Collection 导出为 Postman v2.1 格式
- 嵌套文件夹结构完整支持
- 所有 Body 类型映射
- 冲突处理机制 (覆盖/重命名/合并/跳过)

详细实现说明（含 Body 类型映射表）请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#postman-导入导出)。

---

### M6: 环境变量功能 ✅ COMPLETED (2026-08-21)

**目标**: 实现完整的环境变量管理系统，支持多环境切换和变量替换（PRD F3.1-F3.3）。

> **决策（2026-08-20）**: 定位为「可复用 + AI 变量注入的基础」，不是 parity。AI 生成的请求引用 `{{baseUrl}}` / `{{token}}`。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| Environment 模型 | ✅ | P0 | 4h | Freezed + Hive (typeId 11/12/13) |
| 环境管理界面 | ✅ | P0 | 8h | 管理对话框：列表 + 变量表格 + secret 掩码 |
| 环境切换器 | ✅ | P0 | 4h | Sidebar 顶部下拉，持久化激活状态 |
| 变量替换引擎 | ✅ | P0 | 6h | `{{variable}}` 解析，URL/Params/Headers/Body |
| 全局变量 | ✅ | P1 | 4h | Globals 作用域，跨环境共享 |
| 变量作用域 | ✅ | P1 | 4h | 环境覆盖全局（就近原则） |
| 动态变量 | ✅ | P2 | 6h | `$timestamp`/`$timestampMs`/`$isoTimestamp`/`$randomUUID`/`$randomInt` |
| 未定义变量标记 | ✅ | P1 | 3h | 切换器 + URL 栏警告图标（替代悬停预览/快速编辑） |
| 变量预览/快速编辑 | ⏳ | P2 | 7h | 悬停显示变量值，双击快速编辑（后续迭代） |
| 环境导入/导出 | ✅ | P1 | - | Postman Environment 导入已落地（导出待 F3.7） |

**实现要点**:
- 发送前在 `RequestResponseNotifier.sendRequest` 统一应用变量替换
- `url_params_sync.dart` 增加占位符保护，修复 `{{var}}` 被 `Uri.parse` 百分号编码破坏的问题
- test-mode 新增 10 个环境指令（`create_environment` / `set_active_environment` / `resolve_text` / `get_resolved_request` 等）
- 验收：`integration_test/test_environment_variables.py` 9/9 通过

**验收标准** (PRD F3.1-F3.3):
- [x] 可创建多个环境配置 (开发/测试/生产)
- [x] 可创建跨环境共享的全局变量
- [x] URL/Headers/Body 中支持 `{{var}}` 语法
- [x] 发送前自动替换变量为实际值
- [x] 未定义变量在 UI 中明显标记
- [x] 变量值支持字符串和密文类型

详细设计（数据模型 / 替换流程 / UI 设计）请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#环境变量系统-m81)。

---

### M7: 测试与质量保障 ✅ COMPLETED

| 任务 | 状态 | 优先级 | 数量 |
|-----|------|--------|------|
| 单元测试 (Models) | ✅ | P0 | 185 个 |
| 单元测试 (Services) | ✅ | P0 | 178 个 |
| 单元测试 (Providers) | ✅ | P0 | 114 个 |
| 单元测试 (Utils) | ✅ | P1 | 41 个 |
| Widget 测试 | ✅ | P1 | 99 个 (+2 跳过) |
| Peekaboo E2E 测试 | ✅ | P2 | 完整套件 |
| CI/CD 配置 | ✅ | P0 | GitHub Actions |

测试方案、UI 测试模式与 Peekaboo 套件用法见 [TESTING.md](./TESTING.md)。

---

## 🚀 发布计划

### v0.1.0 - Alpha ✅ COMPLETED

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

### v0.4.0 - RC ✅ COMPLETED (2026-03-16)

- ✅ 主题切换 (基础实现)
- ✅ 国际化 (框架搭建)
- ✅ Timing 分析
- ✅ 请求详情展示
- ✅ 请求设置 UI (SSL/TLS)
- ✅ 修复测试失败 (2个 Widget 测试)
- ✅ 请求保存功能修复
- ✅ Body 编辑器优化

### v0.5.0 - Data Exchange ✅ COMPLETED (2026-03-16)

- ✅ Postman 导入/导出 (v2.1 格式完整支持)
- ✅ Collection/Environment 批量导入
- ✅ 导入冲突处理机制
- ✅ SSL 证书验证开关
- ✅ 4XX/5XX 响应修复
- ✅ 真实证书获取

### v0.6.0 - Code Generation & Utils ✅ COMPLETED (2026-03-18)

**目标**: 实现代码生成和 cURL 双向导入导出，提升对接效率。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| **cURL 导入 (F2.6)** | ✅ | **P0** | 10h | **解析 cURL 命令创建请求** |
| cURL 导入 UX 改进 | ✅ | P1 | 4h | 支持编辑名称、选择 Collection |
| 对话框 UI 规范修复 (Issue #7) | ✅ | P1 | 2h | Import/Export/Delete 对话框样式统一 |
| URL 参数双向联动 (Issue #11) | ✅ | P0 | 8h | URL 与 Params Tab 双向同步 |
| Postman 导入重复参数修复 | ✅ | P1 | 2h | 修复 raw URL 含查询参数导致重复问题 |
| Collection 级联删除 (Issue #3) | ✅ | P0 | 4h | 删除父集合时自动删除子集合 |
| Collection 扁平化存储 | ✅ | P1 | 6h | 统一使用 parentId 建立层级关系 |
| 空状态入口指引 (Issue #6) | ✅ | P0 | 4h | 初次使用添加明显的创建入口 |
| 代码片段生成 (F7.6) | ⏳ | P1 | 8h | 20+ 语言支持 |
| cURL 命令生成 (F1.10) | ⏳ | P1 | 4h | 请求 → cURL 导出 |

#### M6.1 cURL 导入详细设计

**状态**: ✅ 已完成 (2026-03-18)

**技术方案**: Tokenizer（词法分析）+ Parser（语法分析），支持常用选项 `-X` / `-H` / `-d` / `-F` / `--data-urlencode` / `-u` / `-k` / `-L`。

详细实现说明（含选项映射表）请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#curl-导入)。

#### M6.2 URL 参数双向联动 (Issue #11)

**状态**: ✅ 已完成 (2026-03-18)

**功能概述**:
- URL 输入 `?key=value` → 自动解析到 Params Tab
- Params Tab 修改 → 自动更新 URL
- 使用标志位防止循环更新
- 36 个单元测试覆盖

#### M6.3 Collection 扁平化存储重构 (Issue #3)

**状态**: ✅ 已完成 (2026-03-19)

**问题**: 双重存储结构导致级联删除和层级显示问题

**解决方案**: 统一使用扁平化存储结构（只使用 `parentId` 建立层级关系）

**核心改动**:
- `children` 字段保留但标记为废弃（向后兼容）
- `deleteCollection`: 通过 `parentId` 查询递归删除子集合
- `rootCollectionsProvider`: 返回根级集合

#### M6.4 空状态入口指引 (Issue #6)

**状态**: ✅ 已完成 (2026-03-19)

**问题**: 初次使用缺少明显的创建 Request/Collection 入口

**解决方案**:
- Sidebar 空状态添加 "Create Collection" 按钮
- 主区域空状态添加 "Create Request" 按钮
- Sidebar Header 添加可见的 "+" 按钮

---

### v0.7.0 - 环境变量与测试脚本（部分完成）⚠️

> **纠偏（2026-08-20）**: 本里程碑原先标记为 ✅ COMPLETED，但环境变量系统（M6）和测试脚本（F4）实际上**未实现**（`lib/` 中无 Environment 模型/服务）。仅完成 Postman Environment 导入导出格式支持。
>
> **现状（2026-08-21）**: 环境变量系统已由 v0.8.0 M8.1 完整落地（见上文 M6，✅ 2026-08-21）；测试脚本（F4）决策**降级**——不做 JS 沙箱，改轻量断言 + AI 生成 + CLI/CI 导出，排入 v0.8.0 M8.4。下表保留原始规划作为对照，子项状态不再逐项维护。
>
> 相关决策已更新，见 [PRD](./PRD.md) 与下文 v0.8.0。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| **环境变量功能 (M6)** | ✅ | **P0** | **35h** | **F3.1-F3.3 已由 M8.1 完成（2026-08-21），详见上文 M6** |
| ├─ Environment 模型 | ⏳ | P0 | 4h | 环境变量数据模型 |
| ├─ 环境管理界面 | ⏳ | P0 | 8h | 创建/编辑/删除环境 |
| ├─ 环境切换器 | ⏳ | P0 | 4h | 下拉选择激活环境 |
| ├─ 变量替换引擎 | ⏳ | P0 | 6h | `{{variable}}` 语法解析 |
| ├─ 全局变量 | ⏳ | P1 | 4h | 跨环境共享变量 |
| ├─ 变量作用域 | ⏳ | P1 | 4h | 优先级管理 |
| ├─ 动态变量 | ⏳ | P2 | 6h | `$timestamp`, `$randomUUID` 等 |
| ├─ 变量预览 | ⏳ | P1 | 3h | 悬停显示变量值 |
| **测试脚本功能** | ⏸️ | **P1** | **52h** | **决策降级：不做 JS 沙箱，子项为原方案存档；新方案（轻量断言 + AI 生成 + CLI/CI 导出）见 v0.8.0 M8.4** |
| ├─ 脚本引擎架构 | ⏳ | P0 | 8h | JavaScript 沙箱环境 |
| ├─ Pre-request Script | ⏳ | P0 | 10h | F4.2 请求前脚本 |
| ├─ Test Script | ⏳ | P0 | 10h | F4.3 请求后断言脚本 |
| ├─ 可视化断言 | ⏳ | P1 | 6h | F4.1 无需代码的断言配置 |
| ├─ 批量运行 | ⏳ | P1 | 8h | F4.4 集合级别批量执行 |
| ├─ 测试报告 | ⏳ | P1 | 6h | HTML/CSV 报告导出 |
| ├─ CryptoJS 集成 | ⏳ | P0 | 4h | MD5/SHA/HMAC 签名算法 |
| 其他功能 | ⏳ | P2 | 42h | |
| ├─ 请求历史记录 (F2.1) | ⏳ | P1 | 6h | 自动保存最近请求 |
| ├─ 收藏请求 (F2.2) | ⏳ | P2 | 4h | 手动收藏常用请求 |
| ├─ 响应体搜索 (F5.4) | ⏳ | P2 | 4h | 在响应内容中搜索 |
| ├─ 数据备份与恢复 (F6.4) | ⏳ | P2 | 6h | 导出完整数据备份 |
| ├─ 字体缩放 (F5.6) | ⏳ | P2 | 4h | 编辑器字体大小调整 |
| ├─ Cookie 管理 (F1.8) | ⏸️ | P2 | 10h | 查看/编辑/导入 Cookie |
| ├─ API 文档生成 (F7.3) | ⏸️ | P3 | 8h | 从集合生成 Markdown/HTML 文档 |
| └─ 完整国际化支持 | ⏳ | P2 | 8h | 多语言翻译完善 |

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#测试与自动化)。

---

### v0.8.0 - 战略转型：本地 + 私有 AI 🔄 IN PROGRESS

> **方向（2026-08-20 决策）**: 不再追平 Postman 功能集，转向「本地优先 + 私有 AI」的差异化定位。
>
> **版本号说明（2026-08-24 核实）**: 设计系统重构（P1–P5）作为插入工作先行发布，pubspec 版本号由 0.7.0 直接推进至 0.9.2（跳过 0.8.x），见下文「v0.9.x」一节；本里程碑（M8.2–M8.6）仍在推进中，里程碑命名与发布版本号已脱钩。

按优先级排序：

| 阶段 | 内容 | 优先级 | 预估 | 状态 |
|------|------|--------|------|------|
| M8.0 | 状态纠偏 + UX 审计：跑 app 逐屏过，产出可验证瑕疵清单 | P0 | — | ✅ (2026-08-21) |
| M8.1 | 环境变量系统（M6）：定位「可复用 + AI 变量注入基础」 | P0 | — | ✅ (2026-08-21) |
| M8.2 | 预请求链 + 变量转换（F8.1-F8.3）：登录→token、密码 sha1/aes 加密 | P0 | ≈5 周 | ⏳ |
| M8.3 | Tier 0（F9）：OpenAPI/Swagger 导入 → 一键生成请求/collection | P0 | ≈2 周 | ⏳ |
| M8.4 | 轻量断言（F4.1/F4.2/F4.4）：状态/Header/Body/JSONPath + AI 生成 + CLI/CI 导出 | P1 | ≈4 周 | ⏳ |
| M8.5 | Tier 1（F9）：本地模型（Ollama/LM Studio）解释响应 / 生成断言 / 自然语言建请求 | P1 | ≈2 周 | ⏳ |
| M8.6 | Tier 2（F9）：BYOK 云端，默认关闭 | P2 | ≈1 周 | ⏳ |

**已搁置**（原 v0.8/v0.9 规划，非差异化，暂停）：
- Mock 服务器（F7.4）、代理（F7.5）、WebSocket（F7.1）、代码片段生成（F7.6）→ 暂缓
- Cookie 管理（F1.8）、文件上传下载（F1.9）→ 视需求再启

---

### v0.9.x - 设计系统重构与 UX 收口 ✅ COMPLETED (2026-08-24)

> 战略转向后的插入工作：先把视觉品质与「规范可被强制遵守」的机制补齐，再推进 M8.2+。版本号由 v0.7.0 直接推进至 v0.9.2（跳过 v0.8.x）。

| 任务 | 状态 | 说明 |
|-----|------|------|
| 设计系统 P1–P5 | ✅ (2026-08-22) | `lib/theme/` token 体系 + 设计守卫（基线 457→0 清零）；8 个统一组件落地并全量迁移；组件 golden 双主题基线；`withOpacity`/`FontWeight.bold` 清零；`constants.dart` 删除。详见 [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) |
| 侧栏主题切换 (v0.9.1) | ✅ (2026-08-22) | `AppSegmentedControl` + footer 三段切换（system/light/dark），持久化 `AppSettings.themeMode` |
| 环境管理对话框重设计 (v0.9.2) | ✅ (2026-08-24) | 原型先行（`docs/design/environment_manager_preview.html`）；附带修复对话框阴影渗透发灰、AppDivider 宽松约束塌缩、Request Settings 页 token 收口 |

逐项变更记录见 [CHANGELOG.md](./CHANGELOG.md)（v0.8.5 ～ v0.9.5 条目）。

---

### v1.0.0 - GA ⏳ PLANNED

**目标**: 本地优先 + 私有 AI 的 API 工作台，具备明确差异化后发布。

- ⏳ 差异化能力落地（环境变量 / 预请求链 / Tier 0 / 断言）
- ⏳ 全平台稳定（macOS/Windows/Linux）
- ⏳ 应用商店发布 (Mac App Store, Microsoft Store)

---

### Backlog (未来规划)

未排期的候选功能、已知问题与技术债统一由 [BACKLOG.md](./BACKLOG.md) 维护，本文档不再重复记录。

## 🐛 已知问题修复记录

| Issue | 问题描述 | 状态 | 修复时间 |
|-------|----------|------|----------|
| #1 | 4XX/5XX 响应不显示服务端返回内容 | ✅ 已修复 | 2026-03-17 |
| #2 | Certificate 显示假数据 | ✅ 已修复 | 2026-03-17 |
| #3 | 删除 Collection 子目录处理问题 | ✅ 已修复 | 2026-03-19 |
| #5 | Hive 数据库兼容性修复 | ✅ 已修复 | 2026-03-17 |
| #6 | 初次使用缺少创建入口 | ✅ 已修复 | 2026-03-19 |
| #7 | Import/Export/Delete 对话框 UI 规范 | ✅ 已修复 | 2026-03-18 |
| #9 | Request Settings UI 样式问题 | ✅ 已修复 | 2026-03-17 |
| #10 | Postman 导入 Raw Content Type 识别错误 | ✅ 已修复 | 2026-03-17 |
| #11 | URL 查询参数与 Params Tab 双向联动 | ✅ 已实现 | 2026-03-18 |
| #8 | About 页链接点击无效，无法跳转浏览器 | ✅ 已修复 | 2026-08-21 |
| #14 | Add Folder 对话框样式不符合规范 | ✅ 已修复 | 2026-08-21 |
| #16 | New Collection 对话框不符合 UI/UX 规范 | ✅ 已修复 | 2026-08-21 |

---

## 🔗 参考链接

- [产品需求规格说明书](./PRD.md)
- [架构设计（技术栈与依赖）](./ARCHITECTURE.md)
- [UI/UX 设计规范](./UI_UX_GUIDELINES.md)
- [详细实现说明](./IMPLEMENTATION_NOTES.md)
- [测试方案](./TESTING.md)
- [Backlog 任务清单](./BACKLOG.md)
- [项目知识积累](../AGENTS.md)
- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
