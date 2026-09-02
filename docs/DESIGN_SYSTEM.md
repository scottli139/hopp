# Hopp 设计系统重构方案

> 目标：把 Hopp 的视觉品质提升到商业产品水准，并建立「规范能被强制遵守」的长期机制。
> 配套原型：`docs/design/design_system_preview.html`（浏览器打开，含 token、组件、主界面双主题 mockup）。
> 状态：**P1–P5 全部完成**（P1 2026-08-21，P2–P5 2026-08-22）：lib/theme/ + 守卫基线上线并清零（457→0）；方法色/状态码色唯一入口、Menlo 统一、MethodBadge/StatusChip/AppDivider 落地、withOpacity/FontWeight.bold 清零；**8 个统一组件落地**（AppButton/AppIconButton/AppTextField/AppDialog/AppTabs/AppSwitch/AppCheckbox/AppCard），Send/Save/全部 10 个对话框/请求与响应 Tab/KV 控件完成迁移，AppComponentStyles 已删除；**P4 区域翻新完成**：版本号统一（Issue #13，package_info_plus + pubspec 同步守护测试）、URL 栏 32px 白底 borderStrong + `{{var}}` 高亮、响应信息栏统一 38px、Timing Tab 固定标签、侧栏 hover ⋮（含菜单保活修复）与行高 28、环境切换器盒式 30px、空态统一 `AppEmptyState`、分隔线两档归一、logo SVG 化修暗色白块；**P5 闭环完成**：`lib/utils/constants.dart` 删除（AppConstants 并入 AppMetrics，appVersion 兜底迁 `kFallbackAppVersion`）、幽灵 AppColors/AppTextStyles 清除、守卫基线 120→0；新增 token `code11`/`accentPink`/`br2`/`height48`；`AppPopupSelect` boxed 规格与 AppTextField 对齐（高 32/compact 28、底 background、边 borderStrong），环境管理对话框 Name/Type 控件盒式化且行高对齐；Design Gallery 页面上线（test-mode `open_design_gallery`，单页全 token/组件双主题）；组件 golden 补齐至 12 组 24 张；UI_UX_GUIDELINES.md 按代码现状重写；AGENTS.md 新增守门条款；**输入框渲染修复（2026-08-22 下午）**：发现并根治 InputDecorator isDense 描边不随外层 SizedBox 撑高的框架级陷阱（渲染 28 描边仅 16，环境对话框同页 4 种高度），AppTextField 改显式 Container 盒子（新增 enabled/suffix/fieldKey/expands），环境对话框与 cURL 粘贴区全对齐，新增规格测试 + 行高一致性回归测试；**主题切换（2026-08-22 晚）**：新增统一组件 `AppSegmentedControl`（app_segmented_control.dart，24px 分段选择器：surfaceVariant 容器 + 选中段 surface 底/shadowSm/brand 图标），侧栏底部 footer 接入主题三段开关（system/light/dark，持久化 `AppSettings.themeMode`——该设置项此前只有数据层与 l10n 文案，无 UI 入口），组件规格测试 + golden 双主题基线 + 侧栏渲染/持久化测试，test-mode 双主题截图目检通过；**环境管理对话框重设计（2026-08-24）**：原型先行（docs/design/environment_manager_preview.html）后落地——`AppTextField` 新增 `borderless` 模式（透明底边，hover/focus 才显边框，表格单元格与行内标题场景）、`AppIconButton` 新增 `danger` hover 变体（errorSoft 底 + error 图标）、`AppDialog` 新增 `showDividers`/`footerLeading`；对话框背景分层（侧栏 surface/主区 background）、变量类型选择徽章化（string 中性/secret 琥珀带锁，替代 boxed 下拉）、Add Variable 虚线行、空状态居中引导、侧栏分组标签 + 激活环境绿点；**添加提取规则按钮合规（2026-08-25）**：预请求链编辑器手写 InkWell 按钮（tiny11/13px 图标/textTertiary/无 hover）替换为 `AppButton.secondary`，与同屏「添加步骤」规格对齐，test-mode 双主题截图目检通过；**M8.3 / M8.4 视觉同步（2026-08-28）**：导入对话框三页签合并（Postman/cURL/OpenAPI，IndexedStack 常驻面板）、请求编辑器新增 Assertions 页签、响应区新增 Tests 页签（n/m passed 徽标）、Export 对话框 FORMAT 双选项卡片 + secret 提示条——全部复用既有 token/组件，design_guard 零新增违规，状态行更新至 2026-08-31；**界面缩放（2026-09-02，F5.7/M8.7/v0.15.0）**：侧栏 footer 新增 format_size 弹出菜单（100%/125%/150%，AppPopupMenu.textItem 选中态），`AppSettings.uiScale` 经 `MaterialApp.builder` 的 `MediaQuery(textScaler:)` 全局缩放文字——token 定义、布局度量（AppMetrics）与 golden 基线（默认 1.0）均不变，守卫零新增，ARM64 HiDPI 实机 150% 双主题审计通过

---

## 1. 现状审计结论

2026-08-21 对 `lib/`（约 11k 行 UI 代码）全量盘点 + 双主题截图审计，核心数据：

### 1.1 三套取色途径并存，规范与代码脱节

| 途径 | 用量 | 问题 |
|------|------|------|
| `colorScheme.*`（fromSeed 生成） | 373 处 | 运行时产物与 `AppColors` token 是两套独立体系，混用 |
| `AppColors.*`（constants.dart） | 119 处 | 一半是死代码（dark\* 8 色、AppShadows 等零引用） |
| 硬编码 `Color(0x…)` / `Colors.xxx` | 97 处（UI 代码） | 品牌粉 `#EC4899` 5 处不在任何 token；warning 重复定义 3 处 |

### 1.2 最典型的 10 个不一致

1. HTTP 方法色 **4 套实现**：`AppColors.getHttpMethodColor` vs `request_tabs.dart` 裸 Material 色 vs `response_viewer.dart` 两个重复 switch——同一 GET 在侧栏与标签栏颜色不同
2. 状态码色 **2 套**：token `#10B981` vs 响应区 `Colors.green`
3. 语法高亮类 **整份重复**：`optimized_response_viewer.dart` 与 `code_editor.dart` 逐字相同
4. 等宽字体 **3 套**：Menlo ×11 / monospace ×7 / token JetBrains Mono 零使用
5. 分隔线 **7 种写法**：dividerColor 实色 / ×0.5 / ×0.3 / outlineVariant 实色 / ×0.5 / outline×0.15–0.5 / grey.shade300·700
6. 方法徽章规格 8/9/10/11px 随机，token `methodBadge` 无人用
7. 按钮双轨：对话框走 `AppComponentStyles`（25 处），主界面全手写（Send 是全 App 唯一 elevation 2 按钮；Save 用 GestureDetector）
8. `withOpacity` 148 处 14 种 alpha，又混入 4 处 `withValues`
9. 规范文档类名（NeutralColors/AppSpacing/ButtonStyles…）在代码中不存在；规范 URL 栏 32px vs 代码 36px；正文 14px 名存实亡（实际 10–13px）
10. 暗色隐患：`response_viewer.dart:285` 错误条直接用浅色 `errorLight`

### 1.3 根因

- **token 层不可信**：定义了但数值与现状脱节、一半是死代码，开发者自然绕开
- **组件层缺失**：只有菜单选择器统一了，按钮/输入/徽章/对话框/Tab 均无封装
- **没有反馈回路**：规范写在文档里，违反零成本，CI 不检查

---

## 2. 目标设计系统

设计原则：**密度优先**（对标 Postman/VS Code）、**单一事实来源**（token→主题→组件）、**语义化命名**（暗色零分支）、**克制即专业**（分隔线 2 档、圆角 4 档、阴影仅浮层）。

### 2.1 架构：三层单向依赖

```
lib/theme/                    ← 唯一允许出现色值/字号/尺寸字面量的地方
  app_colors.dart               品牌色 + 语义色 + 方法色/状态码色唯一入口（原始调色板）
  app_theme_data.dart           AppThemeData extends ThemeExtension：语义颜色亮暗双套
                                （surface/surfaceVariant/border/borderStrong/
                                  textPrimary/Secondary/Tertiary、语义色+*Soft）
  app_text_styles.dart          7 档命名样式（display20/title16/body13/caption12/tiny11/micro10/code12）
  app_metrics.dart              间距(4·8·12·16·20·24·32)、圆角(4·6·8·10)、高度(24/28/32/36)、动画
  app_syntax_colors.dart        语法高亮亮暗双套（合并现有两份重复定义）
  app_theme.dart                AppTheme.light()/dark()：显式映射 token → ThemeData
                                （不再 fromSeed；补齐 textTheme/dividerTheme/iconTheme/
                                  buttonTheme/popupMenuTheme/tooltipTheme/scrollbarTheme）
        ↓ 依赖
lib/widgets/common/           ← 组件层（只引用 theme）
  app_button.dart               AppButton(primary/secondary/ghost/danger × s28/m32) + AppIconButton
  app_text_field.dart           AppTextField(outline/plain-KV) 
  app_badge.dart                MethodBadge / StatusChip / DotIndicator
  app_tabs.dart                 AppTabs（次级 tab 条：icon+label+count+dot，32px）
  app_dialog.dart               AppDialog（圆角 8、title 16 w600、按钮区右对齐）
  app_controls.dart             AppSwitch(32×18) / AppCheckbox(15px) / AppRadio
  app_divider.dart              AppDivider（H/V，border 或 border50% 两档）
  app_card.dart                 AppCard(standard/elevated)
  app_popup_menu.dart           已有，保留
        ↓ 依赖
lib/widgets/… lib/screens/…   ← 业务层：只组装组件与 token，禁止字面量
```

关键决策：

- **语义颜色走 `ThemeExtension`**（`context.appTheme.border`），暗色主题只是另一套取值，消灭 `AppColors.light*` 硬编码与 colorScheme/fromSeed 混用
- **ColorScheme 显式映射** token（primary=brand 等），不再 `fromSeed` 随机生成
- **UI 字体用系统栈**（Inter/JetBrains Mono 未打包，现状声明实际无效），代码字体统一 **Menlo**
- **字号收敛 7 档**：20/16/13/12/11/10 + code 12；废弃 8/9/14/18/24（9px 徽章并入 10px micro）
- **分隔线只有两档**：`border`（实色）与 `border × 50%`，其余 7 种写法废弃
- **URL 栏 / 主按钮统一 32px**（规范值），现状 36px 在 P4 调整并截图验证
- **方法色/状态码色唯一入口** `AppColors.method(String)` / `AppColors.statusCode(int?)`
- 阴影仅浮层（菜单/对话框）用 `shadowSm/shadowMd`；按钮一律无阴影

### 2.2 token 全表

见原型页 `docs/design/design_system_preview.html`（色彩/字体/间距三节即 token 定义，实施时照抄数值）。中性色沿用 Slate 系：亮色 `#FFFFFF/#F8FAFC/#F1F5F9/#E2E8F0/#CBD5E1`，暗色 `#0F172A/#1E293B/#334155/#2B3A55/#475569`。

---

## 3. 执行保障机制（让规范被遵守）

### 3.1 设计守卫测试（核心，零新依赖）

`test/design_guard_test.dart`：Dart 测试直接读 `lib/` 源码做静态扫描，CI 必过（现有 `flutter test` 已在 CI）。

| 规则 | 禁止模式 | 白名单 |
|------|----------|--------|
| G1 | `Colors.`（Material 色板） | `lib/theme/`、test |
| G2 | `Color(0x` 字面量 | `lib/theme/`、test |
| G3 | 内联 `TextStyle(` 含 `fontSize:` | `lib/theme/` |
| G4 | `fontFamily:` 字面量 | `lib/theme/` |
| G5 | `BorderRadius.circular(数字)` | `lib/theme/` |
| G6 | `withOpacity(` | 全禁（统一 `withValues(alpha:)` 或 token） |
| G7 | `FontWeight.bold` | 全禁（显式 w600/w700） |

**基线 ratchet**：现存违规记录在 `test/design_guard_baseline.json`（按 文件×规则 计数），测试断言「实际 ≤ 基线」，违规减少时自动要求收紧基线——只减不增，渐进清零。这样机制第一天就能上线而不必一次性修完 600+ 处存量。

### 3.2 组件 Gallery + Golden Test

- test-mode 新指令 `open_design_gallery`：单页展示全部 token 与 common 组件的双主题渲染，是设计验收的「活规范」
- 核心组件（AppButton/AppBadge/AppTabs/AppDialog/MethodBadge/StatusChip）配 `matchesGoldenFile` 测试（双主题），样式回归 CI 直接变红

### 3.3 截图审计固化

`integration_test/ui_audit_screenshots.py`（一键遍历主界面/请求响应各 Tab/全部对话框 × 亮暗主题）纳入 TESTING.md：任何 UI 改动提交前必须跑一遍并对照。

### 3.4 规范镜像 + 守门条款

- 重写 `docs/UI_UX_GUIDELINES.md`：只写与代码一致的内容（真实类名、真实数值、真实用法），删除幽灵类；每个组件给「用法 / 反例」
- `AGENTS.md` 增加「UI 变更四步」：查规范 → 用 common 组件 → 过守卫测试 → 跑截图审计
- （后续可选）评估 `custom_lint` 提供 IDE 实时提示，列入 BACKLOG，不阻塞本方案

---

## 4. 实施路线

5 个阶段，每个阶段独立提交、独立验收（全量测试 + 双主题截图对照），风险递进、视觉变化递进：

| 阶段 | 范围 | 视觉变化 | 验收 |
|------|------|----------|------|
| **P1 基建** | 新建 `lib/theme/`；`AppThemeData` ThemeExtension 接入 main.dart；ColorScheme 显式映射；合并语法高亮两份重复；守卫测试 + 基线上线 | 无（token 数值先对齐现状） | 617 测试全绿；截图与基线像素级一致 |
| **P2 收口** | 方法色/状态码色唯一入口（消灭 4+2 套实现）；Menlo 统一；`AppDivider` 统一 Divider 系写法（Container 边线分隔归 P4）；徽章统一 MethodBadge/StatusChip；`withOpacity`→`withValues` | 细微（颜色微调） | 守卫基线减少 ≥200 处（实际 -221）；截图对照 |
| **P3 组件** | `AppButton/AppIconButton/AppTextField/AppDialog/AppTabs/AppSwitch/AppCheckbox/AppCard` 落地；替换 Send/Save/工具栏/全部对话框/响应区 Tab | 明显（按钮、对话框、Tab 统一） | 组件 golden 建立；截图审计通过 |
| **P4 翻新** ✅ | 侧栏/request editor/response viewer/env manager/About 逐区域 polish：间距网格、hover/focus 统一、空态、URL 栏 32px、响应信息栏 38px 统一、版本号统一（Issue #13）、Timing Tab 固定标签 | 显著 | 全量截图审计双主题通过（18 场景）；守卫基线 163→120；测试 627 全绿 |
| **P5 闭环** ✅ | Gallery + 组件 golden 补齐；UI_UX_GUIDELINES 重写；AGENTS 守门条款；守卫基线清零、删除幽灵 token | — | 基线 120→0；constants.dart 删除；golden 11 组 22 张；文档与代码一致 |

工作量预估：P1 0.5d · P2 1d · P3 2d · P4 2–3d · P5 1d。

---

## 5. 已确认的取舍

- **不做**：引入第三方字体文件（包体积/版权）、custom_lint（后续再说）、响应式/mobile 布局（桌面工具定位不变）
- **品牌色不变**：Indigo `#6366F1` 保留识别度；粉色渐变仅保留在 logo
- **正文 13px** 为基准（桌面密度），不回到规范的 14px——规范文档按现实修正
- **9px 徽章字号废弃**，统一 10px micro（与 8/9/11 混用现状对齐到单档）
