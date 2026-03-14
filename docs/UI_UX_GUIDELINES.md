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
| Body | 14px | 400 | 20px | 正文内容 |
| Body Small | 13px | 400 | 18px | 次要文字 |
| Caption | 12px | 500 | 16px | 标签、提示 |
| Tiny | 11px | 500 | 14px | 辅助信息 |
| Code | 13px | 400 | 18px | 代码显示 |

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
| Tab | 8px 16px | 0 |
| Card | 16px | - |
| Input | 10px 12px | - |
| Button (S) | 6px 12px | - |
| Button (M) | 8px 16px | - |
| Button (L) | 12px 24px | - |
| Section | - | 16px |

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
| Medium | 36px | 12px | 13px |
| Large | 44px | 16px | 14px |

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
  - Body Tab：有内容时显示绿色圆点
  - Headers/Params Tab：显示数量标记（如 "Headers 11"）
- 选中状态：底部 2px 主色指示线
- 字体：11px Medium

### 响应式断点

| 断点 | 宽度 | 行为 |
|-----|------|------|
| Mobile | < 768px | 隐藏 Sidebar，使用抽屉 |
| Tablet | 768px - 1200px | 缩小 Sidebar 至 200px |
| Desktop | > 1200px | 默认布局 |

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
| 按钮内 | 16px |
| 列表项 | 16px |
| 工具栏 | 20px |
| 空状态 | 48px |
| 特性展示 | 64px |

### 图标库

- 主要：Material Icons
- 备选：Phosphor Icons

---

## 快捷键

| 快捷键 | 功能 |
|-------|------|
| Ctrl/Cmd + N | 新建请求 |
| Ctrl/Cmd + S | 保存请求 |
| Ctrl/Cmd + Enter | 发送请求 |
| Ctrl/Cmd + W | 关闭标签 |
| Ctrl/Cmd + Shift + T | 重新打开关闭的标签 |
| Ctrl/Cmd + / | 切换 Sidebar |
| Ctrl/Cmd + , | 打开设置 |
| Ctrl/Cmd + Shift + P | 命令面板 |

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

<p align="center">Designed with ❤️ by AI · Powered by Kimi</p>
