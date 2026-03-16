# Hopp UI/UX 设计规范

> 本文档定义 Hopp 产品的视觉设计规范和交互设计原则，确保产品具有专业、现代的审美水准和优秀的用户体验。

---

## 📋 目录

- [设计原则](#设计原则)
- [色彩系统](#色彩系统)
- [字体系统](#字体系统)
- [间距系统](#间距系统)
- [组件规范](#组件规范)
- [布局规范](#布局规范)
- [交互规范](#交互规范)
- [暗黑模式](#暗黑模式)
- [Key-Value 编辑器规范](#key-value-编辑器规范)
- [Certificate Tab UI 规范](#certificate-tab-ui-规范)
- [Timing Tab UI 规范](#timing-tab-ui-规范)
- [Request Tab UI 规范](#request-tab-ui-规范)
- [Request Settings UI 规范](#request-settings-ui-规范)
- [图标规范](#图标规范)
- [快捷键](#快捷键)
- [无障碍](#无障碍)

---

## 设计原则

### 1. 简洁清晰

- 减少视觉噪音，保持界面清爽
- 信息层次分明，重点突出
- 避免过度装饰，以内容为中心

### 2. 一致性

- 统一的设计语言贯穿整个产品
- 相似的交互模式保持一致
- 使用标准化的组件和样式

### 3. 效率优先

- 减少用户操作步骤
- 提供快捷操作和快捷键
- 界面响应迅速，反馈及时

### 4. 专业质感

- 精致的细节处理
- 恰到好处的动画效果
- 符合开发者工具的设计惯例

---

## 色彩系统

### 主色调

```dart
class AppColors {
  // 主色
  static const primary = Color(0xFF6366F1);      // Indigo 500
  static const primaryLight = Color(0xFF818CF8); // Indigo 400
  static const primaryDark = Color(0xFF4F46E5);  // Indigo 600
  
  // 辅助色
  static const secondary = Color(0xFF8B5CF6);    // Violet 500
  static const success = Color(0xFF10B981);      // Emerald 500
  static const warning = Color(0xFFF59E0B);      // Amber 500
  static const error = Color(0xFFEF4444);        // Red 500
  static const info = Color(0xFF3B82F6);         // Blue 500
}
```

### HTTP 方法颜色

```dart
class HttpMethodColors {
  static const get = Color(0xFF3B82F6);      // Blue 500
  static const post = Color(0xFF10B981);     // Emerald 500
  static const put = Color(0xFFF59E0B);      // Amber 500
  static const delete = Color(0xFFEF4444);   // Red 500
  static const patch = Color(0xFF8B5CF6);    // Violet 500
  static const head = Color(0xFF6B7280);     // Gray 500
  static const options = Color(0xFF6B7280);  // Gray 500
}
```

### 状态码颜色

```dart
class StatusCodeColors {
  static const success = Color(0xFF10B981);  // 2xx
  static const redirect = Color(0xFFF59E0B); // 3xx
  static const clientError = Color(0xFFEF4444); // 4xx
  static const serverError = Color(0xFFDC2626); // 5xx
}
```

### 中性色

```dart
class NeutralColors {
  // 浅色模式
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9FAFB);
  static const surfaceVariant = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  
  // 深色模式
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkBorder = Color(0xFF334155);
  static const darkDivider = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkTextTertiary = Color(0xFF6B7280);
}
```

---

## 字体系统

### 字体栈

```dart
class AppFonts {
  static const ui = 'Inter';
  static const mono = 'JetBrains Mono';
  static const fallback = ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto'];
}
```

### 字号规范

| 样式 | 字号 | 字重 | 行高 | 用途 |
|-----|------|------|------|------|
| Display | 24px | 600 | 32px | 页面标题 |
| Headline | 18px | 600 | 28px | 区块标题 |
| Title | 16px | 600 | 24px | 卡片标题 |
| Subtitle | 14px | 500 | 20px | 子标题 |
| Body | 14px | 400 | 20px | 正文内容 |
| Body Small | 13px | 400 | 18px | 次要文字 |
| Caption | 12px | 500 | 16px | 标签、提示 |
| Tiny | 11px | 500 | 14px | Tab 文字、徽章 |
| Micro | 10px | 500 | 12px | Certificate 标签 |
| Nano | 9px | 600 | 11px | Sidebar Method badge |
| Code | 13px | 400 | 18px | 代码显示 |
| Code Small | 11px | 400 | 16px | 性能模式代码 |

### 实际应用规范

| 位置 | 字号 | 字重 | 说明 |
|------|------|------|------|
| Request/Response Tab | 11px | 500 | 统一使用 Tiny |
| Sidebar 请求名 | 11px | 400 | 紧凑显示 |
| Sidebar Method badge | 9px | 600 | Nano 字号 |
| Certificate 标签 | 10px | 400 | Micro 字号 |
| Certificate 值 | 11px | 400 | Tiny 字号 |
| Certificate 标题 | 13px | 600 | 卡片标题 |
| Response Tab | 10px | 500 | 比 Request Tab 更小 |
| URL 输入框 | 13px | 400 | Body Small |
| Headers/Params 表头 | 11px | 500 | Tiny |
| Key-Value 输入框 | 12px | 400 | Caption |

```dart
class AppTextStyles {
  static const display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );
  
  static const headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.55,
  );
  
  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );
  
  static const tiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
  
  static const code = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
    fontFamily: 'JetBrains Mono',
  );
}
```

---

## 间距系统

### 基础单位

```dart
class AppSpacing {
  static const unit = 4.0;
  
  static const xs = 4.0;   // 4px
  static const s = 8.0;    // 8px
  static const m = 12.0;   // 12px
  static const l = 16.0;   // 16px
  static const xl = 24.0;  // 24px
  static const xxl = 32.0; // 32px
  static const xxxl = 48.0; // 48px
}
```

### 组件间距

| 组件 | 内边距 | 间距 |
|-----|-------|------|
| Sidebar Item | 8px 12px | - |
| Sidebar Divider | - | 1px |
| Tab | 8px 16px | 0 |
| Card | 16px | - |
| Input | 10px 12px | - |
| Button (S) | 6px 12px | - |
| Button (M) | 8px 16px | - |
| Button (L) | 12px 24px | - |
| Section | - | 16px |

### 高度规范

| 组件 | 高度 | 说明 |
|-----|------|------|
| URL Bar | 32px | Method下拉、URL输入框、按钮统一 |
| Method Dropdown | 32px | 与 URL Bar 对齐 |
| Method 选项 | 36px | 下拉菜单选项高度 |
| Request Tab | 32px | 图标+文字+状态指示器 |
| Request Editor Tabs | 28px | 次级 Tab，更紧凑 |
| Response Tab | 28px | 字体 10px |
| SegmentedButton | 28px | Content Type 切换 |
| Key-Value Row | 36px | Headers/Params 列表行高 |
| StatusBar | 28px | 底部状态栏 |
| Send/Save Button | 32px | 与 URL Bar 统一 |

### 对齐规范

| 元素 | 对齐规则 |
|-----|----------|
| URL Bar | Method下拉、URL输入框、按钮高度统一，底部对齐 |
| URL Focus 边框 | TextField 完全控制边框，紫色边框与灰色背景区域对齐 |
| Key-Value 行 | Checkbox、Key输入框、Info图标、Value输入框、Delete按钮垂直居中对齐 |
| Tab 文字 | 统一使用 11px，垂直居中 |
| Sidebar 图标 | 与文字垂直居中对齐 |

---

## 组件规范

### 按钮

#### 尺寸

| 尺寸 | 高度 | 水平内边距 | 字体 |
|-----|------|-----------|------|
| Small | 28px | 12px | 12px Medium |
| Medium | 36px | 16px | 13px Medium |
| Large | 44px | 24px | 14px Medium |

#### 样式

```dart
class ButtonStyles {
  // 主要按钮
  static final primary = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
  
  // 次要按钮
  static final secondary = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
  
  // 幽灵按钮
  static final ghost = TextButton.styleFrom(
    foregroundColor: AppColors.textSecondary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
```

### 输入框

#### 尺寸

| 尺寸 | 高度 | 水平内边距 | 字体 |
|-----|------|-----------|------|
| Small | 28px | 10px | 12px |
| Medium | 32px | 12px | 13px |
| Large | 36px | 16px | 14px |
| XLarge | 44px | 16px | 14px |

#### URL Bar 专用输入框

```dart
// URL 输入框样式规范
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerHighest,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
      borderSide: BorderSide(color: theme.colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
  ),
)
```

**关键点**:
- 高度统一 32px
- TextField 完全控制背景和边框（避免外层 Container 叠加）
- Focus 状态紫色边框与背景区域完全对齐
- 文字垂直居中

#### 样式

```dart
class InputStyles {
  static final outline = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: NeutralColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: NeutralColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.error),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}
```

### 标签

```dart
class TagStyles {
  // HTTP 方法标签
  static Widget httpMethod(String method) {
    final color = HttpMethodColors.getColor(method);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  
  // 状态标签
  static Widget status(int code) {
    final color = StatusCodeColors.getColor(code);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$code',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
```

### 卡片

```dart
class CardStyles {
  static final standard = BoxDecoration(
    color: NeutralColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: NeutralColors.border),
  );
  
  static final elevated = BoxDecoration(
    color: NeutralColors.background,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
}
```

### 开关 (Switch/Toggle)

#### 尺寸

| 尺寸 | 宽度 | 高度 | 圆角 |
|-----|------|------|------|
| Default | 40px | 24px | 12px |
| Small | 32px | 18px | 9px |

#### 样式

```dart
class SwitchStyles {
  // 开启状态
  static final active = SwitchThemeData(
    thumbColor: MaterialStateProperty.all(Colors.white),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.primary;
      }
      return NeutralColors.border;
    }),
    trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
  );
}
```

#### 使用规范

- 开关右侧显示状态文字："ON"/"OFF" 或 "开启"/"关闭"
- 状态文字使用 12px Regular，颜色为 textSecondary
- 开关与文字间距：8px

### 下拉选择 (Dropdown)

#### 尺寸

| 尺寸 | 高度 | 水平内边距 | 字体 |
|-----|------|-----------|------|
| Small | 28px | 10px | 12px |
| Medium | 32px | 12px | 13px |

#### 样式

```dart
class DropdownStyles {
  static final outline = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: NeutralColors.border),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    isDense: true,
    suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
  );
}
```

---

## 布局规范

### 整体布局

```
┌─────────────────────────────────────────────────────┐
│                     MainScreen                       │
├──────────┬──────────────────────────────────────────┤
│          │              RequestArea                  │
│  Sidebar │  ┌─────────────────────────────────────┐  │
│  22%     │  │           RequestTabs               │  │
│          │  ├─────────────────────────────────────┤  │
│          │  │                                     │  │
│          │  │         RequestEditor               │  │
│          │  │         (Vertical Split)            │  │
│          │  │                                     │  │
│          │  ├─────────────────────────────────────┤  │
│          │  │         ResponseViewer              │  │
│          │  │                                     │  │
│          │  └─────────────────────────────────────┘  │
├──────────┴──────────────────────────────────────────┤
│                    StatusBar (28px)                  │
└─────────────────────────────────────────────────────┘
```

### 侧边栏

- 宽度：22% (可调整，范围 15%-40%)
- 最小宽度：200px
- 背景色：surface
- 右侧边框：1px divider

### 标签栏

- 高度：36px
- 标签样式：文字 + 关闭按钮
- 活动标签：底部 2px 主色指示器
- 背景：surface

### Request Editor Tabs

- 高度：28px
- 标签样式：图标 + 文字 + 状态指示器
- 状态指示器：
  - Body Tab：有内容时显示绿色圆点（4px）
  - Headers/Params Tab：显示数量标记（如 "Headers 11"）
- 选中状态：底部 2px 主色指示线
- 字体：11px Medium
- 间距：Tab 之间 4px

```dart
Widget _buildTabItem({
  required IconData icon,
  required String label,
  String? badge,        // 数量标记
  bool hasDot = false,  // 绿色圆点指示器
  required bool isActive,
  required VoidCallback onTap,
}) {
  return Container(
    height: 28,
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: isActive
        ? Border(bottom: BorderSide(color: AppColors.primary, width: 2))
        : null,
    ),
    child: Row(
      children: [
        Icon(icon, size: 14),
        SizedBox(width: 6),
        Text(label, style: AppTextStyles.tiny),
        if (badge != null) ...[
          SizedBox(width: 4),
          Text(badge, style: AppTextStyles.caption),
        ],
        if (hasDot) ...[
          SizedBox(width: 4),
          DotIndicator(color: AppColors.success),
        ],
      ],
    ),
  );
}
```

### Response Viewer Tabs

- 高度：28px
- 字体：10px Medium（比 Request Tab 更小）
- 标签样式：图标 + 文字
- 动态 Tab：Certificate Tab 仅在 HTTPS 响应时显示
- 选中状态：底部 2px 主色指示线

**Tab 顺序**: Body → Headers → Cookies → Certificate → Timing → Request

### URL Bar

```
┌──────────────────────────────────────────────────────────────────────┐
│ [GET ▼] [URL Input                    ] [💾 Save] [▶ Send]          │
│  32px          32px（与两侧对齐）            32px      32px           │
└──────────────────────────────────────────────────────────────────────┘
```

- 整体高度：32px
- Method Dropdown：左侧圆角，宽度自适应
- URL Input：右侧圆角，与 Method fused 连接
- 按钮：与输入框高度一致，Send 按钮使用主色填充

### 响应式断点

| 断点 | 宽度 | 行为 |
|-----|------|------|
| Mobile | < 768px | 隐藏 Sidebar，使用抽屉 |
| Tablet | 768px - 1200px | 缩小 Sidebar 至 200px |
| Desktop | > 1200px | 默认布局 |

### 大响应体显示策略

| 响应大小 | 默认模式 | 说明 |
|---------|---------|------|
| < 10KB | Full | 完整语法高亮，全部显示 |
| 10KB - 50KB | Full | 完整语法高亮，全部显示 |
| > 50KB | Performance | 虚拟化列表，初始 500 行，轻量高亮 |

**Performance 模式 UI**:
- 顶部工具栏：Performance / Full / Raw 切换按钮（始终显示）
- 底部加载提示："Showing 500 of 5008 lines"
- 加载更多按钮："Load 4508 more" / "Load all"

---

## 交互规范

### 悬停效果

| 元素 | 悬停效果 |
|-----|---------|
| Button | 背景色加深 8% |
| List Item | 背景色变为 surfaceVariant |
| Tab | 背景色变为 surfaceVariant |
| Link | 颜色变为主色 |

### 点击效果

| 元素 | 点击效果 |
|-----|---------|
| Button | Scale 0.98 |
| List Item | 背景色加深 |
| Card | 轻微阴影变化 |

### 焦点样式

```dart
class FocusStyles {
  static final outline = BoxDecoration(
    border: Border.all(color: AppColors.primary, width: 2),
    borderRadius: BorderRadius.circular(6),
  );
}
```

### 过渡动画

```dart
class Transitions {
  static const fast = Duration(milliseconds: 100);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
  
  static const curve = Curves.easeInOut;
}
```

### 常用动画

```dart
// 淡入淡出
AnimatedOpacity(
  opacity: visible ? 1.0 : 0.0,
  duration: Transitions.normal,
  child: child,
)

// 滑入
AnimatedSlide(
  offset: visible ? Offset.zero : Offset(0, 0.1),
  duration: Transitions.normal,
  child: child,
)

// 缩放
AnimatedScale(
  scale: pressed ? 0.98 : 1.0,
  duration: Transitions.fast,
  child: child,
)
```

---

## Request Settings UI 规范

> **功能状态**: ⏳ 规划中 (参考 Postman 请求级别配置)

### 整体布局

```
┌─────────────────────────────────────────────────────────┐
│  Settings Tab                                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ HTTP Version                      [Dropdown ▼]  │   │
│  │ Select the HTTP version...                      │   │
│  │ Default: Settings                               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Enable SSL certificate verification    [○] OFF  │   │
│  │ Verify SSL certificates when...                 │   │
│  │ Default: Settings                               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Automatically follow redirects         [●] ON   │   │
│  │ Follow HTTP 3xx responses...                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ... more settings ...                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 功能清单

| 设置项 | 控件类型 | 默认值 | Dio 支持 |
|--------|----------|--------|----------|
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

### 设置项结构

每个设置项采用统一的卡片式布局：

```dart
class SettingItem extends StatelessWidget {
  final String title;           // 设置项标题
  final String description;     // 设置项描述
  final Widget control;         // 控件（Switch/Dropdown/Input）
  final String? defaultValue;   // 默认值提示
  final bool isModified;        // 是否已修改

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: CardStyles.standard,
      child: Row(
        children: [
          // 左侧：标题和描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.body),
                    if (isModified) ...[
                      SizedBox(width: 8),
                      DotIndicator(color: AppColors.primary),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(description, 
                  style: AppTextStyles.caption.copyWith(
                    color: NeutralColors.textSecondary,
                  ),
                ),
                if (defaultValue != null) ...[
                  SizedBox(height: 4),
                  Text('Default: $defaultValue',
                    style: AppTextStyles.tiny.copyWith(
                      color: NeutralColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 右侧：控件
          control,
        ],
      ),
    );
  }
}
```

### 间距规范

| 元素 | 间距 |
|-----|------|
| 设置项之间 | 12px |
| 设置项内边距 | 16px |
| 标题与描述之间 | 4px |
| 描述与默认值之间 | 4px |
| 控件与文字之间 | 16px |

### 实现规划

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

### 技术要点

1. 请求设置应与请求数据一起持久化到 Collection
2. Dio 支持通过 `Options` 配置大部分设置
3. SSL 验证通过 `DioHttpClientAdapter` 的 `onHttpClientCreate` 配置
4. TLS/SSL 协议禁用需要平台特定的实现
5. 设置项需要支持「继承全局默认值」和「请求级别覆盖」两种模式

### 控件类型

#### 1. Toggle Switch

用于布尔类型设置项（ON/OFF）

```dart
SettingItem(
  title: 'Enable SSL certificate verification',
  description: 'Verify SSL certificates when sending a request...',
  defaultValue: 'Settings',
  control: Row(
    children: [
      Switch(value: isOn, onChanged: onChanged),
      SizedBox(width: 8),
      Text(isOn ? 'ON' : 'OFF', style: AppTextStyles.caption),
    ],
  ),
)
```

#### 2. Dropdown

用于选择类型设置项

```dart
SettingItem(
  title: 'HTTP Version',
  description: 'Select the HTTP version to use for sending the request',
  defaultValue: 'Settings',
  control: SizedBox(
    width: 120,
    child: DropdownButtonFormField(
      value: selectedValue,
      items: ['Auto', 'HTTP/1.1', 'HTTP/2'],
      onChanged: onChanged,
      decoration: InputStyles.outline,
    ),
  ),
)
```

#### 3. Number Input

用于数值类型设置项

```dart
SettingItem(
  title: 'Maximum number of redirects',
  description: 'Set a cap on the maximum number of redirects to follow',
  control: SizedBox(
    width: 80,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputStyles.outline.copyWith(
        suffixText: 'times',
      ),
    ),
  ),
)
```

#### 4. Text Input

用于文本类型设置项（如加密套件列表）

```dart
SettingItem(
  title: 'Cipher suite selection',
  description: 'Order of cipher suites that the SSL server profile uses...',
  control: Expanded(
    child: TextField(
      controller: controller,
      decoration: InputStyles.outline.copyWith(
        hintText: 'Enter cipher suites',
      ),
    ),
  ),
)
```

#### 5. Multi-select Chips

用于多选类型设置项（如 TLS 协议禁用）

```dart
SettingItem(
  title: 'TLS/SSL protocols disabled during handshake',
  description: 'Specify the SSL and TLS protocol versions to be disabled',
  control: Wrap(
    spacing: 8,
    children: [
      FilterChip(label: Text('SSLv3'), onSelected: ...),
      FilterChip(label: Text('TLS 1.0'), onSelected: ...),
      FilterChip(label: Text('TLS 1.1'), onSelected: ...),
    ],
  ),
)
```

### 视觉状态

| 状态 | 视觉表现 |
|-----|---------|
| 默认值 | 无特殊标记 |
| 已修改 | 标题旁显示紫色圆点指示器 |
| 悬停 | 卡片背景色变为 surfaceVariant |
| 禁用 | 控件置灰，透明度 0.5 |

### 分组标题

相关设置项可使用分组标题进行组织：

```dart
class SettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: NeutralColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
```

---

## Key-Value 编辑器规范

### Headers/Params 列表

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ✓ │ Key                    │ ⓘ │ Value                 │ Description  │
├─────────────────────────────────────────────────────────────────────────┤
│ ✓ │ Content-Type           │ ⓘ │ application/json      │ The MIME...  │
│ ✓ │ Authorization          │   │ Bearer xxx            │              │
│ ☐ │ X-Custom-Header        │   │                       │              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 行规范

- 高度：36px
- 结构：Checkbox (24px) + Key Input + Info Icon (条件显示) + Value Input + Delete Button
- 对齐：所有元素垂直居中
- 间距：元素之间 8px

### Info Icon 规则

常见 Headers 显示 Info 图标，悬停显示说明：

| Header Key | 说明 |
|-----------|------|
| Accept | Media types that are acceptable for the response |
| Content-Type | The MIME type of the body of the request |
| Authorization | Credentials for authenticating the client |
| User-Agent | Information about the user agent |
| Cache-Control | Directives for caching mechanisms |
| ... | ... |

### 自动完成

Header Key 输入时显示下拉建议：

```dart
Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) return const [];
    return _commonHeaderKeys.where((key) => 
      key.toLowerCase().contains(textEditingValue.text.toLowerCase())
    );
  },
  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: 'Key',
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      ),
    );
  },
)
```

---

## Certificate Tab UI 规范

### 整体布局

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Certificate Tab                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ 🔒 Certificate is valid                                             │ │
│ │ Valid from: 2023-01-01 to 2024-01-01                                │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Subject:                                                                │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Common Name (CN)       example.com                                  │ │
│ │ Organization (O)       Example Inc.                                 │ │
│ │ Organizational Unit    IT Department                                │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Issuer:                                                                 │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Common Name (CN)       DigiCert TLS RSA SHA256 2020 CA1             │ │
│ │ Organization (O)       DigiCert Inc                                 │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Certificate Chain:                                                      │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ ⬇ example.com                                                       │ │
│ │ ⬇ DigiCert TLS RSA SHA256 2020 CA1                                  │ │
│ │ ⬇ DigiCert Global Root CA                                           │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### 字体规范

| 元素 | 字号 | 字重 | 颜色 |
|-----|------|------|------|
| 状态标题 | 13px | 600 | success/error |
| 分组标题 | 12px | 500 | textSecondary |
| 详情标签 | 10px | 400 | textSecondary |
| 详情值 | 11px | 400 | textPrimary |
| 有效期 | 11px | 400 | textSecondary |

### 状态卡片

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isValid 
      ? AppColors.success.withOpacity(0.1)
      : AppColors.error.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: isValid ? AppColors.success : AppColors.error,
    ),
  ),
  child: Row(
    children: [
      Icon(
        isValid ? Icons.lock : Icons.lock_open,
        color: isValid ? AppColors.success : AppColors.error,
      ),
      SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isValid ? 'Certificate is valid' : 'Certificate is invalid',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isValid ? AppColors.success : AppColors.error,
            ),
          ),
          Text(
            'Valid from: $validFrom to $validTo',
            style: TextStyle(fontSize: 11, color: NeutralColors.textSecondary),
          ),
        ],
      ),
    ],
  ),
)
```

---

## Timing Tab UI 规范

### 整体布局

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Timing Tab                                                               │
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │           ⏱ 156 ms                                                  │ │
│ │              Total Duration                                         │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Phase Details:                                                          │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ DNS Lookup     ████████ 25ms (16%)                                  │ │
│ │ TCP Handshake  ██████ 18ms (12%)                                    │ │
│ │ TLS Handshake  ████████████ 42ms (27%)                              │ │
│ │ TTFB           ████████████████ 58ms (37%)                          │ │
│ │ Download       ███ 13ms (8%)                                        │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Timeline:                                                               │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ DNS │ TCP │  TLS   │     TTFB      │ Down│                         │ │
│ │█████│█████│████████│████████████████│█████│                         │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### 总时间卡片

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Icon(Icons.timer, color: Colors.white, size: 32),
      SizedBox(height: 8),
      Text(
        '${timingInfo.totalMs} ms',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(
        'Total Duration',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    ],
  ),
)
```

### 阶段详情

| 阶段 | 颜色 | 说明 |
|-----|------|------|
| DNS Lookup | Blue 500 | 域名解析时间 |
| TCP Handshake | Green 500 | TCP 连接建立时间 |
| TLS Handshake | Purple 500 | SSL/TLS 握手时间 |
| TTFB | Amber 500 | 首字节时间 |
| Download | Gray 500 | 响应体下载时间 |

---

## Request Tab UI 规范

### 整体布局

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Request Tab                                                              │
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │  POST                                          https://api.ex.com   │ │
│ │  /v1/users?include=profile                                          │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Headers (2):                                                            │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Content-Type           application/json                             │ │
│ │ Authorization          Bearer xxx                                   │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│ Body (JSON):                                                            │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ {                                                                   │ │
│ │   "name": "John",                                                   │ │
│ │   "email": "john@example.com"                                       │ │
│ │ }                                                                   │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### 请求概览卡片

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        methodColor.withOpacity(0.1),
        methodColor.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: methodColor.withOpacity(0.3)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          HttpMethodTag(method: request.method),
          SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              request.url,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
      if (queryParams.isNotEmpty)
        SelectableText(
          '?${queryParams.entries.map((e) => "${e.key}=${e.value}").join("&")}',
          style: AppTextStyles.tiny.copyWith(
            color: NeutralColors.textSecondary,
          ),
        ),
    ],
  ),
)
```

### HTTP 方法颜色

```dart
Color _getMethodColor(HttpMethod method) {
  switch (method) {
    case HttpMethod.get: return Color(0xFF3B82F6);    // Blue 500
    case HttpMethod.post: return Color(0xFF10B981);   // Green 500
    case HttpMethod.put: return Color(0xFFF59E0B);    // Amber 500
    case HttpMethod.delete: return Color(0xFFEF4444); // Red 500
    case HttpMethod.patch: return Color(0xFF8B5CF6);  // Violet 500
    default: return Color(0xFF6B7280);                // Gray 500
  }
}
```

---

## 暗黑模式

### 切换逻辑

```dart
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setLight() => state = ThemeMode.light;
  void setDark() => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;
}
```

### 颜色映射

| 浅色模式 | 深色模式 |
|---------|---------|
| background | darkBackground |
| surface | darkSurface |
| surfaceVariant | darkSurfaceVariant |
| border | darkBorder |
| textPrimary | darkTextPrimary |
| textSecondary | darkTextSecondary |

### 特殊处理

- 阴影：降低不透明度或移除
- 边框：降低对比度
- 图片：添加亮度调整

---

## 图标规范

### 图标尺寸

| 用途 | 尺寸 |
|-----|------|
| Tab 内 | 14px |
| 按钮内 | 16px |
| 列表项 | 16px |
| 工具栏 | 20px |
| Sidebar Item | 16px |
| 空状态 | 48px |
| 特性展示 | 64px |

### Tab 图标映射

| Tab | 图标 |
|-----|------|
| Body | Icons.code |
| Headers | Icons.list_alt |
| Params | Icons.tune |
| Cookies | Icons.cookie |
| Certificate | Icons.verified |
| Timing | Icons.timer |
| Request | Icons.send |
| Settings | Icons.settings |

### 图标库

- 主要：Material Icons
- 备选：Phosphor Icons

---

## 快捷键

| 快捷键 | 功能 | 状态 |
|-------|------|------|
| Cmd + N | 新建请求 | ✅ 已实现 |
| Cmd + Enter | 发送请求 | ✅ 已实现 |
| Cmd + S | 保存请求 | ✅ 已实现 |
| Cmd + Shift + S | 另存为 | ✅ 已实现 |
| Cmd + W | 关闭标签 | ✅ 已实现 |
| Cmd + 1-9 | 切换标签 | ✅ 已实现 |
| Ctrl/Cmd + Shift + T | 重新打开关闭的标签 | ⏸️ Backlog |
| Ctrl/Cmd + / | 切换 Sidebar | ⏸️ Backlog |
| Ctrl/Cmd + , | 打开设置 | ⏸️ Backlog |
| Ctrl/Cmd + Shift + P | 命令面板 | ⏸️ Backlog |

### macOS 菜单集成

应用支持 macOS 系统菜单通过 MethodChannel 与 Flutter 通信：

```
File
  ├── New Request (Cmd+N)
  ├── Save (Cmd+S)
  └── Save As... (Cmd+Shift+S)

Edit
  └── (系统默认编辑菜单)

View
  └── (预留)

Window
  ├── Close (Cmd+W)
  └── (系统默认窗口菜单)
```

---

## 无障碍

### 色彩对比度

- 正文文字：对比度 >= 4.5:1
- 大号文字：对比度 >= 3:1
- 图标/UI 元素：对比度 >= 3:1

### 焦点管理

- 所有交互元素可见焦点
- 合理的 Tab 顺序
- 跳过链接支持

### 屏幕阅读器

- 所有图标添加语义标签
- 复杂组件提供完整描述
- 动态内容变化通知

---

## Code Editor UI 规范

> **改进目标**: 参考 Postman 提升 Response Body 和 Request Body 区域的视觉精致度

### 问题分析

对比 Postman 的 Response Body 区域，当前 Hopp 存在以下视觉差距：

| 对比项 | Postman | Hopp (当前) | 改进方向 |
|-------|---------|-------------|---------|
| 行号宽度 | 约 35px，紧凑 | 默认宽度，偏宽 | 缩小至 32-36px |
| 行号背景 | 灰色背景，与代码区明显分隔 | 无独立背景 | 添加灰色背景区分 |
| 编辑器边框 | 精致圆角边框 | 简单边框或无边框 | 添加 6px 圆角边框 |
| 语法高亮 | 清晰：Key 深蓝、String 绿、Number 蓝 | 基础高亮 | 优化配色方案 |
| 工具栏 | 格式选择下拉 + Beautify 按钮 | Performance/Full 切换 | 添加 Beautify 按钮 |
| 整体质感 | 现代、精致 | 略显原始 | 提升细节处理 |

### Response Body 规范

#### 整体布局

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Response Body Tab                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ [JSON ▼] [Preview] [Visualize ▼]                   [Beautify] [Copy]    │  ← 工具栏
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │  1 │ {                                                              │ │
│ │  2 │   "userId": 422661012,                                        │ │  ← 行号区
│ │  3 │   "token": "0e0b7ebd0ddc46fe832bddc45e3cfc59",                │ │    (灰色背景)
│ │  4 │   "username": "zhongmou",                                     │ │
│ │  5 │   "org": "北京中创视讯科技有限公司"                           │ │
│ │  6 │ }                                                              │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 行号区域规范

```dart
// 行号区域样式
class LineNumberStyle {
  // 宽度固定为内容自适应，最大 48px
  static const width = 40.0;
  
  // 背景色 - 浅灰色与代码区区分
  static Color backgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
  }
  
  // 文字样式
  static const textStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    color: Colors.grey, // 灰色，不喧宾夺主
    height: 1.4,
  );
  
  // 内边距
  static const padding = EdgeInsets.only(right: 8);
}
```

**关键要求**:
1. **宽度**: 行号区域宽度固定 40px，右对齐显示
2. **背景**: 使用 `surfaceContainerHighest.withOpacity(0.5)` 作为背景色
3. **分隔**: 行号区与代码区之间添加 1px 分割线
4. **对齐**: 行号与代码行严格对齐

#### 编辑器边框规范

```dart
// 代码编辑器容器样式
Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(
      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
      width: 1,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Row(
      children: [
        // 行号区域
        _buildLineNumberArea(),
        // 分割线
        VerticalDivider(width: 1, thickness: 1),
        // 代码区域
        Expanded(child: _buildCodeArea()),
      ],
    ),
  ),
)
```

#### 工具栏改进

```dart
// Response Body 工具栏
Container(
  height: 36,
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: Row(
    children: [
      // 格式选择下拉 (JSON/XML/Text/HTML)
      _buildFormatDropdown(),
      SizedBox(width: 12),
      // Preview 按钮 (HTML 响应时启用)
      _buildPreviewButton(),
      Spacer(),
      // Beautify 按钮
      _buildBeautifyButton(),
      SizedBox(width: 8),
      // Copy 按钮
      _buildCopyButton(),
    ],
  ),
)
```

**工具栏按钮样式**:

```dart
// Beautify 按钮
TextButton.icon(
  onPressed: _beautifyCode,
  icon: Icon(Icons.format_align_left, size: 14),
  label: Text('Beautify'),
  style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.primary,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
)
```

#### JSON 语法高亮配色

```dart
// 优化后的语法高亮配色
class JsonSyntaxColors {
  // Key - 深蓝色
  static const key = Color(0xFF1E40AF);  // Blue 800
  
  // String - 深绿色
  static const string = Color(0xFF15803D);  // Green 700
  
  // Number - 蓝色
  static const number = Color(0xFF2563EB);  // Blue 600
  
  // Boolean/Null - 紫色
  static const keyword = Color(0xFF7C3AED);  // Violet 600
  
  // Punctuation - 灰色
  static const punctuation = Color(0xFF6B7280);  // Gray 500
  
  // 深色模式适配
  static Color getKey(bool isDark) => isDark ? Color(0xFF93C5FD) : key;
  static Color getString(bool isDark) => isDark ? Color(0xFF86EFAC) : string;
  static Color getNumber(bool isDark) => isDark ? Color(0xFF60A5FA) : number;
}
```

### Request Body 规范

Request Body 区域应与 Response Body 保持一致的编辑器样式。

#### 整体布局

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Request Body Tab                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ ○ none  ○ form-data  ○ x-www-form-urlencoded  ● raw  [JSON ▼]           │  ← Radio 组
├─────────────────────────────────────────────────────────────────────────┤
│ [JSON ▼]                                            [Beautify] [Clear]  │  ← 工具栏
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │  1 │ {                                                              │ │
│ │  2 │   "username": "zhongmou",                                     │ │
│ │  3 │   "password": "7110eda4d09e062aa5e4a390b0a572ac0d2c0220"       │ │
│ │  4 │ }                                                              │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 类型选择器样式 (Radio 组)

```dart
// Radio 组样式
Row(
  children: [
    _buildRadioOption('none', BodyType.none),
    _buildRadioOption('form-data', BodyType.formData),
    _buildRadioOption('x-www-form-urlencoded', BodyType.formUrlEncoded),
    _buildRadioOption('raw', BodyType.raw),
    if (selectedType == BodyType.raw) _buildRawSubtypeDropdown(),
  ],
)

// Radio 选项样式
Widget _buildRadioOption(String label, BodyType value) {
  final isSelected = selectedType == value;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<BodyType>(
        value: value,
        groupValue: selectedType,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      SizedBox(width: 16),
    ],
  );
}
```

#### Raw 子类型下拉

```dart
// Raw 子类型选择器
DropdownButtonFormField<String>(
  value: rawContentType,
  items: [
    DropdownMenuItem(value: 'text', child: Text('Text')),
    DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
    DropdownMenuItem(value: 'json', child: Text('JSON')),
    DropdownMenuItem(value: 'html', child: Text('HTML')),
    DropdownMenuItem(value: 'xml', child: Text('XML')),
  ],
  onChanged: onChanged,
  decoration: InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),
  style: TextStyle(fontSize: 12),
)
```

### 实现优先级

| 改进项 | 优先级 | 工时 | 说明 |
|-------|--------|------|------|
| 行号区域样式优化 | P1 | 3h | 缩小宽度、添加背景色 |
| 编辑器边框样式 | P1 | 2h | 添加圆角边框 |
| JSON 语法高亮优化 | P1 | 3h | 优化配色方案 |
| Beautify 按钮 | P1 | 2h | JSON/XML 格式化功能 |
| 工具栏布局调整 | P2 | 2h | 格式选择下拉 |
| 深色模式适配 | P2 | 2h | 语法高亮深色配色 |

### 参考实现

```dart
// 完整的 Code Editor 组件示例
class ImprovedCodeEditor extends StatelessWidget {
  final String code;
  final String? language;
  final bool showLineNumbers;
  final VoidCallback? onBeautify;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            // 工具栏
            _buildToolbar(),
            // 编辑器区域
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 行号
                  if (showLineNumbers) _buildLineNumbers(),
                  // 代码
                  Expanded(child: _buildCodeField()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineNumbers() {
    final lines = code.split('\n');
    return Container(
      width: 40,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      padding: EdgeInsets.only(right: 8, top: 12, bottom: 12),
      child: Column(
        children: lines.asMap().entries.map((entry) {
          return Text(
            '${entry.key + 1}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              height: 1.4,
              color: Colors.grey,
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

---

<p align="center">Designed with ❤️ by AI · Powered by Kimi</p>
