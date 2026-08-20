# Hopp 开发计划与里程碑

> 本文档记录 Hopp 项目的开发计划、里程碑和任务进度。详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md)。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | v0.7.0 已发布，cURL 导入、URL 参数同步已支持 |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | ✅ **544 个全部通过** |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 175 | ✅ 通过 |
| Services 测试 | 147 | ✅ 通过 |
| Providers 测试 | 99 | ✅ 通过 |
| Widgets 测试 | 87 | ✅ 通过 |
| Utils 测试 | 36 | ✅ 通过 |
| **总计** | **544** | ✅ **全部通过** |

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

**优化策略**:
| 响应大小 | 默认模式 | 说明 |
|---------|---------|------|
| < 10KB | Full | 完整语法高亮 |
| 10KB - 50KB | Full | 完整语法高亮 |
| > 50KB | Performance | 虚拟化列表，轻量高亮 |

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
| Beautify 格式化按钮 | ✅ | P1 | 2h | 右上角 Beautify 按钮，支持 JSON/XML 格式化 |
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

**核心功能列表**:

| 功能项 | 类型 | 默认值 | 说明 | 状态 |
|--------|------|--------|------|------|
| HTTP Version | Dropdown | Auto | HTTP 版本选择 (Auto/HTTP1.1/HTTP2) | ⏳ |
| Enable SSL certificate verification | Toggle | ON | SSL 证书验证开关 | ✅ 已实现 |
| Automatically follow redirects | Toggle | ON | 自动跟随 HTTP 3xx 重定向 | ✅ 已实现 |
| Follow original HTTP Method | Toggle | OFF | 重定向时使用原始 HTTP 方法而非 GET | ⏳ |
| Follow Authorization header | Toggle | OFF | 跨域重定向时保留 Authorization 头 | ⏳ |
| Remove referer header on redirect | Toggle | OFF | 重定向时移除 Referer 头 | ⏳ |
| Enable strict HTTP parser | Toggle | OFF | 严格解析 HTTP 响应头 | ⏳ |
| Encode URL automatically | Toggle | ON | 自动编码 URL 路径、参数和认证字段 | ⏳ |
| Disable cookie jar | Toggle | OFF | 禁用该请求的 Cookie 存储和发送 | ⏳ |
| Use server cipher suite during handshake | Toggle | OFF | TLS 握手时使用服务器加密套件顺序 | ⏳ |
| Maximum number of redirects | Number Input | 10 | 最大重定向次数上限 | ✅ 已实现 |
| TLS/SSL protocols disabled | Multi-select | - | 禁用的 TLS/SSL 协议版本 | ⏳ |
| Cipher suite selection | Text Input | - | 自定义加密套件列表 | ⏳ |

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#请求设置-request-settings)。

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

**Body 类型映射表**:
| Postman mode | Hopp BodyType |
|--------------|---------------|
| raw | raw (支持 json/xml/html/javascript/text 子类型) |
| urlencoded | x-www-form-urlencoded |
| formdata | form-data (文本类型) |
| graphql | graphql |
| binary | binary |

**依赖库**:
```yaml
dependencies:
  file_picker: ^6.1.1
  uuid: ^4.3.3
```

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#postman-导入导出)。

---

### M6: 环境变量功能 ⏳ PLANNED

**目标**: 实现完整的环境变量管理系统，支持多环境切换和变量替换（PRD F3.1-F3.3）。

> **注意**: 目前仅实现了 Postman Environment 的导入导出格式支持，核心功能待实现。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| Environment 模型 | ⏳ | P0 | 4h | 环境变量数据模型 (name/variables) |
| 环境管理界面 | ⏳ | P0 | 8h | 创建/编辑/删除环境，变量列表编辑 |
| 环境切换器 | ⏳ | P0 | 4h | 下拉选择当前激活的环境 |
| 变量替换引擎 | ⏳ | P0 | 6h | `{{variable}}` 语法解析与替换 |
| 全局变量 | ⏳ | P1 | 4h | 跨环境共享的变量 (F3.2) |
| 变量作用域 | ⏳ | P1 | 4h | 全局 > 环境 > 本地 优先级 |
| 动态变量 | ⏳ | P2 | 6h | `{{$timestamp}}`, `{{$randomUUID}}` 等 |
| 变量预览 | ⏳ | P1 | 3h | 悬停显示变量值，快速复制 |
| 快速编辑 | ⏳ | P2 | 4h | URL/Body 中双击变量快速编辑 |
| 环境导入/导出 | ✅ | P1 | - | 已支持 Postman Environment 格式 |

#### M6.1 功能详细设计

**数据模型**:
```dart
@freezed
class Environment with _$Environment {
  const factory Environment({
    required String id,
    required String name,
    required List<EnvironmentVariable> variables,
    String? description,
  }) = _Environment;
}

@freezed
class EnvironmentVariable with _$EnvironmentVariable {
  const factory EnvironmentVariable({
    required String key,
    required String value,
    @Default(VariableType.string) VariableType type,
    @Default(true) bool enabled,
  }) = _EnvironmentVariable;
}

enum VariableType { string, secret }
```

**变量替换流程**:
```
1. 用户发送请求前
2. 提取当前激活的 Environment
3. 扫描 URL/Headers/Body 中的 {{variable}} 占位符
4. 按优先级查找变量值 (全局 > 环境 > 本地)
5. 替换占位符为实际值
6. 发送请求 (使用替换后的值)
7. 在 Request Tab 中显示替换前后的对比
```

**UI 设计**:
- 环境管理对话框 (类似 Postman)
- 侧边栏或顶部工具栏环境切换器
- 变量输入框支持 `{{` 触发自动建议
- 颜色区分：已解析变量 (蓝色) / 未定义变量 (红色)

**验收标准** (PRD F3.1-F3.3):
- [ ] 可创建多个环境配置 (开发/测试/生产)
- [ ] 可创建跨环境共享的全局变量
- [ ] URL/Headers/Body 中支持 `{{var}}` 语法
- [ ] 发送前自动替换变量为实际值
- [ ] 未定义变量在 UI 中明显标记
- [ ] 变量值支持字符串和密文类型

---

### M7: 测试与质量保障 ✅ COMPLETED

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

**技术方案**:
- Tokenizer - 词法分析器
- Parser - 语法分析器
- 支持常用选项: `-X`, `-H`, `-d`, `-F`, `--data-urlencode`, `-u`, `-k`, `-L`

**支持选项映射**:
| cURL 选项 | 映射 |
|-----------|------|
| `-X POST` | `HttpMethod.post` |
| `-H "key:value"` | `KeyValuePair` 列表 |
| `-d "data"` | Body 内容 |
| `-F "key=value"` | `BodyType.formData` |
| `--data-urlencode` | URL 编码处理 |
| `-u user:pass` | Authorization header |
| `-k` | `validateCertificates = false` |
| `-L` | `followRedirects = true` |

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#curl-导入)。

#### M6.2 URL 参数双向联动 (Issue #11)

**状态**: ✅ 已完成 (2026-03-18)

**功能概述**:
- URL 输入 `?key=value` → 自动解析到 Params Tab
- Params Tab 修改 → 自动更新 URL
- 使用标志位防止循环更新
- 36 个单元测试覆盖

详细实现说明请查看 [AGENTS.md](../AGENTS.md#url-查询参数与-params-tab-双向联动-issue-11)。

#### M6.3 Collection 扁平化存储重构 (Issue #3)

**状态**: ✅ 已完成 (2026-03-19)

**问题**: 双重存储结构导致级联删除和层级显示问题

**解决方案**: 统一使用扁平化存储结构（只使用 `parentId` 建立层级关系）

**核心改动**:
- `children` 字段保留但标记为废弃（向后兼容）
- `deleteCollection`: 通过 `parentId` 查询递归删除子集合
- `rootCollectionsProvider`: 返回根级集合

详细实现说明请查看 [AGENTS.md](../AGENTS.md#collection-扁平化存储重构-issue-3)。

#### M6.4 空状态入口指引 (Issue #6)

**状态**: ✅ 已完成 (2026-03-19)

**问题**: 初次使用缺少明显的创建 Request/Collection 入口

**解决方案**:
- Sidebar 空状态添加 "Create Collection" 按钮
- 主区域空状态添加 "Create Request" 按钮
- Sidebar Header 添加可见的 "+" 按钮

详细实现说明请查看 [AGENTS.md](../AGENTS.md#issue-6-空状态入口指引-ux-优化)。

---

### v0.7.0 - Environment & Testing ✅ COMPLETED (2026-04-01)

**目标**: 实现环境变量管理系统和测试脚本功能。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| **环境变量功能 (M6)** | ⏳ | **P0** | **35h** | **F3.1-F3.3 完整实现** |
| ├─ Environment 模型 | ⏳ | P0 | 4h | 环境变量数据模型 |
| ├─ 环境管理界面 | ⏳ | P0 | 8h | 创建/编辑/删除环境 |
| ├─ 环境切换器 | ⏳ | P0 | 4h | 下拉选择激活环境 |
| ├─ 变量替换引擎 | ⏳ | P0 | 6h | `{{variable}}` 语法解析 |
| ├─ 全局变量 | ⏳ | P1 | 4h | 跨环境共享变量 |
| ├─ 变量作用域 | ⏳ | P1 | 4h | 优先级管理 |
| ├─ 动态变量 | ⏳ | P2 | 6h | `$timestamp`, `$randomUUID` 等 |
| ├─ 变量预览 | ⏳ | P1 | 3h | 悬停显示变量值 |
| **测试脚本功能** | ⏳ | **P1** | **52h** | **F4.1-F4.4 测试自动化** |
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

### v0.8.0 - Mock & Advanced Features 📋 PLANNED

**目标**: 实现本地 Mock 服务，支持前后端并行开发。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 本地 Mock 服务器 | ⏳ | P0 | 12h | F7.4 基于 shelf 的本地 HTTP 服务器 |
| Mock 规则配置 | ⏳ | P0 | 8h | 从集合自动生成 Mock 规则 |
| 动态响应模板 | ⏳ | P1 | 6h | 支持模板变量、随机数据生成 |
| 延迟模拟 | ⏳ | P1 | 2h | 模拟网络延迟 |
| 代理设置 | ⏳ | P2 | 6h | F7.5 HTTP/HTTPS 代理 |
| WebSocket 测试 | ⏳ | P2 | 10h | F7.1 ws/wss 支持 |
| 代码片段生成 (F7.6) | ⏳ | P1 | 8h | 20+ 语言代码生成 |
| cURL 命令生成 (F1.10) | ⏳ | P1 | 4h | 请求 → cURL 导出 |
| 拖拽排序 (F2.7) | ⏳ | P2 | 8h | Collection/Folder/Request 拖拽调整顺序 |
| 文件上传/下载 (F1.9) | ⏸️ | P2 | 12h | multipart/form-data、文件下载进度 |

详细实现说明请查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#mock-服务器)。

---

### v0.9.0 - Polish & Stabilization 📋 PLANNED

**目标**: 功能完善和稳定性提升，准备 GA 发布。

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 请求设置完善 | ⏳ | P1 | 12h | F1.14 剩余配置项实现 |
| 性能优化 | ⏳ | P1 | 10h | 大集合加载、内存优化 |
| 完善文档 | ⏳ | P1 | 8h | 用户文档、API 文档 |
| 视频教程 | ⏳ | P2 | 6h | 快速入门、功能演示 |
| Bug 修复 | ⏳ | P0 | - | 社区反馈问题 |

---

### Backlog (未来规划)

暂不实现但未来可能考虑的功能：

| ID | 功能 | 状态 | 说明 |
|----|------|------|------|
| F1.8 | Cookie 管理 | ⏸️ | 查看/编辑/导入 Cookie |
| F1.9 | 文件上传/下载 | ⏸️ | multipart/form-data、文件下载 |
| F5.6 | 字体缩放 | ⏸️ | 编辑器字体大小调整 (Ctrl+滚轮) |
| F7.3 | API 文档生成 | ⏸️ | 从集合生成 Markdown/HTML 文档 |
| F7.7 | gRPC 测试 | Backlog | Protocol Buffers 接口测试 |
| F6.2 | 云端同步 | Backlog | 用户数据云存储，跨设备同步 |
| F6.3 | 团队协作 | Backlog | 多人实时协作编辑 |

---

### v1.0.0 - GA ⏳ PLANNED

**目标**: 功能完整的 API 测试工具，替代 Postman 免费版核心功能。

- ✅ 完整功能集（请求构建、环境变量、集合管理、测试脚本、Mock）
- ✅ 全平台稳定（macOS/Windows/Linux）
- ⏳ 应用商店发布 (Mac App Store, Microsoft Store)

---

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
| file_picker | ^6.1.1 | 文件选择 |
| uuid | ^4.3.3 | UUID 生成 |
| crypto | ^3.0.3 | 证书指纹计算 |

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
// lib/utils/constants.dart
class AppConstants {
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
}
```

### 字体规范

| 样式 | 字号 | 用途 |
|------|------|------|
| Display | 24px | 页面标题 |
| Title | 16px | 区块标题 |
| Body | 14px | 正文 |
| Caption | 12px | 按钮文字 |
| Tiny | 11px | 标签、徽章 |
| Code | 13px | 代码显示 |

---

## 🔗 参考链接

- [详细实现说明](./IMPLEMENTATION_NOTES.md)
- [产品需求规格说明书](./PRD.md)
- [项目知识积累](../AGENTS.md)
- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
