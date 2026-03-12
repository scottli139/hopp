# Hopp 开发计划与里程碑

> 本文档记录 Hopp 项目的开发计划、里程碑和任务进度。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | UI 优化完成，准备主题切换和响应优化 |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | **405 个测试全部通过** ✅ |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | 73 | ✅ 通过 |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | 88 | ✅ 通过 |
| **总计** | **405** | **全部通过** |

---

## 📅 里程碑规划

### M1: 基础架构 ✅ COMPLETED (2026-03-10)

| 任务 | 状态 | 说明 |
|-----|------|------|
| FVM 环境配置 | ✅ | Flutter 3.27.4 + 国内镜像 |
| 项目结构搭建 | ✅ | 目录结构、依赖配置 |
| 代码规范配置 | ✅ | analysis_options.yaml |
| 核心模型定义 | ✅ | Freezed + Hive 模型 (7个) |
| 基础服务实现 | ✅ | HTTP、存储服务 |

**技术决策**:
- FVM 管理 Flutter 版本
- Riverpod 状态管理
- Dio HTTP 客户端
- Hive + SharedPreferences 存储

---

### M2: 核心功能 ✅ COMPLETED (2026-03-10)

| 任务 | 状态 | 说明 |
|-----|------|------|
| 侧边栏组件 | ✅ | Collection 树形结构 |
| 标签页管理 | ✅ | 多标签页支持 |
| 请求编辑器 | ✅ | Method/URL/Params/Headers/Body |
| 响应展示 | ✅ | Body/Headers/Status/Time/Size |
| HTTP 请求发送 | ✅ | Dio 封装，错误处理 |

**设计规范**:
- Material Design 3
- 可拖拽调整面板宽度
- 响应式布局

---

### M3: 用户体验 ✅ COMPLETED (2026-03-12)

#### M3.1 UI/UX 优化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| 数据一致性修复 | ✅ | P0 | dirtyRequestsProvider + 保存功能 |
| JSON 语法高亮 | ✅ | P1 | flutter_code_editor 集成 |
| 错误信息展示优化 | ✅ | P1 | 可展开错误条 |
| UI 字体优化 | ✅ | P1 | 统一 11-12px 字体系统 |
| 布局溢出修复 | ✅ | P0 | Sidebar/Response 区域 |

#### M3.2 品牌化

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| macOS Dock 图标 | ✅ | P0 | AppIcon.icns (16-1024px) |
| About 对话框 Logo | ✅ | P0 | 兔子 logo |
| Sidebar Header Logo | ✅ | P0 | SVG logo |
| StatusBar Logo | ✅ | P0 | 兔子图标 |

#### M3.3 快捷键与 E2E 测试

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| Flutter Shortcuts | ✅ | P0 | Shortcuts + Actions |
| macOS 系统菜单 | ✅ | P0 | File/Edit 菜单 |
| MethodChannel 通信 | ✅ | P0 | Swift ↔ Dart |
| Peekaboo E2E 测试 | ✅ | P1 | 完整自动化测试套件 |

**快捷键**:
- `Cmd+N` - 新建请求
- `Cmd+Enter` - 发送请求
- `Cmd+S` - 保存请求
- `Cmd+W` - 关闭标签
- `Cmd+1-9` - 切换标签

#### M3.4 HTTPS 证书查看 (F1.11)

| 任务 | 状态 | 优先级 | 说明 |
|-----|------|--------|------|
| CertificateInfo 模型 | ✅ | P1 | 证书信息存储 |
| Certificate Tab UI | ✅ | P1 | Response 区域动态 Tab |
| 证书详情展示 | ✅ | P1 | Subject/Issuer/有效期/指纹 |
| 单元测试 | ✅ | P1 | 15个测试 |

---

### M4: 高级功能 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 | 说明 |
|-----|------|--------|---------|------|
| 请求名称编辑 | ✅ | **P0** | 4h | 右键菜单重命名 + UI 测试模式支持 |
| 主题切换 | 🔄 | P1 | 4h | Light/Dark 模式 |
| 国际化完善 | 🔄 | P1 | 6h | 多语言支持 |
| 请求时间分析 | ⏳ | P1 | 10h | Timing Tab (DNS/TCP/TTFB) |
| 请求详情展示 | ⏳ | P1 | 6h | Request Tab |
| 环境变量 | ⏳ | P1 | 12h | 变量替换和多环境 |
| 请求历史 | ⏳ | P2 | 8h | 请求历史记录 |
| 拖拽排序 | ⏳ | P2 | 6h | Collection 拖拽排序 |

---

### M5: 数据管理 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| Postman 导入/导出 | ⏳ | P1 | 12h |
| Insomnia 导入 | ⏳ | P2 | 8h |
| curl 导出 | ⏳ | P2 | 4h |
| 云端同步 | ⏳ | P3 | 20h |
| 团队协作 | ⏳ | P3 | 40h |

---

### M6: 测试与质量保障 ✅ COMPLETED

| 任务 | 状态 | 优先级 | 数量 |
|-----|------|--------|------|
| 单元测试 (Models) | ✅ | P0 | 152 个 |
| 单元测试 (Services) | ✅ | P0 | 73 个 |
| 单元测试 (Providers) | ✅ | P0 | 92 个 |
| Widget 测试 | ✅ | P1 | 88 个 |
| Peekaboo E2E 测试 | ✅ | P2 | 完整套件 |
| CI/CD 配置 | ✅ | P0 | GitHub Actions |

**E2E 测试套件** (`integration_test/peekaboo/`):
```bash
cd integration_test/peekaboo
make test   # 完整测试
make quick  # 快速测试
make logs   # 查看日志
```

---

## 🚀 发布计划

### v0.1.0 - Alpha ✅ CURRENT

- ✅ 基础 HTTP 请求
- ✅ Collection 管理
- ✅ 多标签页
- ✅ 基础 UI

### v0.2.0 - Beta 🔄 IN PROGRESS

- 🔄 主题切换
- 🔄 国际化
- ⏳ 请求历史
- ⏳ 请求名称编辑

### v0.3.0 - RC ⏳ PLANNED

- ⏳ 环境变量
- ⏳ 导入/导出
- ⏳ Timing 分析
- ⏳ 性能优化

### v1.0.0 - GA ⏳ PLANNED

- ⏳ 完整功能集
- ⏳ 完善文档
- ⏳ 全平台稳定
- ⏳ 应用商店发布

---

## 🛠️ 技术栈

### 核心依赖

| 包名 | 版本 | 用途 |
|-----|------|------|
| flutter_riverpod | ^2.6.1 | 状态管理 |
| dio | ^5.8.0+1 | HTTP 客户端 |
| hive | ^2.2.3 | NoSQL 存储 |
| shared_preferences | ^2.5.2 | 配置存储 |
| freezed_annotation | ^2.4.4 | 不可变类生成 |
| multi_split_view | ^3.6.0 | 可拖拽分割面板 |
| flutter_code_editor | ^0.5.0 | 代码高亮 |

### 开发依赖

| 包名 | 版本 | 用途 |
|-----|------|------|
| build_runner | ^2.4.15 | 代码生成 |
| freezed | ^2.5.7 | 不可变类生成 |
| riverpod_generator | ^2.6.3 | Provider 生成 |
| mockito | ^5.4.5 | 测试 Mock |

---

## 🎨 设计规范

### 颜色系统

```dart
const primaryColor = Color(0xFF6366F1);
const successColor = Color(0xFF10B981);
const warningColor = Color(0xFFF59E0B);
const errorColor = Color(0xFFEF4444);
```

### 间距系统

```dart
const kSpaceXS = 4.0;
const kSpaceS = 8.0;
const kSpaceM = 12.0;
const kSpaceL = 16.0;
const kSpaceXL = 24.0;
```

### 字体规范

| 样式 | 字号 | 用途 |
|------|------|------|
| Display | 24px | 页面标题 |
| Title | 16px | 区块标题 |
| Body | 14px | 正文 |
| Caption | 12px | 按钮文字 |
| Tiny | 11px | 标签、徽章 |

---

## 🔗 参考链接

- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
