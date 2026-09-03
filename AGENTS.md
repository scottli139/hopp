# Hopp - AI Agent 项目指南

> 本文件是 Agent 的快速入口：项目定位、常用命令、文档索引和当前状态。详细设计、规范与实现说明见 `/docs`。

---

## 文档维护原则

- **精简**：本文件只放定位、命令、索引和状态，不铺陈细节
- **沉淀**：技术决策、问题解决、规范细节都写到 `/docs` 对应文档
- **不记录**：每日会话过程、具体操作步骤、临时调试信息
- **更新时机**：完成功能 / 修 bug / 做决策后，同步更新对应 docs 文档与下方「当前状态」
- **边界**：内容只写一份，跨文档用链接引用，改一处时同步核对关联文档
  - `PRD.md` = 需求与验收标准（F-ID 的唯一权威来源）
  - `DEVELOPMENT_PLAN.md` = 已排期的里程碑 / 进度 / 发布计划
  - `BACKLOG.md` = 当前计划以外的候选功能 + 已知问题 + 技术债
  - `IMPLEMENTATION_NOTES.md` = 复杂实现的详细设计
  - `ARCHITECTURE.md` = 架构、技术栈与依赖版本
  - `UI_UX_GUIDELINES.md` = 设计规范（颜色/字体/间距/组件）
  - `TESTING.md` = 测试方案与指令清单

---

## 项目概述

**Hopp** 是一款**本地优先、数据不出机器的 API 工作台**：把 AI 的便利嫁接在本地工具的隐私上，轻量、跨平台，基于 Flutter 构建。

> 定位一句话：跟 Postman 比隐私和轻量；跟纯 AI 聊天比确定性（collection/环境/断言可保存、可复跑）和零数据外泄。

| 项目信息 | 详情 |
|----------|------|
| **技术栈** | Flutter 3.35.x + Dart + Riverpod + Dio + Hive |
| **目标平台** | macOS 10.15+ / Windows 10+ / Linux |
| **当前版本** | `0.15.0` |

> 历史参考：项目曾使用 Tauri (React + Rust)，详见 [ARCHIVED_TAURI.md](./docs/ARCHIVED_TAURI.md)。

---

## 常用命令

### 环境准备

```bash
# 安装 FVM（如未安装）
dart pub global activate fvm

# 使用项目指定的 Flutter 版本并安装依赖
fvm use
fvm flutter pub get
```

### 代码生成

```bash
# Freezed / Riverpod / Hive / JSON 生成
fvm dart run build_runner build --delete-conflicting-outputs
```

### 测试

```bash
fvm flutter test                      # 全部单元 / Widget 测试
fvm flutter test test/models/          # 按目录运行
fvm flutter test --coverage            # 生成覆盖率报告
```

### 构建与运行

```bash
fvm flutter run
fvm flutter build macos
```

### 国内镜像

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

---

## 设计系统守门（UI 改动必读）

视觉规范的唯一事实来源是代码，不是文档：

- **Token**：颜色 / 字号 / 间距 / 圆角 / 高度 / 阴影只能用 `lib/theme/`（`context.appTheme.*`、`AppColors`、`AppTextStyles`、`AppMetrics`、`AppShadows`、`AppSyntaxColors`）；组件只能用 `lib/widgets/common/`（AppButton/AppTextField/AppTabs/AppPopupSelect 等）。规范细节见 [UI_UX_GUIDELINES](./docs/UI_UX_GUIDELINES.md)。
- **守卫测试**：`test/design_guard_test.dart` 静态拦截 `Colors.` / `Color(0x…)` / 内联 `fontSize:` / `fontFamily:` / `BorderRadius.circular(数字)` / `withOpacity(` / `FontWeight.bold`。基线已清零，**任何新增违规都会直接挂掉测试**——不要绕过守卫，该加 token 就加在 `lib/theme/`。
- **组件 visual 变更**：更新 golden（`fvm flutter test test/widgets/common/ --update-goldens`）并人工目检 PNG；页面级变更用 test-mode 截图做亮/暗双主题审计（Gallery 页：`open_design_gallery` 指令）。
- **收尾同步**：视觉相关改动提交前更新 `docs/DESIGN_SYSTEM.md` 状态行与 `docs/CHANGELOG.md`。

---

## 文档索引

`/docs` 按功能分类存放详细文档：

| 分类 | 文档 |
|------|------|
| 产品 | [PRD](./docs/PRD.md) · [BACKLOG](./docs/BACKLOG.md) |
| 技术 | [ARCHITECTURE](./docs/ARCHITECTURE.md) · [DEVELOPMENT_PLAN](./docs/DEVELOPMENT_PLAN.md) · [IMPLEMENTATION_NOTES](./docs/IMPLEMENTATION_NOTES.md) · [SHORTCUTS](./docs/SHORTCUTS_IMPLEMENTATION_PLAN.md) · [ARCHIVED_TAURI](./docs/ARCHIVED_TAURI.md) |
| 设计 | [UI_UX_GUIDELINES](./docs/UI_UX_GUIDELINES.md) · [DESIGN_SYSTEM](./docs/DESIGN_SYSTEM.md)（重构方案 + [原型](./docs/design/design_system_preview.html)） · [CODING_STANDARDS](./docs/CODING_STANDARDS.md) · [FEATURE_UI_DESIGN](./docs/FEATURE_UI_DESIGN.md) |
| 测试 | [TESTING](./docs/TESTING.md) · [PEEKABOO_CLI_LEARNING](./docs/PEEKABOO_CLI_LEARNING.md) |
| 工程 | [DEVELOPMENT_ENVIRONMENT](./docs/DEVELOPMENT_ENVIRONMENT.md) · [GITHUB_SETTINGS](./docs/GITHUB_SETTINGS.md) · [CHANGELOG](./docs/CHANGELOG.md) |

**维护规则**：

- 新增文档时，选择合适分类并加入上表
- 架构 / 技术决策 → `ARCHITECTURE.md`；功能进度 → `DEVELOPMENT_PLAN.md`；复杂实现 → `IMPLEMENTATION_NOTES.md`
- 版本变更 → 更新 `CHANGELOG.md` 和本文件「当前状态」

---

## 当前状态

### 战略方向 🎯

本地 + 私有 AI，三层能力详见 [PRD](./docs/PRD.md)：

- **Tier 0（无模型）**：OpenAPI/Swagger 导入 → 一键生成请求/collection
- **Tier 1（本地模型）**：Ollama/LM Studio 走 localhost，解释响应 / 生成断言 / 自然语言建请求
- **Tier 2（BYOK 云端）**：默认关闭，用户自填 key

### 下次重点 🎯

1. ~~状态纠偏 + UX 审计~~（已完成，2026-08-21）
2. ~~环境变量系统~~（已完成，2026-08-21，M8.1：多环境 + 全局变量 + `{{var}}` 替换 + 动态变量）
3. ~~预请求链 + 变量转换~~（已完成，2026-08-25，M8.2 / v0.10.0：Auth 配置与继承 + `{{var | fn}}` 管道全量算法 + 预请求链/401 重跑/试运行 + Hive 落盘加密，见 [PRD](./docs/PRD.md) F8）
4. ~~Tier 0：OpenAPI/Swagger 导入~~（已完成，2026-08-28，M8.3 / v0.11.0：3.0/3.1+2.0、JSON+YAML、文件/URL 双源、防脑补映射、勾选预览 + 结果报告，见 [PRD](./docs/PRD.md) F9.4）
5. ~~**轻量断言 + CLI/CI 导出**~~（已完成，2026-08-28 发布 v0.12.0，M8.4：声明式规则 + Tests 页签 + `.hopp.json` 全保真导出 + `hopp run` 运行器；F4.2 AI 生成挪 M8.5，见 [PRD](./docs/PRD.md) F4 详案）
6. ~~**Tier 1 本地模型**~~（已完成，2026-08-31，M8.5：Ollama/LM Studio 解释响应 / AI 生成断言 / 自然语言建请求 + OpenAI 兼容客户端，见 [PRD](./docs/PRD.md) F9.5 与 [NOTES](./docs/IMPLEMENTATION_NOTES.md)；真模型冒烟已补：Ollama + qwen2.5:3b）
7. ~~**时间戳工效增强**~~（已完成，2026-09-01，M8.6 / v0.14.0：fx 动态变量直达 + 管道时间函数 date_add/date_floor + 响应 epoch 人性化注解，见 [PRD](./docs/PRD.md) F8.5 与 [NOTES](./docs/IMPLEMENTATION_NOTES.md)）
8. ~~**界面缩放（F5.7 / M8.7）**~~（已完成，2026-09-02，v0.15.0：侧栏底栏 100%/125%/150% 全局文字缩放，MediaQuery textScaler 注入；同日 P0 修复 test-mode Linux 数据隔离失效——`Platform.executableArguments` 拿不到 argv 改由 main() 显式传参，见 [CHANGELOG](./docs/CHANGELOG.md)）
9. ~~**Linux 标题栏主题跟随（F5.8）**~~（已完成，2026-09-02，v0.15.0：GtkBox 自定义标题栏绕开 Deepin GTK3 补丁对 GtkHeaderBar 的锁定，updateTitleBar 通道随主题下发 token 色，底栏高度跟随界面缩放，见 [PRD](./docs/PRD.md) F5.8 与 [NOTES](./docs/IMPLEMENTATION_NOTES.md)）
10. ~~**Flutter SDK 3.35.4 对齐**~~（已完成，2026-09-03：CI / `.fvmrc` / 本机 ARM64 社区构建统一锁定 3.35.4（Dart 3.9.2），`intl` 升 `^0.20.2`，本机/CI 版本错位消除，见 [DEVELOPMENT_ENVIRONMENT](./docs/DEVELOPMENT_ENVIRONMENT.md) ARM64 一节）
11. **多语言完善（i18n）**（已立项，2026-09-03，M8.8 / 预计 v0.16.0：i18n 接线 + 全量字符串抽取 + 语言切换，消除中英文混杂，见 [PRD](./docs/PRD.md) F5.9）

### 已知问题 🐛

| 问题 | 优先级 | 状态 |
|------|--------|------|
| 行号与内容滚动不同步 | P2 | 需优化 CodeEditor 组件（Issue #4；test-mode `scroll_response target=body` 可自动化验证） |

---

## 参考资源

- [Flutter](https://docs.flutter.dev/) · [Riverpod](https://riverpod.dev/) · [Material Design 3](https://m3.material.io/)
- [Dio](https://github.com/cfug/dio) · [Hive](https://docs.hivedb.dev/) · [Freezed](https://pub.dev/packages/freezed)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
