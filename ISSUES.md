# Hopp 问题跟踪

> 本文件记录项目中待修复的 Bug 和待实现的功能，按优先级分类。
> 
> 最后更新: 2026-03-17

---

## 🔴 P0 - Critical Bug

### #P0-1: 4XX/5XX 响应不显示服务端返回内容

| 属性 | 值 |
|------|-----|
| **状态** | 🔴 Open |
| **标签** | `bug`, `P0`, `http-service` |
| **创建时间** | 2026-03-17 |
| **指派** | 待分配 |
| **预计修复** | 待安排 |

#### 问题描述
当服务端返回 4XX 或 5XX 错误时，Response Body 区域不显示服务端返回的数据，只显示错误信息。

#### 预期行为
即使 HTTP 状态码为错误码（4XX/5XX），也应该显示服务端返回的响应体内容。

#### 实际行为
只显示错误信息，不显示服务端返回的数据。

#### 修复方案
在 `http_service.dart` 的 DioException 处理中提取 `error.response` 的数据构建完整响应：

```dart
// lib/services/http/http_service.dart
try {
  final response = await _dio.request(...);
  // ...
} on DioException catch (e) {
  if (e.response != null) {
    // 提取服务端返回的数据
    final errorData = e.response?.data;
    final statusCode = e.response?.statusCode;
    // 构建包含服务端响应的 HttpResponse
    return HttpResponse(
      statusCode: statusCode ?? 0,
      body: errorData?.toString() ?? '',
      // ...
    );
  }
}
```

#### 相关文件
- `lib/services/http/http_service.dart`

#### 验收标准
- [ ] 4XX 响应能正确显示服务端返回的 JSON/XML/文本内容
- [ ] 5XX 响应能正确显示服务端返回的错误详情
- [ ] Response Headers 正确显示
- [ ] 状态码正确显示

---

## 🟡 P1 - High Priority

### #P1-1: Certificate Tab 显示假数据

| 属性 | 值 |
|------|-----|
| **状态** | ⏳ Open |
| **标签** | `bug`, `P1`, `certificate`, `ssl` |
| **创建时间** | 2026-03-17 |
| **指派** | 待分配 |
| **预计修复** | 待安排 |

#### 问题描述
Response 区域的 Certificate Tab 当前显示的是模拟/假数据，非真实证书信息。

#### 预期行为
显示真实的 SSL/TLS 证书信息：
- 证书颁发者 (Issuer)
- 证书有效期 (Valid From/To)
- 证书指纹 (Fingerprint)
- 证书链 (Certificate Chain)
- 主题信息 (Subject)
- 签名算法 (Signature Algorithm)

#### 实际行为
显示硬编码的模拟数据。

#### 修复方案
1. 从 Dio 响应中提取证书信息
2. 或使用 `HttpClient` 的 `badCertificateCallback` 获取证书
3. 解析 X.509 证书字段

#### 相关文件
- `lib/widgets/request/response_viewer.dart`
- `lib/models/certificate_info.dart`
- `lib/services/certificate_helper.dart`

#### 验收标准
- [ ] HTTPS 请求能获取真实证书
- [ ] 正确显示证书颁发者和有效期
- [ ] 正确显示证书链
- [ ] 证书过期时有警告提示

---

### #P1-2: 删除 Collection 时子目录处理问题

| 属性 | 值 |
|------|-----|
| **状态** | ⏳ Open |
| **标签** | `bug`, `P1`, `collection`, `data-integrity` |
| **创建时间** | 2026-03-17 |
| **指派** | 待分配 |
| **预计修复** | 待安排 |

#### 问题描述
删除带子目录的 Collection 时，子 Collection 未被删除而是被保留并提升到第一级。

#### 重现步骤
1. 创建一个 Collection A
2. 在 Collection A 下创建子 Collection B
3. 删除 Collection A
4. 观察：Collection B 仍然存在，但被提升到第一级

#### 预期行为
删除父 Collection 时应该级联删除所有子 Collection。

#### 实际行为
子 Collection 被保留并提升到根级别。

#### 修复方案
在 `deleteCollection` 方法中添加递归删除逻辑：

```dart
// lib/providers/collection/collection_provider.dart
Future<void> deleteCollection(String collectionId) async {
  final collection = findCollectionById(collectionId);
  if (collection == null) return;
  
  // 递归删除子 Collection
  for (final childId in collection.children) {
    await deleteCollection(childId);
  }
  
  // 删除当前 Collection
  // ...
}
```

#### 相关文件
- `lib/providers/collection/collection_provider.dart`

#### 验收标准
- [ ] 删除父 Collection 时级联删除所有子 Collection
- [ ] 删除前显示确认对话框，提示将删除的子 Collection 数量
- [ ] 删除操作可撤销（Undo）

---

## 🟢 P2 - Medium Priority

### #P2-1: 行号与内容滚动不同步

| 属性 | 值 |
|------|-----|
| **状态** | ⏳ Open |
| **标签** | `bug`, `P2`, `ui`, `code-editor` |
| **创建时间** | 2026-03-17 |
| **指派** | 待分配 |
| **预计修复** | 待安排 |

#### 问题描述
Request/Response Body 编辑器中行号区域与内容区域未对齐，内容滚动时行号不跟随滚动。

#### 预期行为
行号区域应该与代码内容区域保持同步滚动。

#### 实际行为
滚动代码内容时，行号区域不动。

#### 修复方案
使用 `ScrollController` 同步两个区域的滚动：

```dart
// 方案 1: 使用同一个 ScrollController
final scrollController = ScrollController();

Row(
  children: [
    SingleChildScrollView(
      controller: scrollController,
      child: LineNumberWidget(),
    ),
    Expanded(
      child: SingleChildScrollView(
        controller: scrollController,
        child: CodeContentWidget(),
      ),
    ),
  ],
)

// 方案 2: 使用 LinkedScrollController
```

#### 相关文件
- `lib/widgets/common/code_editor.dart`
- `lib/widgets/common/optimized_response_viewer.dart`

#### 验收标准
- [ ] 滚动代码内容时行号同步滚动
- [ ] 行号与代码行保持对齐
- [ ] 支持横向滚动同步（如需要）

---

## 📋 Feature Requests

### #F1-14: 请求设置功能实现 (Request Settings)

| 属性 | 值 |
|------|-----|
| **状态** | 📅 Planned |
| **标签** | `enhancement`, `P1`, `settings`, `F1.14` |
| **创建时间** | 2026-03-14 |
| **指派** | 待分配 |
| **预计开始** | 2026-03-20 |
| **预计工时** | 10 小时 |

#### 描述
实现请求级别的配置选项，参考 Postman 的请求设置功能。

#### 功能清单

| 设置项 | 类型 | 默认值 | Dio 支持 |
|--------|------|--------|----------|
| HTTP Version | Dropdown | Auto | ✅ via `httpVersion` |
| Enable SSL certificate verification | Toggle | ON | ✅ via `HttpClient` |
| Automatically follow redirects | Toggle | ON | ✅ via `followRedirects` |
| Follow original HTTP Method | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Follow Authorization header | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Remove referer header on redirect | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Enable strict HTTP parser | Toggle | OFF | ❌ 平台特定 |
| Encode URL automatically | Toggle | ON | ✅ 默认行为 |
| Disable cookie jar | Toggle | OFF | ✅ via `CookieManager` |
| Use server cipher suite during handshake | Toggle | OFF | ⚠️ 平台特定 |
| Maximum number of redirects | Number | 10 | ✅ via `maxRedirects` |
| TLS/SSL protocols disabled | Multi-select | - | ⚠️ 平台特定 |
| Cipher suite selection | Text | - | ⚠️ 平台特定 |

#### 实现架构
```
lib/
├── models/
│   └── request_settings.dart          # Freezed 模型
├── providers/
│   └── request/
│       └── request_settings_provider.dart
├── widgets/
│   └── request/
│       ├── request_editor.dart        # 添加 Settings Tab
│       └── request_settings_tab.dart  # 设置面板 UI
└── services/
    └── http/
        └── request_options_builder.dart   # 构建 Dio Options
```

#### UI 设计
- 设置项采用卡片式布局，每个设置独立卡片
- 显示「Default: Settings」提示继承关系
- 修改后显示紫色圆点指示器
- 支持分组（SSL/TLS、重定向、编码等）

#### 验收标准
- [ ] 支持 HTTP 版本选择
- [ ] 支持 SSL 证书验证开关
- [ ] 支持重定向相关设置
- [ ] 支持 Cookie 开关
- [ ] 设置与请求数据一起持久化
- [ ] UI 显示与 Postman 类似的设置界面

---

### #REQ-1: Request Body 区域优化

| 属性 | 值 |
|------|-----|
| **状态** | 🔄 In Progress |
| **标签** | `enhancement`, `P2`, `ui`, `body-editor` |
| **创建时间** | 2026-03-14 |
| **指派** | 待分配 |

#### 描述
参考 Postman 改进 Body Tab UI。

#### 已完成 ✅
- [x] Radio 选择器样式
- [x] Raw 子类型下拉菜单
- [x] UI 测试验证

#### 待实现 ⏳
- [ ] form-data 文件上传支持
- [ ] x-www-form-urlencoded 编辑器
- [ ] binary 文件选择
- [ ] GraphQL 编辑器

---

### #REQ-2: 国际化完善

| 属性 | 值 |
|------|-----|
| **状态** | ⏳ Open |
| **标签** | `enhancement`, `P2`, `i18n` |
| **创建时间** | 2026-03-14 |
| **指派** | 待分配 |

#### 描述
国际化框架已搭建，需要完善各语言翻译。

#### 已完成 ✅
- [x] 框架搭建 (flutter_localizations)
- [x] 基础键值定义

#### 待完善 ⏳
- [ ] 中文翻译补全
- [ ] 英文翻译校对
- [ ] 其他语言支持

---

## 统计

| 优先级 | 数量 | 状态 |
|--------|------|------|
| 🔴 P0 | 1 | 1 Open |
| 🟡 P1 | 3 | 2 Open, 1 Planned |
| 🟢 P2 | 1 | 1 Open |
| 📋 Feature | 3 | 1 In Progress, 2 Open |
| **总计** | **8** | **8 活跃** |

---

## 更新日志

| 日期 | 更新内容 |
|------|----------|
| 2026-03-17 | 创建 ISSUES.md，整理已知问题 |
