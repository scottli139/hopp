# Hopp 开发计划与里程碑

> 本文档只记录开发计划、里程碑和任务进度。设计规范见 [UI_UX_GUIDELINES.md](./UI_UX_GUIDELINES.md)，技术栈与依赖见 [ARCHITECTURE.md](./ARCHITECTURE.md)，详细实现说明见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md)，测试方案见 [TESTING.md](./TESTING.md)。
>
> **结构约定**：「里程碑」按 M# 组织工作——进行中的里程碑保留明细，已完成的折叠为摘要（实现细节见 IMPLEMENTATION_NOTES）；「发布计划」只做版本 → 里程碑映射，逐版本变更记录见 [CHANGELOG.md](./CHANGELOG.md)。里程碑编号与发布版本号脱钩。

---

## 📊 项目概况

| 项目信息 | 详情 |
|----------|------|
| **当前阶段** | 战略转向：本地 + 私有 AI（M8 系列进行中：M8.0–M8.4 已完成）；当前版本 v0.11.0（v0.12.0 待发布） |
| **目标版本** | v1.0.0 |
| **技术栈** | Flutter 3.27.x + Dart 3.6.x + Riverpod |
| **测试状态** | ✅ **727 通过 / 2 跳过**（2026-08-25 实测） |

### 测试统计

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 185 | ✅ 通过 |
| Services 测试 | 250 | ✅ 通过 |
| Providers 测试 | 114 | ✅ 通过 |
| Widgets 测试 | 135 (+2 跳过) | ✅ 通过 |
| Utils 测试 | 41 | ✅ 通过 |
| 根目录（design_guard / app_version） | 2 | ✅ 通过 |
| **总计** | **729（727 通过 + 2 跳过）** | ✅ **全部通过** |

---

## 📅 里程碑

### M8 系列：本地 + 私有 AI 转型 🔄 IN PROGRESS

> **方向（2026-08-20 决策）**：不再追平 Postman 功能集，转向「本地优先 + 私有 AI」的差异化定位（Tier 0/1/2 三层能力定义见 [PRD](./PRD.md)）。

| 阶段 | 内容 | 优先级 | 预估 | 状态 |
|------|------|--------|------|------|
| M8.0 | 状态纠偏 + UX 审计 | P0 | — | ✅ (2026-08-21)，审计清单见 [UX_AUDIT_M8.md](./UX_AUDIT_M8.md) |
| M8.1 | 环境变量系统（即原 M6）：多环境 + 全局变量 + `{{var}}` 替换 + 动态变量 | P0 | — | ✅ (2026-08-21)，实现说明见 [IMPLEMENTATION_NOTES](./IMPLEMENTATION_NOTES.md#环境变量系统-m81) |
| M8.2 | 预请求链 + 变量转换（F8.1-F8.4）：登录→token、密码 sha1/aes 加密 | P0 | ≈5 周 | ✅ (2026-08-25，v0.10.0：含集合级继承、401 重跑、试运行、Hive 落盘加密)，实现说明见 [IMPLEMENTATION_NOTES](./IMPLEMENTATION_NOTES.md)「预请求链与变量转换」一节 |
| M8.3 | Tier 0（F9.4）：OpenAPI/Swagger 导入 → 一键生成请求/collection | P0 | ≈2 周 | ✅ (2026-08-28：3.0/3.1+2.0 转换、JSON+YAML、文件/URL 双源、防脑补映射、勾选预览、结果报告)，实现说明见 [IMPLEMENTATION_NOTES](./IMPLEMENTATION_NOTES.md)「OpenAPI/Swagger 导入」一节 |
| M8.4 | 轻量断言 + CLI/CI（F4.1/F4.4）：状态/Header/Body/JSONPath/响应时间断言 + `cli/` 运行器与导出 | P1 | ≈4 周 | ✅ (2026-08-28：声明式规则 + Tests 页签 + `.hopp.json` 全保真导出 + `hopp run` exit 0/1/2，F4.2 挪 M8.5)，实现说明见 [IMPLEMENTATION_NOTES](./IMPLEMENTATION_NOTES.md)「轻量断言 + CLI/CI」一节 |
| M8.5 | Tier 1（F9）：本地模型（Ollama/LM Studio）解释响应 / 生成断言（F4.2）/ 自然语言建请求 | P1 | ≈2 周 | ⏳ |
| M8.6 | Tier 2（F9）：BYOK 云端，默认关闭 | P2 | ≈1 周 | ⏳ |

**已搁置**：原 v0.8/v0.9 规划中的非差异化功能（Mock 服务器、代理、WebSocket、代码片段生成、Cookie 管理、文件上传下载等）统一由 [BACKLOG.md](./BACKLOG.md) 维护。

> 历史注记：v0.7.0 曾规划「环境变量 + JS 测试脚本」并一度标记完成，2026-08-20 纠偏确认实际未实现——环境变量由 M8.1 承接落地，JS 沙箱决策降级为 M8.4 轻量断言（见 [PRD](./PRD.md) F4）。

### 已完成里程碑摘要

| 里程碑 | 完成时间 | 内容 |
|--------|----------|------|
| M1 基础架构 | 2026-03-10 | FVM 环境（Flutter 3.27.4）、项目结构、Freezed + Hive 核心模型、HTTP/存储基础服务 |
| M2 核心功能 | 2026-03-10 | Collection 树形侧边栏、多标签页、请求编辑器、响应展示、Dio HTTP 发送 |
| M3 用户体验 | 2026-03-13 | UI/UX 优化、品牌化、快捷键 + macOS 菜单、HTTPS 证书查看（F1.11）、大响应虚拟化、Timing 分析、编辑器细节（M3.1–M3.11） |
| M4 高级功能 | 2026-03-17 | 请求设置（SSL/重定向，F1.14 部分）、主题切换、请求详情、4XX/5XX 响应修复、真实证书获取、数据库迁移框架 |
| M5 数据管理 | 2026-03-16 | Postman Collection/Environment v2.0/v2.1 导入导出、冲突处理 |
| M7 测试与质量 | 2026-03 | 单元/Widget 测试体系、Peekaboo E2E、GitHub Actions CI |
| 设计系统重构（插入工作） | 2026-08-22 ~ 08-24 | `lib/theme/` token 体系 + 设计守卫基线清零、8 个统一组件全量迁移、组件 golden 双主题、侧栏主题切换、环境管理对话框重设计（对应 v0.8.5–v0.9.5，详见 [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)） |

> 各里程碑的实现细节按「内容只写一份」原则沉淀：实现设计见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md)，逐项变更见 [CHANGELOG.md](./CHANGELOG.md)，测试方案见 [TESTING.md](./TESTING.md)。

---

## 🚀 发布计划（版本 → 里程碑映射）

> 逐版本变更明细见 [CHANGELOG.md](./CHANGELOG.md)。

| 版本 | 发布日期 | 包含内容 | 状态 |
|------|----------|----------|------|
| v0.1.0 Alpha | 2026-03-10 | M1 基础架构、M2 核心功能 | ✅ |
| v0.2.0 Beta | 2026-03-11 | M3 早期：P0 修复、品牌化、快捷键、单元/Widget 测试起步 | ✅ |
| v0.3.0 Feature Complete | 2026-03-13 | M3：UI 测试模式、大响应虚拟化、Timing 分析、编辑器优化 | ✅ |
| v0.4.0 RC | 2026-03-16 | M4 部分：主题切换、i18n 框架、请求设置 UI、请求详情、保存修复 | ✅ |
| v0.5.0 Data Exchange | 2026-03-16 | M5 Postman 导入导出、Issue #1/#2 修复、SSL 验证开关 | ✅ |
| v0.6.0 Code Gen & Utils | 2026-03-18 ~ 03-19 | cURL 导入（F2.6）、URL↔Params 双向联动、Collection 扁平化、空状态入口、CI 修复 | ✅ |
| v0.7.0 | 2026-04-01 | 版本号提升；站点与 Windows CI 修复（2026-08-20）。原规划的环境变量/JS 测试脚本经 2026-08-20 纠偏后分别由 M8.1 / M8.4 承接 | ✅ |
| v0.8.x | 2026-08-21 ~ 08-22 | M8.0 UX 审计修复、**M8.1 环境变量系统**（v0.8.0）、设计系统 P1–P5（v0.8.5–v0.8.9） | ✅ |
| v0.9.x | 2026-08-22 ~ 08-24 | 设计系统收尾：输入框渲染修复（v0.9.0）、侧栏主题切换（v0.9.1）、环境管理对话框重设计（v0.9.2）及三处配套修复（v0.9.3–v0.9.5） | ✅ |
| v0.10.0 | 2026-08-25 | **M8.2 预请求链与变量转换**（F8.1–F8.4：Auth 配置与继承、`{{var \| fn}}` 管道、预请求链/401 重跑/试运行、Hive 落盘加密） | ✅ |
| v0.11.0 | 2026-08-28 | **M8.3 OpenAPI/Swagger 导入**（F9.4：3.0/3.1+2.0、JSON+YAML、文件/URL 双源、勾选预览、结果报告）、导入入口合并（cURL 页签）、test-mode 数据隔离 | ✅ |
| v0.12.0 | 2026-08-29 | **M8.4 轻量断言 + CLI/CI**（F4.1/F4.4：声明式断言 + Tests 页签、`.hopp.json` 全保真导出、`hopp run` 运行器；F4.2 AI 生成挪 M8.5）、URL 栏过期值修复 | ✅ |
| v1.0.0 GA | — | 差异化能力落地（M8.3–M8.6）+ 全平台稳定（macOS/Windows/Linux）+ 应用商店发布 | ⏳ |

### Backlog（未来规划）

未排期的候选功能、已知问题与技术债统一由 [BACKLOG.md](./BACKLOG.md) 维护，本文档不再重复记录。

---

## 🔗 参考链接

- [产品需求规格说明书](./PRD.md)
- [架构设计（技术栈与依赖）](./ARCHITECTURE.md)
- [UI/UX 设计规范](./UI_UX_GUIDELINES.md)
- [详细实现说明](./IMPLEMENTATION_NOTES.md)
- [测试方案](./TESTING.md)
- [Backlog 任务清单](./BACKLOG.md)
- [项目知识积累](../AGENTS.md)
- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)
