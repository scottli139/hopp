# UX 审计报告（M8.0 状态纠偏 + UX 审计）

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
| Raw 子类型下拉展开 | ❌ 未能拍到展开态（指令缺陷，见 TI-04） |
| 导入对话框（Postman） | ✅ 正常（m8_18） |
| 删除 Collection 确认对话框 | ✅ 正常（m8_20；仅打开截图，未确认删除） |
| cURL 导入对话框 | ❌ 无法弹出（死指令，见 TI-02） |
| 导出对话框 | ✅ 正常（2026-08-20 复核，export_dialog_audit） |

---

## 产品瑕疵清单

### UI-01（P2）Settings Tab 内容不可滚动，空间不足时直接裁切

- **现象**：divider 默认 0.5 时 Redirects 区只剩标题；divider 0.55 有响应时 "Maximum redirects" 副标题被分栏线裁掉半行。内容无滚动能力。
- **复现**：打开任一请求 → Settings Tab → 窗口 800x600 默认布局。
- **证据**：hopp_m8_03_settings.png、hopp_m8_07_resp_body.png
- **建议**：Settings 页内容包 `SingleChildScrollView`，或至少对溢出做收缩保护。

### UI-02（P2）响应区空状态/工具条溢出（debug 横幅）

- **现象**：divider 0.8 时响应空状态报 `BOTTOM OVERFLOWED BY 46 PIXELS`；divider 0.5 且有响应时 body 工具条区报 `BOTTOM OVERFLOWED BY 6.4 PIXELS`。空态 Column 无收缩保护。
- **复现**：拖动分栏改变响应区高度即可复现。
- **证据**：hopp_m8_04_settings_full.png（46px）、hopp_m8_07_resp_body.png（6.4px）
- **建议**：空状态 Column 加 `mainAxisSize: min` / `Flexible` 收缩保护；响应区整体允许垂直滚动兜底。

### UI-03（P2）布局重建会把请求编辑器 Tab 重置回 Params

- **现象**：切到 Settings 后拖动分栏（`set_divider_position`），编辑器 Tab 被重置回 Params；测试指令内部 `updateRequest` 同样触发重置。
- **根因**：编辑器 Tab 索引保存在 widget state 中，任何触发编辑器重建的操作（分栏拖动、请求对象更新）都会丢失当前 Tab。响应区 Tab 不受影响。
- **证据**：hopp_m8_04_settings_full.png（截图指令前置动作是切 Settings + 移 divider，成像却是 Params）
- **建议**：Tab 索引上移到 provider（按 request tab id 持有），或编辑器 Tab 视图使用 `AutomaticKeepAliveClientMixin` / 持久 `TabController`。

### UI-04（P3）Request 视图 auto header 判定为硬编码 key 集合

- **现象**：`_isAutoHeader()`（response_viewer.dart:1110）只认 `user-agent / accept-encoding / connection / host` 四个 key。用户若**手动**添加同名 header（如自定义 `Host`），会被误标 `auto` 徽章并归入 "Auto-added Headers"。
- **说明**：审计中看到的 `Accept: */* 无 auto 徽章且 "2 custom" 计数含水`（hopp_m8_08_request.png）系**模拟响应手工构造的 mock 数据**所致，真实发送路径不会自动注入 Accept，不计为缺陷；本条仅保留硬编码集合这一边缘问题。
- **建议**：auto 标记应在构建 request info 时按来源打上（而非按 key 名猜），或至少把判定集合与客户端真实自动注入的 header 对齐。

---

## 测试基建问题（不计入产品瑕疵，修 test-mode 时处理）

| ID | 问题 | 根因 |
|----|------|------|
| TI-01 | `set_window_size` 是死指令 | 只写 `uiTestWindowSizeProvider`，全 lib/ 无监听者，窗口尺寸不会变 |
| TI-02 | `trigger_curl_import_dialog` 是死指令 | `uiTestCurlImportDialogProvider` 定义并赋值，但无任何 UI 监听（sidebar 只监听 import/export/delete） |
| TI-03 | `scroll_response` 无法滚动响应体 | 监听方（response_viewer.dart:91）只驱动 `_certificateScrollController`（Certificate Tab 的控制器），Body 编辑器不受影响；行号滚动同步因此无法自动化验证 |
| TI-04 | `switch_request_tab` / `expand_raw_content_type_dropdown` 不可靠 | one-shot StateProvider 同值重设不触发（需先切其他 Tab 中转）；且 expand 指令内部 `updateRequest` 触发编辑器重建，经 UI-03 把刚切到的 Body tab 重置回 Params，展开信号落到已销毁的 widget 上 |

---

## 已复核、确认非问题

- **Auth Tab "Coming soon…"**、**Cookies Tab "Cookie management coming soon"**：对应 BACKLOG F8.1 / F1.8，为排期中的占位页。
- **Certificate / Timing Tab 按数据有无条件显示**：mock 响应无证书时不显示 Certificate tab，属设计行为。
- **导出对话框 Export 按钮**（2026-08-20 复核）：未选 Collection 时为禁用态（低对比度导致 OCR 误读为缺失），非缺陷。
- **模拟 4xx 的 mock body 内 error 字段与状态码文案不一致**（"Bad Request" vs 422）：mock 数据自身问题，非 UI 缺陷。

## 未覆盖 / 需人工检查

- 侧边栏 Filter 搜索输入（test-mode 无键盘输入能力）
- 真实点击/拖拽交互、右键菜单、快捷键
- CodeEditor 行号与内容滚动同步（BACKLOG 已知 P2；TI-03 修复前无法自动化验证，需人工滚动确认）
- Windows / Linux 平台外观
