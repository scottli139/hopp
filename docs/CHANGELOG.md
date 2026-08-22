# Hopp 更新日志 (Changelog)

> 记录每个版本的更新内容，按时间正序排列。

---

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-10 | v0.2.0-flutter | Flutter 迁移完成 |
| 2026-03-11 | v0.2.1-unit-tests | 317个单元测试 |
| 2026-03-11 | v0.2.2-widget-tests | 88个 Widget 测试 |
| 2026-03-11 | v0.2.5-ui-ux-fix | 修复 P0 BUG、JSON 语法高亮 |
| 2026-03-11 | v0.2.6-branding | 统一 Logo、修复布局溢出 |
| 2026-03-12 | v0.2.8-shortcuts | 快捷键 + macOS 菜单 |
| 2026-03-12 | v0.2.9-peekaboo | Peekaboo E2E 测试套件 |
| 2026-03-12 | v0.3.0-ui-test-mode | UI 测试模式，支持 HTTP 指令控制 |
| 2026-03-12 | v0.3.1-rename-request | 请求名称编辑功能 + UI 测试验证 |
| 2026-03-12 | v0.3.2-response-optimization | 大响应体渲染优化 + UI 测试 |
| 2026-03-13 | v0.3.3-ui-polish | UI 细节优化：Tab样式、+按钮、输入框对齐、边框统一、高度优化 |
| 2026-03-13 | v0.3.5-ui-fix | URL Bar 对齐修复：Method下拉、URL输入框、Save/Send按钮统一36px高度 |
| 2026-03-13 | v0.3.6-url-focus-fix | 修复 URL 输入框 focus 状态下紫色边框与灰色背景区域高度不一致问题 |
| 2026-03-14 | v0.3.7-timing-analysis | 请求时间分析功能：DNS/TCP/TLS/TTFB/Download |
| 2026-03-14 | v0.3.8-request-editor-ui | Request Editor UI 优化：Tab样式、Headers/Params列表、自动完成 |
| 2026-03-14 | v0.4.0-rc-plan | 请求设置 (Request Settings) 功能规划完成，参考 Postman 实现 |
| 2026-03-16 | v0.5.0-postman-import | Postman 导入/导出功能：Collection/Environment 支持 v2.0/v2.1 格式 |
| 2026-03-14 | v0.4.0-docs-update | 全面更新项目文档，同步实际功能状态 |
| 2026-03-14 | v0.4.1-request-details | 请求详情展示功能：Request Tab (方法/URL/Headers/Body) + UI测试 |
| 2026-03-14 | v0.4.2-request-info | Request Tab 完善：展示实际发送的完整请求信息（含自动添加的 Headers） |
| 2026-03-14 | v0.4.3-test-fix | 修复 22 个单元测试失败：修复 MissingStubError 问题，所有 418 个测试全部通过 |
| 2026-03-14 | v0.4.4-body-type-selector | Body 类型选择器重构：Radio 组样式 + Raw 子类型下拉菜单 |
| 2026-03-14 | v0.4.5-ui-test-debug-guide | 添加 UI 测试调试规范，修复 Release 模式下日志被过滤问题 |
| 2026-03-15 | v0.4.6-body-type-test | Request Body 类型选择器 UI 测试修复完成，日志系统修复 |
| 2026-03-16 | v0.4.9-save-final | Request 保存功能最终修复：移除 isDirty 限制、新请求可直接保存 |
| 2026-03-16 | v0.4.8-save-fix | Request 保存功能修复：新请求自动添加到 Collection、UI 测试验证 |
| 2026-03-16 | v0.5.0-code-editor-fix | Response/Request Body 编辑器修复：禁用 CodeField 内置行号，解决重复行号问题 |
| 2026-03-16 | v0.5.1-border-polish | Body 编辑器边框优化：隐藏左侧边框，Request Body 左右靠边 |
| 2026-03-16 | v0.5.2-border-final | Body 编辑器边框最终修复：完全禁用所有边框，使用 Theme 覆盖 inputDecorationTheme |
| 2026-03-16 | v0.4.7-dropdown-style | Dropdown 样式改进：垂直间距优化、触发按钮样式统一、UI测试验证 |
| 2026-03-16 | v0.5.3-font-update | Code Editor 字体优化：使用 Menlo 等宽字体，代码 12px/行号 11px，行高 1.5，同步更新 UI_UX_GUIDELINES |
| 2026-03-16 | v0.5.4-known-issues | 记录已知问题：Certificate 假数据、Collection 子目录删除问题、行号滚动同步问题 |
| 2026-03-17 | v0.5.5-certificate-real | 修复 Issue #2: Certificate Tab 显示真实 SSL/TLS 证书（使用 SecureSocket 预连接获取） |
| 2026-03-17 | v0.5.6-error-response-fix | 修复 Issue #1: 4XX/5XX 响应正确显示服务端返回内容 |
| 2026-03-17 | v0.5.7-ssl-verify-switch | 实现 SSL 证书验证开关（Request Settings），支持内网自签名证书，优化证书错误提示 |
| 2026-03-17 | v0.5.9-postman-import-fix | 修复 Postman 导入 Raw Content Type 映射问题 (Issue #10): 支持 language 字段和 Content-Type header 推断 |
| 2026-03-17 | v0.5.8-settings-ui-fix | 修复 Request Settings UI 样式问题 (Issue #9): 字号、Switch 尺寸和颜色规范 |
| 2026-03-18 | v0.6.0-curl-import | cURL 导入功能 (F2.6): 解析 cURL 命令创建请求，支持常用选项 (-X, -H, -d, -F, -u, -k, -L 等)，多行命令，44 个单元测试 |
| 2026-03-18 | v0.6.1-curl-import-ux | cURL 导入 UX 改进: 支持编辑请求名称、选择目标 Collection，参考 Postman 导入流程 |
| 2026-03-18 | v0.6.2-dialog-ui-fix | 修复 Issue #7: Import/Export/Delete Collection 对话框 UI/UX 规范 - 统一英文语言、规范字号和按钮样式 |
| 2026-03-18 | v0.6.3-url-params-sync | 实现 Issue #11: URL 查询参数与 Params Tab 双向联动 - URL→Params、Params→URL 同步，36个单元测试 |
| 2026-03-18 | v0.6.4-import-params-fix | 修复 Postman 导入重复参数问题: URL raw 含查询参数时正确提取 base URL |
| 2026-03-19 | v0.6.5-collection-cascade-delete | 修复 Issue #3: Collection 级联删除 - 删除父集合时自动删除所有子集合 |
| 2026-03-19 | v0.6.6-collection-flat-storage | Collection 扁平化存储重构 - 统一使用 parentId 建立层级关系，修复级联删除和显示层级问题 |
| 2026-03-19 | v0.6.7-empty-state-ux | 修复 Issue #6: 初次使用空状态入口指引 - Sidebar/主区域添加 Create 按钮，优化新用户体验 |
| 2026-03-19 | v0.6.8-ci-fix | 修复 GitHub CI 配置: pr-check.yml 使用 `--no-fatal-infos` 与 ci.yml 保持一致，添加生成文件存在性检查 |
| 2026-03-19 | v0.6.9-ci-success | ✅ CI 修复完成: 修复 analysis warnings (unused variable/function/import)，所有任务通过 (analyze-and-test + 3平台构建) |
| 2026-04-01 | v0.7.0 | 版本发布：版本号从 v0.6.9 提升至 0.7.0 |
| 2026-08-20 | v0.7.0-docs | 完善 GitHub Pages 站点：信息型首页 + 文档中心 + 中英文 |
| 2026-08-20 | v0.7.0-ci-fix | 修复 Windows CI：windows-latest 已升级 VS2026，Flutter 3.27 不支持，固定 windows-2022 (VS2022) |
| 2026-08-21 | v0.8.0-m8.0-ui-fix | 修复 M8.0 审计三项布局缺陷：UI-01 Settings 页滚动条指示、UI-02 响应区空态 BOTTOM OVERFLOWED、UI-03 布局重建重置请求编辑器 Tab（幂等分栏 + 索引持久化） |
| 2026-08-21 | v0.8.0-dialog-links-fix | 修复 Issue #8/#14/#16：New Collection/Add Folder 对话框统一规范样式（共用命名对话框组件，支持 Enter 提交）；About 页链接经 url_launcher 跳转外部浏览器；test-mode 新增 tap_at/scroll_at 指针注入与三个触发指令 |
| 2026-08-21 | v0.8.0-m8.1-env-vars | M8.1 环境变量系统：多环境管理 + 全局变量 + `{{var}}` 替换引擎（含动态变量）+ secret 掩码 + 未定义变量警告 + Postman Environment 导入落地；修复 `{{var}}` 被 URL 编码破坏问题；test-mode 新增 10 个环境指令，UI 自动化验收 9/9 通过 |
| 2026-08-21 | v0.8.1-ui04-auto-header | 修复 UI-04：auto header 改为按来源标记（`HttpRequestInfo.autoHeaderKeys`），手填同名 header 不再误标；附带修复 Request 视图长 header key + auto 徽章溢出 |
| 2026-08-21 | v0.8.2-td4-test-mode-fix | 修复 TD-4 测试基建：`set_window_size` 走 macOS 原生通道真实调整窗口；`trigger_curl_import_dialog` 补齐监听；`scroll_response` 支持 body/certificate 目标并回读滚动结果；`switch_request_tab` 时间戳幂等；新增 `dismiss_dialog` 指令 |
| 2026-08-21 | v0.8.3-env-ui-acceptance-fix | 环境变量 UI 全面验收修复：管理对话框 Type 列文字显式着色（修复亮色模式白字不可读）；环境切换器重构为 PopupMenuButton（修复 "No Environment" 按钮折行溢出与菜单折行，菜单宽度自适应内容）；test-mode 修复 `dismiss_dialog` 500（改走根 navigatorKey）、新增 `set_theme_mode` 指令（light/dark/system）；亮/暗双主题截图回归，单元测试 617 通过 |
| 2026-08-21 | v0.8.4-popup-menu-unify | 统一弹出菜单样式：新增 `AppPopupMenu` 共享组件（容器圆角+边框/elevation/底色、菜单项 32px/icon 14/caption）与 `AppPopupSelect` 值选择器（替代全部 `DropdownButton`/`DropdownButtonFormField`：环境变量类型、cURL 导入集合、导出对话框两个选择器）；sidebar 三处 ⋮ 菜单、环境切换器、请求右键菜单、Method/Raw Content-Type MenuAnchor 全部对齐（UI_UX_GUIDELINES 新增「弹出菜单」规范）；顺带修复：请求右键菜单固定 (100,100) 弹出改为指针位置、右键 Rename 无效（接入重命名编辑态）、cURL 导入集合选择器显式着色防白字 |
| 2026-08-21 | v0.8.5-design-system-p1 | 设计系统 P1 基建：新建 lib/theme/ 六文件（AppColors 调色板含方法色/状态码色唯一入口、AppThemeData ThemeExtension 亮暗双套语义色、AppTextStyles 7 档、AppMetrics 度量、AppSyntaxColors、AppTheme 显式 ColorScheme 映射替代 fromSeed）；main.dart 接入 `AppTheme.light()/dark()`；合并 code_editor 与 optimized_response_viewer 两份逐字重复的语法高亮定义；新增 `design_guard_test` 七条静态扫描规则 + baseline ratchet（457 处存量入账，只减不增，CI 必过）；主界面双主题截图回归像素级零差异，测试 618 通过 |
| 2026-08-22 | v0.8.6-design-system-p2 | 设计系统 P2 收口：方法色/状态码色唯一入口 `AppColors.method()/statusCode()`（消灭 4+2 套实现，修复同一 GET 在侧栏与标签栏颜色不一致）；等宽字体统一 Menlo（`AppTextStyles.code12` 单一来源，monospace/JetBrains Mono 用法清除，G4 清零）；新增 `MethodBadge`/`StatusChip`/`AppDivider` 组件并替换散落写法（侧栏方法徽章 8px→10px micro 档、响应信息栏状态徽章统一、Divider/VerticalDivider 16 处）；`withOpacity` 全量迁移 `withValues`（136 处）+ `FontWeight.bold` 清零；constants.dart 死代码清除（dark* 8 色、AppShadows、display/headline/code/methodBadge 样式、死徽章 widget）；顺带修复暗色模式错误条误用浅色 errorLight（改 appTheme.errorSoft）；守卫基线 457→236（-221，目标 -200 达成）；测试 618 全绿 |
| 2026-08-22 | v0.8.7-design-system-p3 | 设计系统 P3 组件层：新增 8 个统一组件 `AppButton`（primary/secondary/ghost/danger × 28/32，无阴影、hover 渐变、禁用 45%）/ `AppIconButton`（28×28 可选边框）/ `AppTextField`（32/28 两档，brand 焦点边）/ `AppDialog`（圆角 8 + 边框 + shadowMd，标题 16 w600 + 关闭 X，按钮区右对齐）/ `AppTabs`（次级 Tab 条 32px，图标+计数徽章+dot，brand 下划线，横向可滚）/ `AppSwitch`（32×18）/ `AppCheckbox`（15px）/ `AppCard`；新增 token `AppShadows`（亮暗双套 sm/md）与 `AppColors.onBrand/transparent/black`；全量迁移：Send/Save/请求与响应 Tab/KV Checkbox/Settings Switch/全部 10 个对话框（sidebar 4 + 导入导出 3 + cURL + 环境管理 + About）+ 空态与工具栏散点按钮；删除死代码 `AppComponentStyles`；组件 golden 测试 16 张双主题基线图上线（test/widgets/common/）；守卫基线 236→163；测试 626 全绿，主界面+6 对话框+编辑区双主题截图审计通过 |
| 2026-08-22 | v0.8.8-design-system-p4 | 设计系统 P4 区域翻新：版本号统一（Issue #13：package_info_plus 从包信息动态读取，状态栏/About 对话框/About 页三处接入，`AppConstants.appVersion` 兜底 + `app_version_test` 守护与 pubspec 同步）；URL 栏 36→32px、灰底填充改白底 + borderStrong 描边、code12 等宽、`{{var}}` brand-soft 高亮（自定义 TextEditingController）、method 选择器换 MethodBadge；响应信息栏空态 36/正常 40/错误 44 → 统一 38px、去阴影；Timing Tab 动态标签「Time: xxx ms」改固定「Timing」（总耗时在内容区展示，标签宽度不再跳动）；侧栏 ⋮ 菜单 hover 才显现（并修复菜单打开期间按钮被行 onExit 卸载、PopupMenuButton `!mounted` 吞掉 onSelected 的真实交互 bug——onOpened/onCanceled 跟踪保活）、行高统一 28、选中态 brand-soft 圆角底（去 3px 左边线）、hover 统一 surfaceVariant、请求名 11→12px；环境切换器改盒式选择器 30px；空态统一新组件 `AppEmptyState`（图标底块+标题+副标题+可选 CTA，替换响应区 3 处手写空态 + 侧栏 + 编辑区无请求 + 主区无活跃 Tab）；请求标签栏激活态白底 + brand 下划线、方法标识改 micro 档纯文字、关闭按钮透明底；响应 Headers 表头 primary 彩色改中性 surfaceVariant + micro 档；Body 工具栏 40→38px；Load more 条按钮层级下调 secondary/ghost；About 页 token 化；分隔线两档归一（dividerColor/outlineVariant 混写 → appTheme.border / border×50%，含 MultiSplitView 分隔条）；logo PNG 白底方块问题修复（About 页/About 对话框/欢迎页三处换 logo.svg，暗色不再露白块）；守卫基线 163→120；测试 627 全绿，18 场景双主题截图审计通过 |
| 2026-08-22 | v0.8.9-design-system-p5 | 设计系统 P5 闭环：**守卫基线 120→0 清零**（12 个业务文件全量 token 化：内联 fontSize 8/9px 升档 10、等宽 10/11 归并新档 `code11`、Colors./Color(0x)/BorderRadius 字面量清除、colorScheme 残留映射 appTheme）；**`lib/utils/constants.dart` 删除**（AppConstants 间距/圆角/动画并入 AppMetrics，新增 `height48`/`radius2`/`br2`；幽灵 AppColors/AppTextStyles 清除；appVersion 兜底迁 `kFallbackAppVersion`（app_info_provider.dart），app_version_test 同步）；新 token `AppTextStyles.code11`、`AppColors.accentPink`；**AppPopupSelect boxed 规格与 AppTextField 对齐**（固定高 32、新增 compact 28、底 background、边 borderStrong），修复环境管理对话框 Name 无框/Type 选择器无盒/行内控件高度不一三处视觉缺陷；**Design Gallery 页面**（test-mode `open_design_gallery`，单页展示全部 token 与组件亮暗双主题）；组件 golden 补齐 AppPopupSelect/AppDivider/AppEmptyState（共 11 组 22 张双主题）；UI_UX_GUIDELINES.md 按代码现状全量重写；AGENTS.md 新增设计守门条款；测试 627+ 全绿，analyze 0 error/warning |
| 2026-08-22 | v0.9.0-textfield-render-fix | 修复输入框描边缩水（用户截图发现环境管理对话框同页 16/18/24/28 四种高度）：根因是 `InputDecorator(isDense)` 描边只包「文字行高 + contentPadding」，外层 SizedBox 只影响布局不影响描边（`InputDecoration.constraints` 同样无效，widget test 量 render box 量不出、golden 单组件目检难以察觉）；`AppTextField` 重写为显式 Container 盒子 + collapsed 装饰（全部 border 状态显式置空防主题继承第二道描边），渲染盒 == 绘制盒可测试；新增 `enabled`/`suffix`/`fieldKey`/`expands` 参数，删除静态 `decoration()` 方法；环境管理对话框 Name（32）/Key/Value/secret（28）/Type 下拉（28）全对齐，cURL 粘贴区文字溢出描边框的同族问题一并修复；新增 AppTextField 规格测试 7 个 + 环境对话框行高一致性回归测试；组件 golden 更新目检通过；测试 638 全绿，analyze 0 error/warning |
| 2026-08-22 | v0.9.1-theme-switcher | 侧栏新增主题切换开关：新增统一组件 `AppSegmentedControl`（24px 分段选择器：surfaceVariant 容器 br6、段 28/图标 13、选中段 surface 底 + shadowSm + brand 图标、未选中 textTertiary/hover textPrimary、每段 Tooltip）；侧栏底部 footer 接入三段切换（跟随系统/浅色/深色，经 `updateThemeMode` 持久化 `AppSettings.themeMode`——该设置项数据层与 l10n 文案早已就绪，此前无 UI 入口，只能跟随系统或走 test-mode 指令）；新增组件规格测试 4 个 + golden 双主题基线 + 侧栏 footer 渲染与持久化测试 2 个；test-mode 亮/暗截图目检通过（选中态正确、对比度正常）；测试 645 全绿 |
