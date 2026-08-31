# UX 审计报告（M8.0 状态纠偏 + UX 审计）

> **时点快照（2026-08-21）**：本文是 M8.0 时点的审计记录。其中「请求编辑器 5 个 Tab」「Auth 为占位页」等描述已被后续里程碑改变（现为 7 页签，Auth/Pre-request/Assertions 均已落地，响应区新增 Tests）；各项修复状态以 [CHANGELOG](./CHANGELOG.md) 与 [DEVELOPMENT_PLAN](./DEVELOPMENT_PLAN.md) 为准。未修复项仍列于 [BACKLOG](./BACKLOG.md) 已知问题。

- **日期**：2026-08-20 ～ 2026-08-21
- **环境**：macOS Debug 构建，Flutter 3.27.4（FVM），窗口 800x600pt（截图 1600x1200 @2x）
- **方法**：`--test-mode` 启动 app，经 HTTP 指令驱动 UI（切 Tab / 模拟响应 / 触发对话框 / 截图），截图经人工逐张读图复核；并结合源码确认根因
- **证据**：截图原件存于 `~/Documents/kimi/workspace/hopp_m8_audit/`（沙箱 tmp 会被清理，已拷出），下文以文件名引用

## 覆盖范围

| 路线 | 结果 |
|------|------|
| 初始空状态主界面 | ✅ 正常（m8_01） |
| 请求编辑器 5 个 Tab（Params/Headers/Body/Auth/Settings） | ⚠️ Settings 见 UI-01；Auth 为占位页（对应 F8.1，非缺陷） |
| 响应区 6 个 Tab（Body/Headers/Cookies/Request/Certificate/Timing） | ✅ 正常；Certificate/Timing 按数据有无条件显示（m8_07/08 系列） |
| 响应空状态占位 | ⚠️ 溢出，见 UI-02（m8_04、m8_07_resp_body） |
| 4xx / 5xx 错误横幅 + 错误体展示 | ✅ 正常（422 红横幅、503，m8_09/10） |
| 大响应（50KB+，1008/2008 行）Performance 模式渐进加载 | ✅ 正常（500/1008 行 + Load more，m8_11、m8_21） |
| 方法下拉（7 方法彩色徽章） | ✅ 正常（m8_12） |
| 多 Tab 页签 | ✅ 正常（m8_13） |
| Raw 子类型下拉展开 | ✅ 已复验（TI-04 修复后拍到展开态，ti04_raw_dropdown） |
| 导入对话框（Postman） | ✅ 正常（m8_18） |
| 删除 Collection 确认对话框 | ✅ 正常（m8_20；仅打开截图，未确认删除） |
| cURL 导入对话框 | ✅ 已复验（TI-02 修复后可弹出，ti02_curl_dialog） |
| 导出对话框 | ✅ 正常（2026-08-20 复核，export_dialog_audit） |

---

## 产品瑕疵清单

### UI-01（P2）Settings Tab 缺滚动条指示，空间不足时内容被裁切 ✅ 已修复（2026-08-21）

- **现象**：divider 默认 0.5 时 Redirects 区只剩标题；divider 0.55 有响应时 "Maximum redirects" 副标题被分栏线裁掉半行。
- **根因复核**：修复时确认页面本已包 `SingleChildScrollView`（可滚动），真实缺陷是**无 Scrollbar 视觉指示**，用户无从得知下方还有内容。
- **证据**：hopp_m8_03_settings.png、hopp_m8_07_resp_body.png
- **修复**：`request_editor.dart` 为 Settings 页加 `Scrollbar(thumbVisibility: true)` 并挂接专用滚动控制器。复验截图 verify_ui03/verify_ui02 右侧滚动条可见。

### UI-02（P2）响应区空状态/工具条溢出（debug 横幅）✅ 已修复（2026-08-21）

- **现象**：divider 0.8 时响应空状态报 `BOTTOM OVERFLOWED BY 46 PIXELS`；divider 0.5 且有响应时 body 工具条区报 `BOTTOM OVERFLOWED BY 6.4 PIXELS`。空态 Column 无收缩保护。
- **复现**：拖动分栏改变响应区高度即可复现。
- **证据**：hopp_m8_04_settings_full.png（46px）、hopp_m8_07_resp_body.png（6.4px）
- **修复**：`response_viewer.dart` 三处空态（`_buildBodyTab`、`_buildHeadersTab`、`_buildEmptyState`）的居中 Column 外包 `SingleChildScrollView`，空间不足时改为可滚动而非溢出。复验：divider 0.8 压扁响应区后无 overflow 横幅（verify_ui02_no_overflow）。

### UI-03（P2）布局重建会把请求编辑器 Tab 重置回 Params ✅ 已修复（2026-08-21）

- **现象**：切到 Settings 后拖动分栏（`set_divider_position`），编辑器 Tab 被重置回 Params；测试指令内部 `updateRequest` 同样触发重置。
- **根因**（修复时精确定位）：`main_screen._listenToUITestCommands` 在分栏 provider 值 ≠ 默认 0.5 时，**每次 build 都 post-frame 整体替换 `_verticalSplitController.areas`**，子树 State 被销毁，编辑器 TabController 以 initialIndex 0 重建。真实用户拖拽只在原 Area 上改 flex、不替换对象，故该问题主要出现在「测试指令设了非默认分栏 + 任意 provider 触发重建」的组合场景。
- **证据**：hopp_m8_04_settings_full.png（截图前置动作是切 Settings + 移 divider，成像却是 Params）
- **修复**：① `main_screen.dart` 记录 `_lastAppliedDividerRatio`，仅在分栏值变化时才应用 areas；② 新增 `requestEditorTabIndexProvider`（request_tab_provider.dart）持久化编辑器 Tab 索引，`RequestEditor` State 重建后以保存的索引恢复。复验：切 Settings 后连续两次移动分栏（0.7、0.8）仍停留在 Settings（verify_ui03/verify_ui02）。

### UI-04（P3）Request 视图 auto header 判定为硬编码 key 集合 ✅ 已修复（2026-08-21）

- **现象**：`_isAutoHeader()`（response_viewer.dart:1110）只认 `user-agent / accept-encoding / connection / host` 四个 key。用户若**手动**添加同名 header（如自定义 `Host`），会被误标 `auto` 徽章并归入 "Auto-added Headers"。
- **说明**：审计中看到的 `Accept: */* 无 auto 徽章且 "2 custom" 计数含水`（hopp_m8_08_request.png）系**模拟响应手工构造的 mock 数据**所致，真实发送路径不会自动注入 Accept，不计为缺陷；本条仅保留硬编码集合这一边缘问题。
- **修复**：按建议改为按来源标记——`HttpRequestInfo` 新增 `autoHeaderKeys` 字段，`HttpService._buildRequestInfoHeaders` 与 test-mode mock 路径在构建 request info 时记录自动 header keys（小写），response_viewer 按该集合判定并删除两处 `_isAutoHeader`；附带修复 `content-length` 等长 key + auto 徽章在 140px 固定列溢出的问题。4 个服务级测试 + 2 个 widget 测试覆盖。

---

## 测试基建问题（✅ 已全部修复，2026-08-21）

| ID | 问题 | 根因 | 修复 |
|----|------|------|------|
| TI-01 | ~~`set_window_size` 是死指令~~ | 只写 `uiTestWindowSizeProvider`，全 lib/ 无监听者，窗口尺寸不会变 | 新增 `com.example.hopp/window` MethodChannel（AppDelegate 注册 handler），指令改为直接调原生 `setWindowSize` 并返回实际尺寸；删除死 provider |
| TI-02 | ~~`trigger_curl_import_dialog` 是死指令~~ | `uiTestCurlImportDialogProvider` 定义并赋值，但无任何 UI 监听（sidebar 只监听 import/export/delete） | sidebar 补 `ref.listen` 打开 cURL 导入对话框（复验截图 ti02_curl_dialog） |
| TI-03 | ~~`scroll_response` 无法滚动响应体~~ | 监听方（response_viewer.dart:91）只驱动 `_certificateScrollController`（Certificate Tab 的控制器），Body 编辑器不受影响；行号滚动同步因此无法自动化验证 | 指令新增 `target`（body 默认 / certificate）；`OptimizedResponseViewer` 支持外部滚动控制器并接入 Body 滚动；监听方动画后回写 before/after 到 `uiTestScrollResponseResultProvider`，指令回读返回（复验：0→500→300） |
| TI-04 | ~~`switch_request_tab` / `expand_raw_content_type_dropdown` 不可靠~~ | one-shot StateProvider 同值重设不触发（需先切其他 Tab 中转）；且 expand 指令内部 `updateRequest` 触发编辑器重建，经 UI-03 把刚切到的 Body tab 重置回 Params，展开信号落到已销毁的 widget 上 | `uiTestRequestTabProvider` 改带时间戳 payload，同值重发可触发；expand 指令等重建/动画窗口延长到 350ms（配合 UI-03 修复）。复验：同值连发保持 Body tab；下拉展开态截图成功（ti04_raw_dropdown） |

> 附带新增 `dismiss_dialog` 指令（`Navigator.maybePop` 关闭顶层对话框），替代不可靠的坐标点击 Cancel。

---

## 已复核、确认非问题

- **Auth Tab "Coming soon…"**、**Cookies Tab "Cookie management coming soon"**：对应 BACKLOG F8.1 / F1.8，为排期中的占位页。
- **Certificate / Timing Tab 按数据有无条件显示**：mock 响应无证书时不显示 Certificate tab，属设计行为。
- **导出对话框 Export 按钮**（2026-08-20 复核）：未选 Collection 时为禁用态（低对比度导致 OCR 误读为缺失），非缺陷。
- **模拟 4xx 的 mock body 内 error 字段与状态码文案不一致**（"Bad Request" vs 422）：mock 数据自身问题，非 UI 缺陷。

## 未覆盖 / 需人工检查

- 侧边栏 Filter 搜索输入（test-mode 无键盘输入能力）
- 真实点击/拖拽交互、右键菜单、快捷键
- CodeEditor 行号与内容滚动同步（BACKLOG 已知 P2；TI-03 已修复，`scroll_response target=body` 可驱动 Body 滚动，可转为自动化验证）
- Windows / Linux 平台外观
