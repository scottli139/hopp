# Hopp UI/UX 设计规范

> 本文档与代码严格一致：所有类名、字段名、数值都能在 `lib/theme/`、`lib/widgets/common/` 中找到。
> 设计系统重构方案见 [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)，可视化原型见 [design/design_system_preview.html](./design/design_system_preview.html)。
> 写 UI 前请先读本文件；新增样式违规会被 `test/design_guard_test.dart` 拦截。

---

## 目录

- [设计原则](#设计原则)
- [设计 Token](#设计-token)
- [统一组件](#统一组件)
- [区域布局规格](#区域布局规格)
- [强制遵守机制](#强制遵守机制)
- [暗黑模式](#暗黑模式)

---

## 设计原则

1. **Token 唯一来源**：颜色 / 字号 / 圆角 / 阴影一律取自 `lib/theme/`，禁止字面值（守卫 G1–G7 强制）。
2. **组件优先**：先找 `lib/widgets/common/` 里的统一组件，没有再写新的，不要手写第三套样式。
3. **桌面密度**：面向桌面端的小号高密度 UI（正文 13px、控件高 28/32），不做移动端断点。
4. **亮暗双主题**：只用 `context.appTheme` 语义色，不为暗色单独写一套值。

---

## 设计 Token

### 语义颜色：AppThemeData（随亮/暗主题变化）

`lib/theme/app_theme_data.dart` · `ThemeExtension<AppThemeData>`，20 个字段，通过 `context.appTheme` 访问（未挂载主题时回退 `AppThemeData.light`）。

| 字段 | 用途 | Light | Dark |
|------|------|-------|------|
| `background` | 页面背景 | `#FFFFFF` | `#0F172A` |
| `surface` | 一级表面（卡片 / 侧栏 / 分组容器） | `#F8FAFC` | `#1E293B` |
| `surfaceVariant` | 二级表面（hover / 填充 / 选中底色） | `#F1F5F9` | `#334155` |
| `border` | 常规分隔线 / 边框 | `#E2E8F0` | `#2B3A55` |
| `borderStrong` | 强边框（输入框边、强调分隔） | `#CBD5E1` | `#475569` |
| `textPrimary` | 主要文字 | `#0F172A` | `#F1F5F9` |
| `textSecondary` | 次级文字 | `#475569` | `#94A3B8` |
| `textTertiary` | 占位 / 禁用文字 | `#94A3B8` | `#64748B` |
| `brand` / `brandHover` / `brandSoft` | 品牌色 / hover / 浅底（选中态） | `#6366F1` / `#4F46E5` / `#EEF2FF` | `#818CF8` / `#6366F1` / `#818CF8`@14% |
| `success` / `successSoft` | 成功（2xx / POST）及浅底 | `#10B981` / `#ECFDF5` | 同色 / @14% |
| `warning` / `warningSoft` | 警告（3xx / PUT）及浅底 | `#F59E0B` / `#FFFBEB` | 同色 / @14% |
| `error` / `errorSoft` | 错误（4xx / DELETE）及浅底 | `#EF4444` / `#FEF2F2` | 同色 / @14% |
| `info` / `infoSoft` | 信息（GET）及浅底 | `#3B82F6` / `#EFF6FF` | 同色 / @14% |

用法：`final t = context.appTheme; ... color: t.textSecondary`。

### 常量调色板：AppColors（与主题无关）

`lib/theme/app_colors.dart`，私有构造，全部是静态常量 / 方法。

- 品牌：`brand #6366F1`、`brandLight #818CF8`（暗色主题用）、`brandDark #4F46E5`、`onBrand #FFFFFF`（品牌色上的前景）。
- 基础：`transparent`（替代 `Colors.transparent`）、`black`（半透明遮罩用，如 danger hover 叠加 8%）。
- 语义：`success / warning / error / info`（亮暗通用，值同上表）；`errorStrong #B91C1C`（5xx 专用）；`accentPink #EC4899`（装饰点缀）。
- HTTP 方法色：`methodGet=info`、`methodPost=success`、`methodPut=warning`、`methodDelete=error`、`methodPatch #8B5CF6`、`methodOther #64748B`。
- **唯一入口**：
  - `AppColors.method(String)` —— 方法 → 颜色（未知方法归 `methodOther`）。
  - `AppColors.statusCode(int?)` —— 2xx→success、3xx→warning、4xx→error、5xx→`errorStrong`、null/其他→`methodOther`。

### 文字：AppTextStyles（8 档收敛）

`lib/theme/app_text_styles.dart`。禁止内联 `fontSize`（G3），从这里取或在其上 `copyWith`（仅限字重 / 颜色等非字号属性）。

| 样式 | 字号 / 字重 / 行高 | 用途 |
|------|------|------|
| `display20` | 20 w600 h1.3 | 页面级大标题（极少使用） |
| `title16` | 16 w600 h1.4 | 对话框标题 / 区块标题 |
| `body13` | 13 w400 h1.4 | 正文基准（桌面密度） |
| `caption12` | 12 w400 h1.35 | 辅助说明 / 次级信息 / 侧栏与 Tab 文字 |
| `tiny11` | 11 w500 h1.3 | 徽标文字 / 状态行 |
| `micro10` | 10 w700 h1.2 ls0.2 | 方法徽章等小号强调 |
| `code12` | 12 w400 h1.45 Menlo | 代码 / 等宽文本统一入口（URL 输入、Body） |
| `code11` | 11 w400 h1.4 Menlo | 密集代码场景（KV 行 / 头信息 / 行号） |

### 间距 / 圆角 / 高度 / 动画：AppMetrics

`lib/theme/app_metrics.dart`。禁止 `BorderRadius.circular(数字)` 字面量（G5）。

- 间距（4 的倍数网格）：`space4 / space8 / space12 / space16 / space20 / space24 / space32`。
- 圆角：`radius2 / radius4 / radius6 / radius8 / radius10`，对应 `BorderRadius` 版本 `br2 / br4 / br6 / br8 / br10`。br2 微型徽章、br4 列表行 / 小徽章、br6 按钮 / 输入框 / 菜单、br8 对话框、br10 卡片。
- 控件高度：`height24`（紧凑行 / 小控件）、`height28`（小按钮 / 图标按钮 / 状态栏 / 侧栏行）、`height32`（标准控件：URL 栏 / 主按钮 / 输入框 / Tab 条）、`height36`（宽松控件）、`height38`（响应信息栏）、`height48`（页面头部条 / 侧栏 header）。
- 动画时长：`animFast 100ms`（hover / 开关）、`animNormal 200ms`、`animSlow 300ms`。

### 阴影：AppShadows

`lib/theme/app_shadows.dart`。仅浮层使用，按钮一律无阴影；亮暗两套值按 `Theme.brightness` 自动选择。

- `AppShadows.sm(context)`：开关滑块 / 小浮层（blur 2, y1）。
- `AppShadows.md(context)`：菜单 / 对话框 / 悬浮卡片（blur 12 y4 + blur 3 y1 双层）。

### 语法高亮：AppSyntaxColors

`lib/theme/app_syntax_colors.dart`，JSON/XML 代码视图共用（code_editor 与 optimized_response_viewer 统一来源）。

| Token | Light | Dark（经 `getX(isDark)`） |
|-------|-------|------|
| `key` | `#1E40AF` | `#93C5FD` |
| `string` | `#15803D` | `#86EFAC` |
| `number` | `#2563EB` | `#60A5FA` |
| `keyword`（bool/null） | `#7C3AED` | `#C4B5FD` |
| `punctuation` | `#6B7280` | `#9CA3AF` |

### 主题组装：AppTheme

`lib/theme/app_theme.dart` 的 `AppTheme.light() / dark()`：Material 3，显式 `ColorScheme` 映射 + `AppThemeData.light/dark` 注入 `extensions`。业务代码不直接读 `ColorScheme` 做中性色，优先 `context.appTheme`。

---

## 统一组件

全部位于 `lib/widgets/common/`，亮/暗 golden 见 `test/widgets/common/app_components_golden_test.dart`，实物预览见 Design Gallery（[强制遵守机制](#强制遵守机制)）。

### AppButton / AppIconButton（app_button.dart）

统一按钮。规格：圆角 br6、w500、无阴影；禁用态 opacity 0.45。

- 变体 `AppButtonVariant`（命名构造同名）：`primary`（brand 底 + onBrand 字，hover→brandHover，主操作）；`secondary`（borderStrong 描边 + textPrimary，hover 底 surfaceVariant，次操作）；`ghost`（无边框 textSecondary，hover 底 surfaceVariant + textPrimary，取消 / 低强调）；`danger`（error 底 + onBrand，hover 叠加 black 8%，删除等破坏操作）。
- 尺寸 `AppButtonSize`：`medium` 高 32 / 横 padding 14 / body13（默认）；`small` 高 28 / 横 padding 12 / caption12。可选 `icon`（16/14px，与文字间距 6）。
- `onPressed: null` 即禁用。示例：`AppButton.primary(label: 'Send', icon: Icons.send, onPressed: ...)`。

`AppIconButton`：28×28（`size` / `iconSize` 可调，默认 28 / 16）图标按钮，圆角 br6。默认图标 textSecondary，hover 底 surfaceVariant + 图标 textPrimary；`bordered: true` 加 borderStrong 边框 + background 底（输入区工具按钮）；`color` 覆盖图标色（如 dirty 态用 brand）；支持 `tooltip`；禁用 opacity 0.45。

### AppTextField（app_text_field.dart）

统一输入框（outline 风格）：默认高 32 / 字号 body13，`compact: true` 高 28 / 字号 caption12（工具条/表格行内嵌）；底 background、边 borderStrong、圆角 br6、focus 边 brand 1.5px；占位 textTertiary；横 padding 10。

- 参数：`controller / focusNode / fieldKey / hintText / onChanged / onSubmitted / autofocus / enabled / compact / obscureText / maxLines / expands / height / style / suffix`。`height` 可覆盖固定高度（如侧栏搜索用 30，仅单行生效）；`maxLines > 1` 时盒子包裹内容高度；`expands: true` 撑满父级紧约束（大段粘贴区，文本顶对齐）；`suffix` 在盒内右端嵌控件（如 secret 显隐按钮）；`fieldKey` 挂到内部 TextField 供测试定位。
- **实现红线**：输入框描边必须走 AppTextField 的显式 Container 盒子，不要退回 `SizedBox + InputDecorator(isDense)` 控高——装饰器描边只包「文字行高 + contentPadding」，不会撑满外层 SizedBox（`InputDecoration.constraints` 同样无效），会出现渲染 28 描边 16 的缩水框；也不要给 collapsed 装饰留任何 border 状态为 null，否则会继承主题 inputDecorationTheme 叠出第二道描边。多行/撑满场景同一组件已覆盖。

### AppSwitch / AppCheckbox（app_controls.dart）

- `AppSwitch`：32×18，滑块 14px 白色带 shadowSm；off 底 borderStrong，on 底 brand；animFast 滑动；禁用 opacity 0.45。
- `AppCheckbox`：15×15，圆角 br4；off 1.5px borderStrong 边 + background 底，on 底 brand + 白色对勾（11px）；`label` 非空时右侧带 caption12 文字且整行可点。

### AppTabs（app_tabs.dart）

次级 Tab 条（请求编辑区 / 响应区共用）。规格：条高 32 + 底部 1px border；Tab 高 32、横 padding 12、图标 12、caption12 w500；选中 = brand 文字 + 2px brand 下划线；hover 文字 textPrimary。

- `AppTabItem(label, icon, count, dot)`：`count` 计数徽章（micro10 w600，圆角 br8，选中 brandSoft 底 / 未选中 surfaceVariant 底，如 Params/Headers 条数）；`dot` 5px success 圆点（如 Body 有内容）。
- `backgroundColor` 默认 `surface`。

### AppCard（app_card.dart）

统一卡片容器，圆角 br10，默认 padding space16。

- 默认（standard）：surface 底 + 1px border 边。
- `AppCard.elevated`：background 底 + shadowMd（浮层卡片）。
- `onTap` 非空时包 InkWell。

### MethodBadge / StatusChip（app_badge.dart）

- `MethodBadge(method)`：HTTP 方法徽章。高 18、最小宽 34、横 padding 5、圆角 br4、micro10；方法色文字 + 方法色 soft 底（亮 10% / 暗 14%，组件内部按 brightness 处理）。颜色经 `AppColors.method()`。
- `StatusChip(statusCode, {label})`：状态码徽章。高 22、横 padding 8、圆角 br4、tiny11 w600；颜色经 `AppColors.statusCode()`，底按档位取 successSoft / warningSoft / errorSoft（null 或非 2xx+ 取 surfaceVariant）。`label` 默认 `'$statusCode'`，可传「200 OK」。

### AppDialog / showAppDialog（app_dialog.dart）

统一对话框：圆角 br8、1px border 边、shadowMd、底 background、insetPadding 24。头部 padding 20/16/20/0、title16 标题、右上角 AppIconButton 关闭（24/14，`showClose` 可关）；正文默认 padding 20/16/20/16（大型对话框传 `EdgeInsets.zero` 自行布局）；`actions` 右对齐、间距 8。`width` 默认 420，`height` 可固定（如环境管理）。

业务代码用 `showAppDialog(...)` 弹出，底部按钮统一用 AppButton（惯例：Cancel 用 ghost，确认用 primary / danger）。

### AppPopupMenu / AppPopupSelect（app_popup_menu.dart）

命令菜单（`PopupMenuButton` / `showMenu` / `MenuAnchor`）统一容器与菜单项：

- 容器：`menuShape(theme)` = 圆角 br6 + dividerColor 50% 细边；`menuElevation = 4`；`menuColor(theme)` = colorScheme.surface；MenuAnchor 用 `menuStyle(theme)`。
- 菜单项：高 32、横 padding 12、图标 14（默认 onSurfaceVariant）、文字 caption12 w500。`iconItem`（图标 + 文字命令项，危险操作 icon/label 传 `AppColors.error`）；`textItem`（纯文字选择项，`selected` 时 primary + w600）。

`AppPopupSelect<T>`：值选择场景，**DropdownButton 的统一替代**（其菜单容器无法与本规范对齐）。触发器为「文字 + arrow_drop_down」，当前值在菜单中选中态高亮。

- `boxed: false`（默认）：无边框紧凑触发器，工具栏等极简场景。
- `boxed: true`：带边框表单触发器，规格与 AppTextField 对齐（高 32、background 底、borderStrong 边、br6），菜单宽度 = 触发器宽度；`compact: true` 时高 28（表格行内，与 AppTextField compact 对齐）。
- 参数：`value / items(AppPopupSelectEntry) / onSelected / hint / boxed / compact / textStyle`。

### AppDivider（app_divider.dart）

统一分隔线，替代散落的 `Divider` / `VerticalDivider` / 手写边线。

- `AppDivider()` 水平（线贴底，默认占高 1）；`AppDivider.vertical()` 垂直（线贴左，默认占宽 1）。
- `subtle: true` 用 border × 50%，否则实色 border。`height` / `width` 只改占用空间，不改变线宽。

### AppEmptyState（app_empty_state.dart）

统一空态（侧栏 / 请求编辑区 / 响应区等「无内容」场景）：56×56 surfaceVariant 圆角 br10 底块 + 28px 图标（textTertiary）、标题 body13 w600 textSecondary、可选副标题 caption12 textTertiary、可选 `action` 按钮（如「Create Collection」）。

### 交互反馈（统一约定）

- hover：按钮按变体定义（primary→brandHover、secondary/ghost→surfaceVariant 底、danger→black 8% 叠加），图标按钮 / Tab / 列表行 hover 底 surfaceVariant；过渡统一 animFast（100ms，AnimatedContainer）。
- 禁用：统一组件 `onPressed / onChanged` 传 `null` 即禁用，视觉 opacity 0.45。
- 展开 / 收起等状态切换用 `AppMetrics.animFast`（如侧栏 AnimatedCrossFade、chevron AnimatedRotation）；更长动效用 animNormal / animSlow，不自造时长。

---

## 区域布局规格

以下数值均已从代码核实（`lib/screens/main_screen.dart`、`lib/widgets/layout/sidebar.dart`、`lib/widgets/layout/request_tabs.dart`、`lib/widgets/request/request_editor.dart`、`lib/widgets/request/response_viewer.dart`、`lib/widgets/environment/environment_switcher.dart`）。

### 整体布局

- 水平分栏（MultiSplitView）：侧栏 flex 0.22（min 0.15 / max 0.4），内容区 0.78；分隔条 1px，border×50%，拖拽高亮 brand×50%。
- 内容区垂直分栏：请求编辑区 0.6 / 响应区 0.4。
- 主结构：侧栏 →（请求 Tab 条 + 请求编辑区 + 响应区）→ 状态栏。

### 侧栏

- 容器：surface 底 + 右侧 1px border。
- Header：高 48（`height48`），横 padding 8：品牌 Logo + 「New Collection」按钮（AppIconButton）+ 操作菜单。
- 环境切换器（EnvironmentSwitcher）：盒式高 30，background 底 + border 边 + br6，外边距 左右 8 / 下 8；菜单项复用 AppPopupMenu.textItem，菜单宽 min 160 / max 280。
- 搜索框：AppTextField `compact: true` + `height: 30`，外边距 左右 8 / 下 8，与环境切换器左缘对齐。
- 树区域：横 padding 6 / 纵 2。
- 行：高 28（`height28`），圆角 br4；缩进 `space8 + depth × space12`（请求行再 +12）。
  - Collection 行：chevron 16 + 文件夹图标 16（展开时 brand，否则 brand×70%）+ 名称 caption12。
  - 请求行：MethodBadge + 名称 caption12（选中态 brand 文字 w500）。
  - 选中态：brandSoft 底 + br4 圆角；hover：surfaceVariant 底。
  - ⋮ 菜单按钮 hover / 选中 / 菜单打开时才显现，平时以 28px 占位保持行宽稳定（菜单打开期间必须保持挂载，否则 PopupMenuButton 的 onSelected 会被吞掉）。

### 请求编辑区

- 请求 Tab 条（打开的 Tab，request_tabs.dart）：高 32，surface 底。
- URL 栏：整体高 32（`height32`），白底（background）+ borderStrong 描边，圆角 6。Method 下拉与 URL 输入框 fused 连接（下拉左圆角、输入框右圆角）；URL 文字 code12；Send 用 `AppButton.primary`（高 32），Save 用 bordered `AppIconButton`（dirty 时图标 brand 色）。
- 编辑器 Tab 条（AppTabs，高 32）：Params（count）/ Headers（count）/ Body（dot）/ Auth / Settings。
- Key-Value 编辑器（Headers/Params）：
  - 表头行：高 32，surfaceVariant 底，横 padding 12。
  - 数据行：高 36，横 padding 12；Checkbox + Key 输入 + Info 图标（常见 Header 悬停显示说明）+ Value 输入 + 删除按钮，垂直居中。
  - Headers 启用 key 自动完成，Params 关闭（`showAutocomplete`）。
- Settings Tab：分组卡片式（分组间距 24、组内间距 12、页面 padding 16）。当前分组：SSL/TLS（证书校验开关 + info 提示条）、Redirects（follow redirects 开关 + Maximum redirects 0–50 数字输入）、Coming Soon（禁用占位项）。
- 无打开请求时：AppEmptyState。

### 响应区

- 响应信息栏：高 38（`height38`），background 底 + 底部 border，横 padding 12；内容依次 StatusChip（「200 OK」）、耗时、大小等；网络错误态同栏展示（error 配色，可展开至 150px 看全文）。
- 响应 Tab 条（AppTabs，高 32）：Request / Body / Headers / Cookies，动态追加 Timing（有 timingInfo 时）、Certificate（有 certificateInfo 时）。
- Body 空 / Headers 空：AppEmptyState。
- 大响应体：OptimizedResponseViewer，>50KB（`performanceThreshold = 50000`）进入 Performance 模式（虚拟化 + 初始 500 行 `maxInitialLines`），工具栏提供 Performance / Full / Raw 切换；行号区宽 40、右 padding 8。

### 状态栏

高 28（`height28`），surface 底 + 顶部 border，横 padding 12；左侧品牌徽标 + 版本号（`appVersionProvider`，读取失败回退 `kFallbackAppVersion`，见 `lib/providers/core/app_info_provider.dart`；旧 `lib/utils/constants.dart` 已删除），右侧状态点。

---

## 强制遵守机制

### 设计守卫（静态扫描）

`test/design_guard_test.dart` 扫描 `lib/` 全部 Dart 源码（排除 `.g.dart` / `.freezed.dart` / `lib/l10n/`），注释行不计入。

| 规则 | 内容 | 改用 |
|------|------|------|
| G1 | 禁止 `Colors.*`（Material 色板） | `context.appTheme` / AppColors |
| G2 | 禁止 `Color(0x…)` 字面色值 | 同上 |
| G3 | 禁止内联 `fontSize:` | AppTextStyles |
| G4 | 禁止 `fontFamily:` 字面量 | AppTextStyles.code12/code11 |
| G5 | 禁止 `BorderRadius.circular(数字)` | AppMetrics.br2–br10 |
| G6 | 禁止 `withOpacity(` | `withValues(alpha:)` 或 token |
| G7 | 禁止 `FontWeight.bold` | 显式 w600 / w700 |

G1–G5 白名单 `lib/theme/`（token 定义所在地）；G6/G7 全局适用（含 lib/theme/）。

**基线 ratchet**：存量违规记录在 `test/design_guard_baseline.json`（文件×规则计数），只允许减少、不允许增加；当前基线已为 **0**（`files: {}`），即任何新增违规直接红。误报或违规减少后收紧基线：

```bash
DESIGN_GUARD_UPDATE=1 fvm flutter test test/design_guard_test.dart
```

### Golden 测试

`test/widgets/common/app_components_golden_test.dart`：11 组组件 × 亮/暗双主题（AppButton、AppIconButton、AppTabs、AppDialog、AppSwitch & AppCheckbox、AppCard、AppTextField、Badges、AppPopupSelect、AppDivider、AppEmptyState）。样式回归时该文件变红，先对照 `goldens/` 确认是预期变化再更新：

```bash
fvm flutter test test/widgets/common/ --update-goldens
```

### Design Gallery 走查

`lib/screens/design_gallery/design_gallery_screen.dart`：单页展示全部 token（颜色 / 文字 / 度量 / 阴影）与统一组件的亮/暗双主题效果，与应用全局主题无关（内部各自包 Theme）。通过 test-mode 指令打开（`lib/utils/testing/ui_test_mode.dart`）：

```
open_design_gallery
```

改 token 或统一组件后：① 跑 golden；② 打开 Gallery 肉眼走查亮/暗两区；③ 必要时同步 `docs/design/design_system_preview.html` 原型。

### 新增 UI checklist

1. 颜色 / 字号 / 圆角 / 阴影全部来自 token（过 G1–G7），无 `Color(0x`、无 `fontSize:`。
2. 按钮 / 输入框 / 菜单 / 对话框 / 空态 / 分隔线优先用统一组件；确需新组件则放进 `lib/widgets/common/` 并补 golden + Gallery 展示。
3. 亮 / 暗两个主题都看过（Gallery 或手动切换主题）。
4. 高度落在 height24/28/32/36/38/48 档位内，间距用 space4–32。
5. 对话框用 `showAppDialog`，值选择用 `AppPopupSelect`（禁止 DropdownButton），菜单项用 `AppPopupMenu.iconItem/textItem`。

---

## 暗黑模式

- **不要手写两套颜色**。随主题变化的颜色全部走 `context.appTheme`（`AppThemeData.light / dark` 已在 `AppTheme.light() / dark()` 中注入，主题切换即自动换值）。
- 与主题无关的常量色（方法色、语义主色）用 AppColors；需要 soft 底时用 AppThemeData 的 `*Soft` 字段，不要自己 `withValues` 调透明度（MethodBadge 的 10%/14% 双档是已封装的例外，新代码优先复用 MethodBadge / StatusChip）。
- 阴影用 `AppShadows.sm/md(context)`（内部按 brightness 选值）；语法高亮用 `AppSyntaxColors.getKey(isDark)` 等取值方法。
- 暗色下品牌色自动换 `brandLight` 系（`t.brand` 在 dark 下即 #818CF8），输入框 focus 边等已在 AppTheme / 组件内处理，业务代码无需分支。
