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
