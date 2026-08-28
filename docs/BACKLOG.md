# Backlog 任务清单

> 本文档只记录**当前计划（M8 系列，见 DEVELOPMENT_PLAN）以外**的内容：未排期的候选功能、已知问题与技术债。
>
> 战略决策、里程碑与已排期任务见 [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md)；需求细节与验收标准见 [PRD.md](./PRD.md)。

**最后更新**: 2026-08-25

---

## 待实现功能（未排期）

### 一、核心请求功能

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F1.8 | Cookie 管理 | ⭐⭐⭐ | 1周 | 查看/编辑/导入 Cookie（认证链需要时再启） |
| F1.9 | 文件上传/下载 | ⭐⭐⭐ | 1.5周 | multipart/form-data、文件下载进度 |
| F1.10 | cURL 生成 | ⭐⭐ | 3天 | cURL 命令生成与复制（后续并入 Tier 0，见 PRD F9） |
| F1.14-2 | HTTP 版本选择 | ⭐⭐ | 3天 | Request Settings - HTTP/1.1 或 HTTP/2 |
| F1.14-3 | 重定向设置 | ⭐⭐ | 3天 | Request Settings - 跟随原始方法、保留 Authorization 等 |
| F1.14-4 | Cookie 设置 | ⭐⭐ | 2天 | Request Settings - 禁用 Cookie Jar |
| F1.14-5 | 高级 TLS 设置 | ⭐ | 1周 | Request Settings - 协议版本、加密套件 |

### 二、集合与组织功能

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F2.1 | 请求历史 | ⭐⭐⭐ | 1周 | 自动保存最近请求记录 |
| F2.2 | 收藏请求 | ⭐⭐ | 3天 | 手动收藏常用请求 |
| F2.7 | 拖拽排序 | ⭐⭐ | 5天 | Collection/Folder/Request 拖拽排序 |

### 三、环境变量功能

> 核心（F3.1-F3.5）已于 2026-08-21 完成（M8.1，见 DEVELOPMENT_PLAN）；F3.6 变量转换已由 F8.3 落地（M8.2 / v0.10.0，2026-08-25）。

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F3.7 | 环境变量导出 | ⭐⭐ | 2天 | 导出为 Postman Environment 格式（导入已支持） |
| F3.8 | 变量悬停预览/快速编辑 | ⭐ | 3天 | 悬停显示变量值、双击快速编辑 |

### 四、测试与断言功能

> F4.1 / F4.2 / F4.4 已排期 M8.4（见 DEVELOPMENT_PLAN）；此处只保留未排期项。

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F4.3 | 批量运行 | ⭐⭐ | 2周 | 集合级批量执行 + 断言 + 报告（M8.4 之后视需求排期） |

---

## 数据与同步功能

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F6.2 | 云端同步 | ⭐⭐⭐ | 4周 | 与本地优先定位冲突，谨慎评估 |
| F6.3 | 团队协作 | ⭐⭐ | 6周 | 多人协作编辑 Collection，权限管理（依赖云端同步，远期） |
| F6.4 | 数据备份 | ⭐⭐ | 1周 | 自动/手动备份，可导出完整数据备份 |

---

## 高级功能（⏸️ 暂缓：非差异化，见 PRD 决策）

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F7.1 | WebSocket 测试 | ⭐⭐ | 4周 | 支持 ws/wss 协议，消息收发 |
| F7.7 | gRPC 测试 | ⭐⭐ | 4周 | 支持 gRPC 协议的 API 测试 |
| F7.3 | API 文档生成 | ⭐⭐ | 2周 | 从集合生成 Markdown/HTML 文档 |
| F7.4 | Mock 服务 | ⭐⭐ | 3周 | 创建本地 Mock 服务，模拟 API 响应（详细需求已存档于 PRD） |
| F7.5 | 代理设置 | ⭐⭐ | 1周 | HTTP/HTTPS 代理，支持系统代理和自定义代理 |
| F7.6 | 代码生成 | ⭐⭐⭐ | 2周 | 生成 Python/JS/cURL 等代码片段（详细需求已存档于 PRD） |

---

## UI/UX 改进

| ID | 功能 | 优先级 | 预估工作量 | 说明 |
|----|------|--------|------------|------|
| F5.4 | 响应体搜索 | ⭐⭐⭐ | 1周 | 在响应内容中搜索，支持正则，高亮匹配 |
| F5.6 | 字体缩放 | ⭐⭐ | 3天 | 编辑器字体大小调整，Ctrl+滚轮或设置调整 |
| UX-1 | 行号滚动同步 | ⭐⭐ | 3天 | Request/Response Body 编辑器行号与内容滚动同步（Issue #4） |
| UX-3 | Request Body Beautify | ⭐⭐ | 2天 | Issue #15：Raw 编辑器缺一键格式化（响应侧已有，见 `optimized_response_viewer.dart`） |
| UX-4 | 状态栏网络状态显示 | ⭐ | 3天 | Issue #12：替代静态 Ready，显示网络类型/在线状态/本机 IP |

---

## 其他潜在功能

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 插件系统 | ⭐⭐ | 支持第三方插件扩展 |
| API 监控 | ⭐⭐ | 定时任务检查 API 健康状态 |
| 性能测试 | ⭐ | 基础压力测试功能 |
| Insomnia 导入 | ⭐⭐ | Insomnia 数据格式导入（OpenAPI 导入已排期 M8.3，见 PRD F9） |
| 导出格式扩展 | ⭐⭐ | Swagger/OpenAPI、Markdown 导出 |

---

## 已知问题

> 本表只保留未修复问题；已修复/已排除的不再留存，追溯见 [CHANGELOG.md](./CHANGELOG.md) 与 GitHub Issues。

| 问题 | 优先级 | 状态 |
|------|--------|------|
| 行号与内容滚动不同步 | P2 | 待修（CodeEditor 组件；TI-03 已修复，`scroll_response target=body` 可自动化验证，见 [UX_AUDIT_M8.md](UX_AUDIT_M8.md)） |
| 导入对话框拖放未实现 | P3 | 待修（Postman/OpenAPI 导入的拖放区均为视觉残桩，实际只能点击选择；实现需引入 desktop_drop 类依赖） |

---

## 技术债 / 代码重构

> 不改变用户可见行为，仅改善代码质量。按优先级择机处理。

| ID | 问题 | 现状 | 目标 | 优先级 | 触发时机 |
|----|------|------|------|--------|----------|
| TD-1 | 后代集合遍历逻辑重复 | `collection_provider.dart` 的 `collectDescendants` 与 `postman_import_service.dart` 的 `_collectAllChildIds` 是同一段「按 parentId 递归收集子孙」逻辑 | 抽成公共工具函数，两处复用 | P2 | 下次改动集合层级 / 导入导出逻辑时 |
| TD-2 | URL 查询参数解析重复 | `utils/url_params_sync.dart` 已提供 parse/build/sync，但 `http_service.dart`、`postman_mapper.dart`、`curl_import_service.dart` 各自重写 | 统一走 `url_params_sync.dart` | P2 | 下次改动 URL 处理相关代码时 |
| TD-3 | Timing 的 TCP/TLS/TTFB 为估算值 | `http_service.dart` 用硬编码 `30/20/45` 及 `totalMs ~/ 3` 填充 | 改为真实测量，测不到就标记为未测量（null），避免误导 | P2 | 实现真实计时或重做 Timing Tab 时 |
| TD-5 | site/ 版本徽章手动同步 | App 侧版本号已改为动态读取（v0.8.8，Issue #13）；残余：`site/` 两个静态页的 version 徽章需发布时手动改（2026-08-25 已对齐 v0.10.0） | 发布流程中加入 site/ 徽章同步步骤（或脚本化） | P3 | 每次发布 |
| TD-6 | test-mode `tap_at` 疑似干扰 Tab 状态 | F8 截图审计（2026-08-25）：Params 页对 fx 按钮 `tap_at(745,118)`（47 个 hitTargets）后页面异常跳回 Pre-request tab；功能本身由 widget test 覆盖且正常 | 排查 `tap_at` 的命中分发与 `_tabController`/持久化 index 的互相影响 | P3 | 下次扩展 test-mode 指针指令时 |
| TD-7 | 应用无单实例保护 | Hive 非跨进程安全，两个实例并发打开同一数据目录会导致 box 文件清零（2026-08-28 实发事故，test-mode 已通过独立数据目录 `hopp_test` 规避，见 CHANGELOG v0.11.0-test-data-isolation）；普通双开（用户手动启动第二个 release 实例）仍无防护 | 启动时对数据目录加 OS 级文件锁（dart:io File.lock），第二个实例提示退出 | P1 | 下次改动存储初始化时 |
